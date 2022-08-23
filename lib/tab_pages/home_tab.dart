import 'dart:async';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/repository_helper.dart';
import 'package:drivers_app/push_notifications/push_notification_system.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  Completer<GoogleMapController> _completerController = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  Position? userCurrentPosition;
  final geoLocator = Geolocator();
  LocationPermission? _locationPermission;

  String statusText = 'Now offline';
  Color statusColor = Colors.grey;
  bool isActive = false;

  void goOffline() {
    Geofire.removeLocation(currentFirebaseUser!.uid);
    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .child('newRideStatus')
      ..onDisconnect()
      ..remove();
    Future.delayed(const Duration(seconds: 2), () {
      SystemNavigator.pop();
    });
  }

  void goOnline() async {
    userCurrentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Geofire.initialize('activeDrivers');
    Geofire.setLocation(currentFirebaseUser!.uid, userCurrentPosition!.latitude,
        userCurrentPosition!.longitude);
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .child('newRideStatus');
    ref.set('idle');
    ref.onValue.listen((event) {});
  }

  void updateUserLocationInRealTime() {
    positionSubscription =
        Geolocator.getPositionStream().listen((Position newPosition) {
      userCurrentPosition = newPosition;
    });
    if (isActive) {
      Geofire.setLocation(currentFirebaseUser!.uid,
          userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    }
    newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude)));
  }

  Future<void> _setGoogleMapDarkMode() {
    return newGoogleMapController!.setMapStyle('''
                  [
                    {
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#242f3e"
                        }
                      ]
                    },
                    {
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#746855"
                        }
                      ]
                    },
                    {
                      "elementType": "labels.text.stroke",
                      "stylers": [
                        {
                          "color": "#242f3e"
                        }
                      ]
                    },
                    {
                      "featureType": "administrative.locality",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#d59563"
                        }
                      ]
                    },
                    {
                      "featureType": "poi",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#d59563"
                        }
                      ]
                    },
                    {
                      "featureType": "poi.park",
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#263c3f"
                        }
                      ]
                    },
                    {
                      "featureType": "poi.park",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#6b9a76"
                        }
                      ]
                    },
                    {
                      "featureType": "road",
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#38414e"
                        }
                      ]
                    },
                    {
                      "featureType": "road",
                      "elementType": "geometry.stroke",
                      "stylers": [
                        {
                          "color": "#212a37"
                        }
                      ]
                    },
                    {
                      "featureType": "road",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#9ca5b3"
                        }
                      ]
                    },
                    {
                      "featureType": "road.highway",
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#746855"
                        }
                      ]
                    },
                    {
                      "featureType": "road.highway",
                      "elementType": "geometry.stroke",
                      "stylers": [
                        {
                          "color": "#1f2835"
                        }
                      ]
                    },
                    {
                      "featureType": "road.highway",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#f3d19c"
                        }
                      ]
                    },
                    {
                      "featureType": "transit",
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#2f3948"
                        }
                      ]
                    },
                    {
                      "featureType": "transit.station",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#d59563"
                        }
                      ]
                    },
                    {
                      "featureType": "water",
                      "elementType": "geometry",
                      "stylers": [
                        {
                          "color": "#17263c"
                        }
                      ]
                    },
                    {
                      "featureType": "water",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        {
                          "color": "#515c6d"
                        }
                      ]
                    },
                    {
                      "featureType": "water",
                      "elementType": "labels.text.stroke",
                      "stylers": [
                        {
                          "color": "#17263c"
                        }
                      ]
                    }
                  ]
              ''');
  }

  void checkIfPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  void locateUserPosition() async {
    userCurrentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    var cameraPosition = CameraPosition(target: latLngPosition, zoom: 14);
    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    final readableAddress =
        await RepositoryHelper.searchAddressForGeographicCoordinates(
            userCurrentPosition!, context);
  }

  readCUrrentDriverInformation() async {
    currentFirebaseUser = firebaseAuth.currentUser;
    final pushNotificationsSystem = PushNotificationsSystem();
    pushNotificationsSystem.initializeCloudMessaging(context);
    pushNotificationsSystem.generateAndGetToken();
  }

  @override
  void initState() {
    super.initState();
    checkIfPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (controller) {
            _completerController.complete(controller);
            newGoogleMapController = controller;
            _setGoogleMapDarkMode();
            locateUserPosition();
          },
        ),
        statusText != 'Now Online'
            ? Container(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                color: Colors.black87,
              )
            : Container(),
        Positioned(
          top: statusText != 'Now Online'
              ? MediaQuery.of(context).size.height * 0.4
              : 25,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    if (!isActive) {
                      goOnline();
                      updateUserLocationInRealTime();

                      setState(() {
                        statusText = 'Now Online';
                        isActive = true;
                        statusColor = Colors.transparent;
                      });
                      Fluttertoast.showToast(msg: 'You are Online now');
                    } else {
                      goOffline();

                      setState(() {
                        statusText = 'Now Offline';
                        isActive = false;
                        statusColor = Colors.grey;
                      });
                      Fluttertoast.showToast(msg: 'You are Offline now');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      primary: statusColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26))),
                  child: statusText != 'Now Online'
                      ? Text(
                          statusText,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        )
                      : const Icon(
                          Icons.phonelink_ring,
                          color: Colors.white,
                          size: 26,
                        ))
            ],
          ),
        )
      ],
    );
  }
}
