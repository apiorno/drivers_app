import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/models/app_user.dart';
import 'package:drivers_app/models/driver_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
String mapKey = 'MyApiKey';
AppUser? currentUser;
late StreamSubscription<Position> positionSubscription;
late StreamSubscription<Position> driverLiverPositionSubscription;
AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
Position? driverCurrentPosition;
late DriverData onlineDriverData;
late String driverVehiculeType;
