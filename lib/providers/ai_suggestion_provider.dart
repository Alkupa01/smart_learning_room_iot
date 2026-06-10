import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';
import 'sensor_provider.dart';

// 1. Provider untuk service Gemini
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// 2. Menggunakan AsyncNotifier (Standar modern Riverpod untuk state asinkron)
class AiSuggestionNotifier extends AsyncNotifier<String> {
  @override
  FutureOr<String> build() {
    // Nilai awal saat aplikasi pertama kali dimuat
    return 'Belum ada saran. Mulai sesi belajar untuk melihat analisis AI.';
  }

  Future<void> fetchSuggestion() async {
    // Ubah state menjadi loading secara manual agar UI memutar CircularProgressIndicator
    state = const AsyncValue.loading();
    
    // AsyncValue.guard otomatis menangani try-catch dan mengembalikan AsyncData / AsyncError
    state = await AsyncValue.guard(() async {
      // Ambil data sensor terakhir (karena StreamProvider, bentuknya AsyncValue)
      final sensorDataAsync = ref.read(sensorProvider);
      
      // Ambil durasi dari session timer
      final sessionSeconds = ref.read(sessionSecondsProvider);
      final durasiMenit = sessionSeconds ~/ 60;

      // Cek apakah data sensor sudah tersedia dari stream
      if (sensorDataAsync.value == null) {
        return 'Menunggu data sensor...';
      }

      final sensor = sensorDataAsync.value!;
      final gemini = ref.read(geminiServiceProvider);

      // Panggil API Gemini
      // Pastikan variabel suara disesuaikan dengan properti di model Anda (misal: sensor.suara atau sensor.noiseLevel)
      final responseText = await gemini.analyzeSensorData(
        suhu: sensor.temperature,
        kelembapan: sensor.humidity,
        cahaya: sensor.lux,
        suara: 40.0, // <-- Ganti angka ini dengan variabel suara dari branch Anda
        durasiMenit: durasiMenit,
      );

      return responseText;
    });
  }
}

// 3. Provider untuk notifier-nya
final aiSuggestionProvider = AsyncNotifierProvider<AiSuggestionNotifier, String>(() {
  return AiSuggestionNotifier();
});