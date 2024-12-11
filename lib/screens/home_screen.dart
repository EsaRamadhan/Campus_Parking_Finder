import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:campus_parking_finder/screens/reservation_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('parking_spots');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkTimeExceeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parking Reservations'),
        actions: [
          customIconButton('assets/icons/logout.png', () {
            FirebaseAuth.instance.signOut();
          }),
        ],
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
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
            Map<dynamic, dynamic> userReservations = Map.fromEntries(
              data.entries.where((entry) =>
              entry.value['status'] == 'occupied' &&
                  entry.value['userEmail'] == currentUser?.email),
            );

            if (userReservations.isEmpty) {
              return const Center(child: Text('Belum ada reservasi.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: userReservations.keys.length,
              itemBuilder: (context, index) {
                String spotId = userReservations.keys.elementAt(index);
                Map<dynamic, dynamic> spotData = userReservations[spotId];

                return _buildReservationCard(spotId, spotData);
              },
            );
          } else {
            return const Center(child: Text('Belum ada reservasi.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReservationScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset('assets/icons/add.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildReservationCard(String spotId, Map spotData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_parking, size: 28, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Spot ID: $spotId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: const Text(
                    'Reserved',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1.5),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  title: 'Car',
                  value: '${spotData['carType']}',
                  icon: Icons.directions_car,
                ),
                _buildInfoColumn(
                  title: 'Plate',
                  value: '${spotData['plateNumber']}',
                  icon: Icons.confirmation_number,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  title: 'Start',
                  value: _formatDateTime(spotData['startTime']),
                  icon: Icons.access_time,
                ),
                _buildInfoColumn(
                  title: 'End',
                  value: _formatDateTime(spotData['endTime']),
                  icon: Icons.timer_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1.5),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showExitConfirmationDialog(context, spotId);
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text(
                'Exit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkTimeExceeded() {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((spotId, spotData) {
          if (spotData['status'] == 'occupied' &&
              spotData['userEmail'] == currentUser?.email) {
            final endTime = DateTime.parse(spotData['endTime']);
            if (DateTime.now().isAfter(endTime)) {
              _showTimeExceededDialog(context, spotId);
            }
          }
        });
      }
    });
  }

  void _showTimeExceededDialog(BuildContext context, String spotId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Waktu Reservasi Berakhir'),
          content: const Text('Waktu reservasi Anda telah berakhir.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Oke'),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog(BuildContext context, String spotId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Exit'),
        content: const Text('Apakah Anda yakin ingin keluar dari reservasi?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup popup
            },
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              _exitReservation(spotId); // Hapus reservasi
              Navigator.pop(context); // Tutup popup
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  void _exitReservation(String spotId) {
    databaseRef.child(spotId).update({'status': 'available'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservasi telah dibatalkan.'),
        ),
      );
    });
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('EEEE, MMM d yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildInfoColumn({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconButton customIconButton(String iconPath, VoidCallback onPressed) {
    return IconButton(
      icon: Image.asset(iconPath, width: 24, height: 24),
      onPressed: onPressed,
    );
  }
}