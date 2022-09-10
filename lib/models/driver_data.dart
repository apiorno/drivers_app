class DriverData {
  String id;
  String name;
  String email;
  String phone;
  String carModel;
  String carNumber;
  String carColor;

  DriverData(this.id, this.name, this.email, this.phone, this.carModel,
      this.carNumber, this.carColor);

  factory DriverData.fromMap(Map<String, dynamic> map) {
    final carDetails = map['carDetails'];
    return DriverData(
        map['id'],
        map['name'],
        map['email'],
        map['phone'],
        carDetails['carModel'],
        carDetails['carNumber'],
        carDetails['carColor']);
  }
}
