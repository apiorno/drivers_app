import 'dart:async';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/home/home_screen.dart';
import 'package:flutter/material.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  void startTimer() {
    Timer(const Duration(seconds: 3), () async {
      if (firebaseAuth.currentUser != null) {
        currentFirebaseUser = firebaseAuth.currentUser;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo1.png'),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Uber & Indriver clone app',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
    );
  }
}
