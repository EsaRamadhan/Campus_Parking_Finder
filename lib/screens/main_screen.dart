import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref('parking_spots');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Reservation'),
      ),
      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            // Filter hanya spot dengan status "occupied"
            Map<dynamic, dynamic> occupiedSpots = Map.fromEntries(
              data.entries.where((entry) => entry.value['status'] == 'occupied'),
            );

            if (occupiedSpots.isEmpty) {
              return Center(child: Text('You have no active reservations.'));
            }

            return ListView.builder(
              itemCount: occupiedSpots.keys.length,
              itemBuilder: (context, index) {
                String spotId = occupiedSpots.keys.elementAt(index);
                Map<dynamic, dynamic> spotData = occupiedSpots[spotId];

                return ListTile(
                  title: Text('Spot ID: $spotId'),
                  subtitle: Text(
                      'Car: ${spotData['carType']} (${spotData['plateNumber']})'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Update status ke "available"
                      databaseRef.child(spotId).update({'status': 'available'}).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Spot $spotId is now available!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                    child: Text('Exit'),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No reservations found.'));
          }
        },
      ),
    );
  }
}
