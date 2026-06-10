// lib/services/firebase_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/study_session.dart';

class FirebaseService {
  // Mengarahkan referensi root database Realtime DB ke node 'smartlearningroom'
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('smartlearningroom');

  /// Stream untuk menangkap data sensor secara real-time dari ESP32-S3
  Stream<SensorData> getSensorStream() {
    return _dbRef.child('sensors').onValue.map((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue == null) {
        throw Exception("Data sensor tidak ditemukan di database Firebase");
      }
      
      // Mengubah data snapshot Firebase menjadi Map lokal Dart
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshotValue as Map);
      return SensorData.fromMap(data);
    });
  }

  /// Stream untuk mengambil riwayat session belajar dari Firebase
  Stream<List<StudySession>> getSessionStream() {
    return _dbRef.child('sessions').orderByChild('startTime').onValue.map((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue == null) return [];
      final Map<String, dynamic> sessionsMap = Map<String, dynamic>.from(snapshotValue as Map);
      final sessions = sessionsMap.entries.map((entry) {
        final sessionData = Map<String, dynamic>.from(entry.value as Map);
        return StudySession.fromMap(sessionData);
      }).toList();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    });
  }

  /// Simpan sesi belajar ke Firebase
  Future<void> saveStudySession(StudySession session) async {
    await _dbRef.child('sessions').child(session.id).set(session.toMap());
  }

  /// Fungsi untuk mengirim instruksi kontrol aktuator (Fan, Lampu, Servo, Mode) ke Firebase
  Future<void> updateActuatorState({
    bool? fan,
    bool? light,
    double? servoAngle,
    String? mode,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (fan != null) updates['fan'] = fan;
    if (light != null) updates['light'] = light;
    if (servoAngle != null) updates['servoAngle'] = servoAngle;
    if (mode != null) updates['mode'] = mode;

    if (updates.isNotEmpty) {
      await _dbRef.child('control').update(updates);
    }
  }

  /// Fungsi untuk mencatat rating/feedback kenyamanan user langsung ke Firebase
  Future<void> sendUserFeedback(int level) async {
    await _dbRef.child('feedback').set({
      'last_rating': level,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}