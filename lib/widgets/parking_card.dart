import 'package:flutter/material.dart';

class ParkingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Parking Information', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Available Spots: 10'),
            Text('Reserved Spots: 5'),
          ],
        ),
      ),
    );
  }
}
