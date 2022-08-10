class DirectionsAddress {
  String? readableAddress;
  String? locationName;
  String? locationId;
  double? locationLatitude;
  double? locationLongitude;

  DirectionsAddress(
      {this.readableAddress,
      this.locationName,
      this.locationId,
      this.locationLatitude,
      this.locationLongitude});

  DirectionsAddress.fromJson(Map<String, dynamic> jsonData) {
    final location = jsonData['geometry']['location'];
    locationName = jsonData['name'];
    locationLatitude = location['lat'];
    locationLongitude = location['lng'];
    locationId = jsonData['place_id'];
    readableAddress = jsonData['formatted_address'];
  }
}
