import 'package:drivers_app/globals.dart';
import 'package:drivers_app/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          onPressed: () {
            firebaseAuth.signOut();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MySplashScreen()));
          },
          child: const Text('Sign out')),
    );
  }
}
