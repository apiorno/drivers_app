import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/repository_helper.dart';
import 'package:drivers_app/mainScreens/trip_screen.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationDialogBox extends StatefulWidget {
  final UserRideRequestInformation userRideRequestInfo;
  const NotificationDialogBox({Key? key, required this.userRideRequestInfo})
      : super(key: key);

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 2,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.grey[800]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
            ),
            Image.asset(
              'images/car_logo.png',
              width: 160,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'New Ride request',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.grey),
            ),
            const SizedBox(
              height: 14,
            ),
            const Divider(
              height: 3,
              thickness: 3,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
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
                  )
                ],
              ),
            ),
            const Divider(
              height: 3,
              thickness: 3,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        //Cancel request
                        assetsAudioPlayer.pause();
                        assetsAudioPlayer.stop();
                        assetsAudioPlayer = AssetsAudioPlayer();

                        FirebaseDatabase.instance
                            .ref()
                            .child(widget.userRideRequestInfo.rideRequestId)
                            .remove()
                            .then((value) {
                          final driverReference = FirebaseDatabase.instance
                              .ref()
                              .child('drivers')
                              .child(currentFirebaseUser!.uid);
                          Future.wait([
                            driverReference.child('newRideStatus').set('idle'),
                            driverReference
                                .child('tripHistory')
                                .child(widget.userRideRequestInfo.rideRequestId)
                                .remove()
                          ]).then((value) => Fluttertoast.showToast(
                              msg: 'Ride request has been cancelled'));
                        });
                        Future.delayed(Duration(milliseconds: 2000),
                            () => SystemNavigator.pop());
                      },
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(fontSize: 14),
                      )),
                  const SizedBox(
                    width: 25,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () {
                        assetsAudioPlayer.pause();
                        assetsAudioPlayer.stop();
                        assetsAudioPlayer = AssetsAudioPlayer();
                        acceptRideRequest(context);
                      },
                      child: const Text(
                        'ACCEPT',
                        style: TextStyle(fontSize: 14),
                      ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void acceptRideRequest(BuildContext context) {
    final newRideStatusRef = FirebaseDatabase.instance
        .ref()
        .child('driver')
        .child(currentFirebaseUser!.uid)
        .child('newRideStatus');
    newRideStatusRef.once().then((snap) {
      final value = snap.snapshot.value;
      if (value == null) {
        Fluttertoast.showToast(msg: 'This ride request does not exist');
        return;
      }
      if (value == widget.userRideRequestInfo.rideRequestId) {
        newRideStatusRef.set('accepted');
        RepositoryHelper.pauseLiveLocationUpdate();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TripScreen(
                    userRideRequestInfo: widget.userRideRequestInfo)));
      }
    });
  }
}
