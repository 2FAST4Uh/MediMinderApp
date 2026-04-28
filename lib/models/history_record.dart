class HistoryRecord {
  final String id;
  final String medicineName;
  final String dosage;
  final DateTime takenDateTime;

  HistoryRecord({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.takenDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'takenDateTime': takenDateTime.toIso8601String(),
    };
  }

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      id: map['id'],
      medicineName: map['medicineName'],
      dosage: map['dosage'],
      takenDateTime: DateTime.parse(map['takenDateTime']),
    );
  }
}
