import 'dart:async';

import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/black_theme_map.dart';
import 'package:drivers_app/helpers/repository_helper.dart';
import 'package:drivers_app/info_handler/app_info.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/widgets/fare_amount_collection_dialog.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class TripScreen extends StatefulWidget {
  final UserRideRequestInformation userRideRequestInfo;
  const TripScreen({required this.userRideRequestInfo, super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  Completer<GoogleMapController> _completerController = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String buttonTitle = 'Arrived';
  Color buttonColor = Colors.green;

  final markers = Set<Marker>();
  final circles = Set<Circle>();
  final polylines = Set<Polyline>();
  final polylineCoordinates = <LatLng>[];
  final polylinePoints = PolylinePoints();
  double mapPadding = 0;
  late BitmapDescriptor iconMarker;
  final geolocator = Geolocator();
  late Position onlineDriverPosition;
  String rideRequestStatus = 'accepted';
  late String durationFromOriginToDestination;
  bool isRequestDirectionDetails = false;

//Step1 : Driver accepts user ride request
// originLatLng = driver location
// destinationLatLng = user pickup location

//Step2 : Driver already picked up the user
// originLatLng = user pickup location / driver location
// destinationLatLng = user dropoff location

  Future<void> _drawPolylineFromOriginToDestination(
      LatLng originPosition, LatLng destinationPosition) async {
    final appInfo = Provider.of<AppInfo>(context);
    showDialog(
        context: context,
        builder: (context) => const ProgressDialog(
              message: 'Please wait!',
            ));
    final directionDetailsInfo =
        await RepositoryHelper.obtainOriginToDestinationDirectionDetails(
            originPosition, destinationPosition);

    if (!mounted) return;
    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPpointsResult =
        pPoints.decodePolyline(directionDetailsInfo.ePoints!);
    polylineCoordinates.clear();
    decodedPpointsResult.forEach((PointLatLng pointLatLng) =>
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude)));

    setState(() {
      final polyline = Polyline(
          polylineId: const PolylineId('Poly'),
          color: Colors.purpleAccent,
          jointType: JointType.round,
          points: polylineCoordinates,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polylines.add(polyline);
    });
    LatLngBounds bounds;
    if (originPosition.latitude > destinationPosition.latitude &&
        originPosition.longitude > destinationPosition.longitude) {
      bounds = LatLngBounds(
          southwest: destinationPosition, northeast: originPosition);
    } else if (originPosition.latitude > destinationPosition.latitude) {
      bounds = LatLngBounds(
          southwest:
              LatLng(originPosition.latitude, destinationPosition.longitude),
          northeast:
              LatLng(destinationPosition.latitude, originPosition.longitude));
    } else if (originPosition.longitude > destinationPosition.longitude) {
      bounds = LatLngBounds(
          southwest:
              LatLng(destinationPosition.latitude, originPosition.longitude),
          northeast:
              LatLng(originPosition.latitude, destinationPosition.longitude));
    } else {
      bounds = LatLngBounds(
          southwest: originPosition, northeast: destinationPosition);
    }
    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 65));
    final originMarker = Marker(
        markerId: const MarkerId('originID'),
        position: destinationPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
    final destiantionMarker = Marker(
        markerId: const MarkerId('destinationID'),
        position: destinationPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));

    final originCircle = Circle(
        circleId: const CircleId('originID'),
        fillColor: Colors.green,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: originPosition);

    final destinationCircle = Circle(
        circleId: const CircleId('destinationID'),
        fillColor: Colors.red,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: destinationPosition);

    setState(() {
      markers.add(originMarker);
      markers.add(destiantionMarker);
      circles.add(originCircle);
      circles.add(destinationCircle);
    });
  }

  void saveAssignedDriverDetailsToUserRideRequest() {
    final databaseReference = FirebaseDatabase.instance
        .ref()
        .child('rideRequests')
        .child(widget.userRideRequestInfo.rideRequestId);
    final driverLocation = {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };
    databaseReference.child('driverLocation').set(driverLocation);
    databaseReference.child('status').set('accepted');
    databaseReference.child('driveriD').set(onlineDriverData.id);
    databaseReference.child('driverName').set(onlineDriverData.name);
    databaseReference.child('driverPhone').set(onlineDriverData.phone);
    databaseReference
        .child('car_details')
        .set('${onlineDriverData.carColor}${onlineDriverData.carNumber}');
    saveRideRequestIdToDriverHistory();
  }

  void saveRideRequestIdToDriverHistory() {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .child('tripsHistory');

    tripsHistoryRef.child(widget.userRideRequestInfo.rideRequestId).set(true);
  }

  Future<void> initializeActivDriversIconMarker() async {
    final imageConfiguration =
        createLocalImageConfiguration(context, size: const Size(2, 2));
    iconMarker = await BitmapDescriptor.fromAssetImage(
        imageConfiguration, 'images/car.png');
  }

  void getDriversLocationUpdatesAtRealTime() {
    late LatLng oldLatLng;
    driverLiverPositionSubscription =
        Geolocator.getPositionStream().listen((Position newPosition) {
      driverCurrentPosition = newPosition;
      onlineDriverPosition = newPosition;
    });

    final latLngLiveDriverposition =
        LatLng(onlineDriverPosition.latitude, onlineDriverPosition.longitude);
    final animationMarker = Marker(
        markerId: MarkerId('AnimatedMarker'),
        position: latLngLiveDriverposition,
        icon: iconMarker,
        infoWindow: const InfoWindow(title: 'This is your Position'));
    setState(() {
      final cameraPosition =
          CameraPosition(target: latLngLiveDriverposition, zoom: 16);
      newGoogleMapController!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      markers
          .removeWhere((element) => element.markerId.value == 'AnimatedMarker');
      markers.add(animationMarker);
    });
    oldLatLng = latLngLiveDriverposition;
    updateDurationTimeAtRealTime();

    final driverLatLngDataMap = {
      'latitude': onlineDriverPosition.latitude,
      'longitude': onlineDriverPosition.longitude,
    };
    FirebaseDatabase.instance
        .ref()
        .child('rideRequests')
        .child(widget.userRideRequestInfo.rideRequestId)
        .child('driverLocation')
        .set(driverLatLngDataMap);
  }

  Future<void> updateDurationTimeAtRealTime() async {
    if (!isRequestDirectionDetails) {
      isRequestDirectionDetails = true;
      final originLatLng = LatLng(
        onlineDriverPosition.latitude,
        onlineDriverPosition.longitude,
      );
      late LatLng destinationLatLng;
      if (rideRequestStatus == 'accepted') {
        destinationLatLng = widget.userRideRequestInfo.originLatLang;
      } else {
        destinationLatLng = widget.userRideRequestInfo.destinationLatLang;
      }
      final directionInformation =
          await RepositoryHelper.obtainOriginToDestinationDirectionDetails(
              originLatLng, destinationLatLng);

      setState(() {
        durationFromOriginToDestination = directionInformation.durationText!;
      });
      isRequestDirectionDetails = false;
    }
  }

  Future<void> endTrip() async {
    showDialog(
        context: context,
        builder: (context) => ProgressDialog(
              message: 'Please Wait...',
            ));
    final currentDriverpositionLatLng =
        LatLng(onlineDriverPosition.latitude, onlineDriverPosition.longitude);
    final tripDirectionDetails =
        await RepositoryHelper.obtainOriginToDestinationDirectionDetails(
            currentDriverpositionLatLng,
            widget.userRideRequestInfo.originLatLang);

    final totalFareAmount =
        RepositoryHelper.calculateFareAmountFromOriginToDestination(
            tripDirectionDetails);

    FirebaseDatabase.instance
        .ref()
        .child('rideRequests')
        .child(widget.userRideRequestInfo.rideRequestId)
        .child('fareAmount')
        .set(totalFareAmount.toString());

    FirebaseDatabase.instance
        .ref()
        .child('rideRequests')
        .child(widget.userRideRequestInfo.rideRequestId)
        .child('status')
        .set('ended');
    driverLiverPositionSubscription.cancel();
    Navigator.pop(context);
    showDialog(
        context: context,
        builder: (context) =>
            FareAmountCollectionDialog(totalFareAmount: totalFareAmount));

    saveFareAmountToDriverEarnings(totalFareAmount);
  }

  void saveFareAmountToDriverEarnings(double totalFareAmount) {
    final earningsRef = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .child('earning');
    earningsRef.once().then((snap) => snap.snapshot.value != null
        ? earningsRef.set(
            (double.parse(snap.snapshot.value.toString()) + totalFareAmount)
                .toString())
        : earningsRef.set(totalFareAmount.toString()));
  }

  @override
  void initState() {
    super.initState();
    saveAssignedDriverDetailsToUserRideRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: markers,
            circles: circles,
            polylines: polylines,
            onMapCreated: (controller) {
              _completerController.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                mapPadding = 350;
              });
              setGoogleMapDarkMode(newGoogleMapController!);
              var driverLatLngPosition = LatLng(driverCurrentPosition!.latitude,
                  driverCurrentPosition!.longitude);
              var userPickupLatlang = widget.userRideRequestInfo.originLatLang;
              _drawPolylineFromOriginToDestination(
                  driverLatLngPosition, userPickupLatlang);
              getDriversLocationUpdatesAtRealTime();
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white30,
                        blurRadius: 18,
                        spreadRadius: .5,
                        offset: Offset(0.6, 0.6))
                  ]),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(children: [
                  Text(durationFromOriginToDestination,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreenAccent)),
                  const SizedBox(
                    height: 18,
                  ),
                  Divider(
                    thickness: 2,
                    height: 2,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Text(
                        widget.userRideRequestInfo.userName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightGreenAccent),
                      ),
                      const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.phone_android,
                            color: Colors.grey,
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'images/origin.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestInfo.originAddress,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'images/destination.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestInfo.destinationAddress,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Divider(
                    thickness: 2,
                    height: 2,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton.icon(
                      onPressed: () async {
                        if (rideRequestStatus == 'accepted') {
                          rideRequestStatus = 'arrived';
                          FirebaseDatabase.instance
                              .ref()
                              .child('rideRequests')
                              .child(widget.userRideRequestInfo.rideRequestId)
                              .child('status')
                              .set(rideRequestStatus);

                          setState(() {
                            buttonTitle = 'Let`s Go';
                            buttonColor = Colors.lightGreen;
                          });

                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => ProgressDialog(
                                    message: 'Loading...',
                                  ));
                          await _drawPolylineFromOriginToDestination(
                              widget.userRideRequestInfo.originLatLang,
                              widget.userRideRequestInfo.destinationLatLang);
                          Navigator.pop(context);
                        } else if (rideRequestStatus == 'arrived') {
                          rideRequestStatus = 'ontrip';
                          FirebaseDatabase.instance
                              .ref()
                              .child('rideRequests')
                              .child(widget.userRideRequestInfo.rideRequestId)
                              .child('status')
                              .set(rideRequestStatus);

                          setState(() {
                            buttonTitle = 'End Trip';
                            buttonColor = Colors.redAccent;
                          });
                        } else if (rideRequestStatus == 'ontrip') {
                          endTrip();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                      ),
                      icon: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 25,
                      ),
                      label: Text(buttonTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)))
                ]),
              ),
            ),
          )
        ],
      ),
    );
  }
}
