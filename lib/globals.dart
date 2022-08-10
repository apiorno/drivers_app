import 'dart:async';

import 'package:drivers_app/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
String mapKey = 'MyApiKey';
AppUser? currentUser;
late StreamSubscription<Position> positionSubscription;
