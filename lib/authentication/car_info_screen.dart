import 'package:drivers_app/globals.dart';
import 'package:drivers_app/splash/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({Key? key}) : super(key: key);

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  final carColorController = TextEditingController();
  final List<String> carTypes = ['Uber-X', 'Uber-Go', 'Bike'];
  String? selectedCarType;

  void validateForm() {
    String? textToShow;
    if (carColorController.text.isEmpty) {
      textToShow = 'Car color is mandatory';
    } else if (carNumberController.text.isEmpty) {
      textToShow = 'Car number is mandatory';
    } else if (carModelController.text.isEmpty) {
      textToShow = 'Car model is mandatory';
    } else if (selectedCarType == null) {
      textToShow = 'Car type is mandatory';
    }

    (textToShow != null)
        ? Fluttertoast.showToast(msg: textToShow, textColor: Colors.redAccent)
        : saveCarInfo();
  }

  void saveCarInfo() {
    Map driverCarInfoMap = {
      'car_color': carColorController.text,
      'car_number': carNumberController.text,
      'car_model': carModelController.text,
      'type': selectedCarType
    };
    DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child('drivers');
    driversRef
        .child(currentFirebaseUser!.uid)
        .child('car_details')
        .set(driverCarInfoMap);
    Fluttertoast.showToast(msg: 'Car info has been saved!');
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MySplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(
              height: 24,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('images/logo1.png'),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Write Car Details',
              style: TextStyle(
                  fontSize: 26,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: carModelController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                labelText: 'Car model',
                hintText: 'Car model',
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            TextField(
              controller: carNumberController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                labelText: 'Car number',
                hintText: 'Card number',
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            TextField(
              controller: carColorController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                labelText: 'Car color',
                hintText: 'Car color',
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
            DropdownButton(
              iconSize: 26,
              dropdownColor: Colors.white24,
              hint: const Text(
                'Please choose car type',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              items: carTypes
                  .map((carType) => DropdownMenuItem(
                        value: carType,
                        child: Text(
                          carType,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ))
                  .toList(),
              onChanged: (String? newCarType) {
                setState(() {
                  selectedCarType = newCarType;
                });
              },
              value: selectedCarType,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: validateForm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ))
          ],
        ),
      )),
    );
  }
}
