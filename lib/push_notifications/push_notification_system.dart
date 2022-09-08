import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/push_notifications/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PushNotificationsSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async {
    // Terminated
    // When the app is completely closed and opened from a push notification
    messaging.getInitialMessage().then((message) {
      if (message != null) {
        readUserRideRequestInformation(message.data['rideRequestId'], context);
      }
    });

    // Foreground
    // When the app is open and receives a push notification
    FirebaseMessaging.onMessage.listen((message) {
      readUserRideRequestInformation(message.data['rideRequestId'], context);
    });

    // Background
    // When the app is in background and opened from a push notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      readUserRideRequestInformation(message.data['rideRequestId'], context);
    });
  }

  void readUserRideRequestInformation(
      String userRideRequestId, BuildContext context) {
    FirebaseDatabase.instance
        .ref()
        .child('rideRequests')
        .child(userRideRequestId)
        .once()
        .then((snapData) {
      if (snapData.snapshot.value == null) {
        Fluttertoast.showToast(msg: 'This request does not exists');
        return;
      }
      assetsAudioPlayer.open(Audio('music/music_notification.mp3'));
      assetsAudioPlayer.play();
      final snapVal = snapData.snapshot.value as Map<String, dynamic>;

      final userRideRequestInfo = UserRideRequestInformation.fromMap(snapVal,
          id: snapData.snapshot.key!);
      showDialog(
          context: context,
          builder: (context) =>
              NotificationDialogBox(userRideRequestInfo: userRideRequestInfo));
    });
  }

  Future<void> generateAndGetToken() async {
    String? registrationToken = await messaging.getToken();
    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentFirebaseUser!.uid)
        .child('token')
        .set(registrationToken);
    messaging.subscribeToTopic('allDrivers');
    messaging.subscribeToTopic('allUsers');
  }
}
