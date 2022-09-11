import 'package:drivers_app/authentication/signup_screen.dart';
import 'package:drivers_app/globals.dart';
import 'package:drivers_app/splash/splash_screen.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void validateForm() {
    String? textToShow;
    if (!emailController.text.contains('@')) {
      textToShow = 'Email address is not valid';
    } else if (passwordController.text.isEmpty) {
      textToShow = 'Password is mandatory';
    }

    (textToShow != null)
        ? Fluttertoast.showToast(msg: textToShow, textColor: Colors.redAccent)
        : loginDriver();
  }

  Future<void> loginDriver() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const ProgressDialog(message: 'Login in process, please wait...'));
    final User? firebaseUser = (await firebaseAuth
            .signInWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim())
            .catchError((msg) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Error: $msg');
    }))
        .user;
    if (!mounted) return;
    if (firebaseUser != null) {
      DatabaseReference driversRef =
          FirebaseDatabase.instance.ref().child('drivers');
      driversRef.child(firebaseUser.uid).once().then((driverKey) {
        final snapshot = driverKey.snapshot;
        if (snapshot.value != null) {
          currentFirebaseUser = firebaseUser;
          Fluttertoast.showToast(msg: 'Login Successful!');
        } else {
          Fluttertoast.showToast(msg: 'No record exists with this email');
          firebaseAuth.signOut();
        }
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MySplashScreen()));
      });
    } else {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Login error!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(children: [
            const SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('images/logo1.png'),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Login as a Driver',
              style: TextStyle(
                  fontSize: 26,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Email',
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            TextField(
              controller: passwordController,
              keyboardType: TextInputType.text,
              obscureText: true,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Password',
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: validateForm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.black54, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: (() => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SignUpScreen()))),
              child: const Text('Do not have an account yet? Register here'),
            )
          ]),
        ),
      ),
    );
  }
}
