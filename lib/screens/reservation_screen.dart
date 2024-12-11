import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('parking_spots');
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  File? _carImage; // File untuk menyimpan gambar mobil yang diambil.

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _carImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Reservation'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset('assets/icons/back.png', fit: BoxFit.contain),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List parkingSpots = data.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: parkingSpots.length,
              itemBuilder: (context, index) {
                String spotId = parkingSpots[index];
                Map<dynamic, dynamic> spotData = data[spotId];
                String status = spotData['status'];
                String displayText;

                if (status == 'available') {
                  displayText = 'Status: Available';
                } else if (status == 'occupied' &&
                    spotData.containsKey('carType') &&
                    spotData.containsKey('plateNumber')) {
                  displayText =
                  'Status: Occupied by ${spotData['carType']} (${spotData['plateNumber']})';
                } else {
                  displayText = 'Status: Occupied';
                }

                Widget trailingIcon;
                if (status == 'available') {
                  trailingIcon = ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () {
                      _showReservationDialog(context, spotId);
                    },
                    child: const Text('Reserve',
                        style: TextStyle(color: Colors.white)),
                  );
                } else {
                  trailingIcon = const Icon(Icons.check_circle,
                      color: Colors.grey);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10.0),
                    title: Text(
                      '$spotId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(displayText),
                    trailing: trailingIcon,
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }

  void _showReservationDialog(BuildContext context, String spotId) {
    final TextEditingController carTypeController = TextEditingController();
    final TextEditingController plateNumberController = TextEditingController();

    DateTime? selectedStartTime;
    DateTime? selectedEndTime;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.local_parking, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(child: Text('Reserve Spot $spotId'))
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: carTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Car Type',
                      prefixIcon: Icon(Icons.directions_car_filled),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Plate Number',
                      prefixIcon: Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take a photo of your car'),
                  subtitle: _carImage != null
                      ? Image.file(_carImage!, height: 100, fit: BoxFit.cover)
                      : const Text('No photo selected'),
                  onTap: _pickImage,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () async {
                if (carTypeController.text.isNotEmpty &&
                    plateNumberController.text.isNotEmpty &&
                    _carImage != null) {
                  setState(() {
                    _isLoading = true;
                  });

                  await databaseRef.child(spotId).update({
                    'status': 'occupied',
                    'carType': carTypeController.text,
                    'plateNumber': plateNumberController.text,
                    'userEmail': currentUser?.email,
                    'carImage': _carImage!.path, // Save image path
                  }).then((_) {
                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Icon(Icons.check_circle_outline,
                                  color: Colors.green, size: 60),
                              SizedBox(height: 20),
                              Text(
                                'Reservation Successful!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}