// JOurney Details
class DirectionDetailsInfo {
  int? distanceValue;
  int? durationValue;
  String? ePoints;
  String? distanceText;
  String? durationText;

  DirectionDetailsInfo(
      {this.distanceValue,
      this.durationValue,
      this.ePoints,
      this.distanceText,
      this.durationText});

  DirectionDetailsInfo.fromJson(Map<String, dynamic> jsonData) {
    final distance = jsonData['legs'][0]['distance'];
    final duration = jsonData['legs'][0]['duration'];
    ePoints = jsonData['overview_polyline']['points'];
    distanceText = distance['text'];
    distanceValue = distance['value'];
    durationText = duration['text'];
    durationValue = duration['value'];
  }
}
