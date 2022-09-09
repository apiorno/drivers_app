import 'dart:async';

import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/black_theme_map.dart';
import 'package:drivers_app/helpers/repository_helper.dart';
import 'package:drivers_app/info_handler/app_info.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
                  Text('18 mins',
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
                      onPressed: () {},
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
