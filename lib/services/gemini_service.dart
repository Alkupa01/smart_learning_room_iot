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
    String? primaryIssue, // Issue utama yang perlu fokus
  }) async {
    // Build context tentang issue utama
    String issueContext = '';
    if (primaryIssue == 'sound' && suara > 70) {
      issueContext = '''

⚠️ MASALAH UTAMA: Tingkat kebisingan SANGAT TINGGI ($suara%).
Ini adalah penyebab utama menurunnya kenyamanan belajar.
Fokus pada solusi untuk mengurangi kebisingan ruangan.''';
    } else if (primaryIssue == 'temperature') {
      issueContext = '''

⚠️ MASALAH UTAMA: Suhu ruangan tidak optimal ($suhu°C).
Ini mempengaruhi fokus dan kenyamanan.''';
    } else if (primaryIssue == 'light') {
      issueContext = '''

⚠️ MASALAH UTAMA: Pencahayaan tidak ideal ($cahaya Lux).
Ini dapat menyebabkan kelelahan mata.''';
    } else if (primaryIssue == 'humidity') {
      issueContext = '''

⚠️ MASALAH UTAMA: Kelembapan udara tidak sesuai ($kelembapan%).
Ini dapat mempengaruhi kesehatan dan konsentrasi.''';
    }

    final prompt = '''
Kamu adalah asisten AI cerdas untuk sistem IoT "Smart Learning Room".
Berikut adalah pembacaan sensor ruangan saat ini:
- Suhu: $suhu °C (Ideal: 22-26°C)
- Kelembapan: $kelembapan % (Ideal: 40-60%)
- Intensitas Cahaya: $cahaya Lux (Ideal: 300-500 Lux)
- Tingkat Kebisingan: $suara % (Ideal: < 40%)
- Durasi Belajar: $durasiMenit menit$issueContext

Tugasmu:
1. Berikan analisis SINGKAT (1 kalimat) tentang kondisi ruangan dan dampaknya untuk fokus belajar.
2. Jika ada masalah (nilai sensor di luar range ideal), PRIORITASKAN solusi untuk masalah tersebut.
3. Berikan 1-2 saran praktis dan segera bisa dilakukan pengguna untuk meningkatkan kenyamanan.

Format jawaban HARUS ringkas, jelas, berbahasa Indonesia yang natural, dan fokus pada solusi.
Hindari penjelasan yang panjang.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tidak dapat menghasilkan saran saat ini.';
    } catch (e) {
      return 'Terjadi kesalahan saat menghubungi AI: $e';
    }
  }
}