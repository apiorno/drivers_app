import 'dart:async';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/black_theme_map.dart';
import 'package:drivers_app/helpers/repository_helper.dart';
import 'package:drivers_app/models/driver_data.dart';
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

    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .once()
        .then((snap) {
      if (snap.snapshot.value == null) return;
      final value = snap.snapshot.value as Map<String, dynamic>;
      onlineDriverData = DriverData.fromMap(value);
      driverVehiculeType = value['carDetails']['type'];
    });
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
            setGoogleMapDarkMode(newGoogleMapController!);
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
                      backgroundColor: statusColor,
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
