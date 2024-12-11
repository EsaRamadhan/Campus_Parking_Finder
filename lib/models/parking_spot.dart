class ParkingSpot implements Comparable<ParkingSpot> {
  final String id;
  final String status;
  final DateTime startTime;
  final DateTime endTime;

  ParkingSpot({
    required this.id,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      status: map['status'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
    );
  }

  @override
  int compareTo(ParkingSpot other) {
    return int.tryParse(id)?.compareTo(int.tryParse(other.id) ?? 0) ?? 0;
  }
}
