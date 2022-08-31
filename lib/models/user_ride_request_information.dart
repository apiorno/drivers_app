import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserRideRequestInformation {
  LatLng originLatLang;

  LatLng destinationLatLang;

  String originAddress;

  String destinationAddress;
  String rideRequestId;
  String userName;

  String userPhone;

  UserRideRequestInformation(
      this.originLatLang,
      this.destinationLatLang,
      this.originAddress,
      this.destinationAddress,
      this.rideRequestId,
      this.userName,
      this.userPhone);

  factory UserRideRequestInformation.fromMap(Map<String, dynamic> map,
      {required String id}) {
    final originLat = double.parse(map['origin']['latitude']);
    final originLong = double.parse(map['origin']['longitude']);

    final destinationLat = double.parse(map['destination']['latitude']);
    final destinationLong = double.parse(map['destination']['longitude']);

    return UserRideRequestInformation(
        LatLng(originLat, originLong),
        LatLng(destinationLat, destinationLong),
        map['originAddress'],
        map['destinationAddress'],
        id,
        map['userName'],
        map['userPhone']);
  }
}
