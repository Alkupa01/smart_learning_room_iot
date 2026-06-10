import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Pastikan Anda sudah meload dotenv di fungsi main()
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak ditemukan di .env');
    }

    // Menggunakan gemini-1.5-flash karena cepat dan efisien untuk teks/penalaran
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> analyzeSensorData({
    required double suhu,
    required double kelembapan,
    required double cahaya,
    required double suara, // Pastikan atribut ini sudah ada di model branch Anda
    required int durasiMenit,
  }) async {
    final prompt = '''
Kamu adalah asisten AI cerdas untuk sistem IoT "Smart Learning Room".
Berikut adalah pembacaan sensor ruangan saat ini:
- Suhu: $suhu °C
- Kelembapan: $kelembapan %
- Intensitas Cahaya: $cahaya Lux
- Tingkat Kebisingan: $suara dB
- Durasi Belajar: $durasiMenit menit

Tugasmu:
1. Berikan analisis singkat (1-2 kalimat) tentang kondisi ruangan saat ini apakah ideal untuk fokus belajar.
2. Berikan 2 suggestion/saran praktis kepada pengguna untuk meningkatkan kenyamanan atau menjaga kesehatannya.

Format jawaban harus ringkas, menggunakan poin-poin, dan berbahasa Indonesia yang natural.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tidak dapat menghasilkan saran saat ini.';
    } catch (e) {
      return 'Terjadi kesalahan saat menghubungi AI: $e';
    }
  }
}