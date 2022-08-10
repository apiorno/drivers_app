import 'package:drivers_app/globals.dart';
import 'package:drivers_app/helpers/request_helper.dart';
import 'package:drivers_app/info_handler/app_info.dart';
import 'package:drivers_app/models/app_user.dart';
import 'package:drivers_app/models/direction_details_info.dart';
import 'package:drivers_app/models/directions_address.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class RepositoryHelper {
  static Future<String> searchAddressForGeographicCoordinates(
      Position position, BuildContext context) async {
    final apiUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey';
    var resultAddress = '';
    try {
      final response = await RequestHelper.receiveRequest(apiUrl);
      resultAddress = response['results'][0]['formatted_address'];
      final userPickupAddress = DirectionsAddress(
          locationLatitude: position.latitude,
          locationLongitude: position.longitude,
          locationName: resultAddress);
      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickupAddress);
    } catch (e) {
      resultAddress = '';
    }
    return resultAddress;
  }

  static void readCurrentOnlineUserInfo() async {
    currentFirebaseUser = firebaseAuth.currentUser;
    DatabaseReference riderRef = FirebaseDatabase.instance
        .ref()
        .child('riders')
        .child(currentFirebaseUser!.uid);
    riderRef.once().then((riderKey) {
      final snapshot = riderKey.snapshot;
      if (snapshot.value != null) {
        currentUser = AppUser.fromSnapshot(snapshot);
      }
    });
  }

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(
      LatLng origin, LatLng destination) async {
    final response = await RequestHelper.receiveRequest(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$mapKey');

    return DirectionDetailsInfo.fromJson(response['routes'][0]);
  }
}
