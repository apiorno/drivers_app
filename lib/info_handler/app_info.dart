import 'package:drivers_app/models/directions_address.dart';
import 'package:flutter/foundation.dart';

class AppInfo extends ChangeNotifier {
  DirectionsAddress? userPickUpLocation;
  DirectionsAddress? userDropOffAddress;

  void updatePickUpLocationAddress(DirectionsAddress newUserPickUpAddress) {
    userPickUpLocation = newUserPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(DirectionsAddress newUserDropOffAddress) {
    userDropOffAddress = newUserDropOffAddress;
    notifyListeners();
  }
}
