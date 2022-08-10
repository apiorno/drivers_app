import 'package:firebase_database/firebase_database.dart';

class AppUser {
  String? phone;
  String? name;
  String? id;
  String? email;

  AppUser({this.phone, this.name, this.id, this.email});

  AppUser.fromSnapshot(DataSnapshot snapshot) {
    final value = snapshot.value as dynamic;
    phone = value['phone'];
    name = value['name'];
    id = snapshot.key;
    email = value['email'];
  }
}
