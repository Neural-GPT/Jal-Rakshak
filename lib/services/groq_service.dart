import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inference_record.dart';

class GroqService {
  static const _url   = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  final String apiKey;
  GroqService(this.apiKey);

  Future<String> analyzeHistory(List<InferenceRecord> records) async {
    if (apiKey.isEmpty) {
      return 'Please add your Groq API key in Settings → AI Analytics.';
    }
    if (records.isEmpty) {
      return 'No inference history yet. Start monitoring to generate analytics.';
    }

    final summary = _buildSummary(records);

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': '''You are an analytics assistant for Jal Rakshak,
an AI-powered water tank monitor. Analyze the inference history and give
practical, concise insights about:
1. Tank filling patterns (time of day, duration, frequency)
2. Average confidence levels and what they indicate about model certainty
3. Any anomalies or unusual patterns
4. Recommendations for optimal water management
Keep response under 200 words. Use bullet points. Be specific with times and numbers.''',
        },
        {
          'role': 'user',
          'content': 'Here is my tank inference history:\n\n$summary',
        },
      ],
      'max_tokens': 400,
      'temperature': 0.3,
    });

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type':  'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices'][0]['message']['content'] as String;
      } else {
        return 'Analytics error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to Groq API: $e';
    }
  }

  String _buildSummary(List<InferenceRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('Total inference events: ${records.length}');

    final filling = records.where((r) => r.isFilling).toList();
    final filled  = records.where((r) => !r.isFilling).toList();
    buffer.writeln('Filling events: ${filling.length}');
    buffer.writeln('Filled/silent events: ${filled.length}');

    if (records.isNotEmpty) {
      buffer.writeln('Date range: ${records.last.timestamp.toLocal()} '
          'to ${records.first.timestamp.toLocal()}');

      // Average confidence per class
      if (filling.isNotEmpty) {
        final avgConf = filling
                .map((r) => r.confidence)
                .reduce((a, b) => a + b) /
            filling.length;
        buffer.writeln(
            'Avg filling confidence: ${(avgConf * 100).toStringAsFixed(1)}%');
      }
      if (filled.isNotEmpty) {
        final avgConf = filled
                .map((r) => r.confidence)
                .reduce((a, b) => a + b) /
            filled.length;
        buffer.writeln(
            'Avg filled confidence: ${(avgConf * 100).toStringAsFixed(1)}%');
      }

      // Average RMS
      final avgRms =
          records.map((r) => r.rms).reduce((a, b) => a + b) / records.length;
      buffer.writeln('Avg RMS: ${avgRms.toStringAsFixed(3)}');
    }

    buffer.writeln('\nRecent 15 events (timestamp, label, confidence, rms):');
    for (final r in records.take(15)) {
      buffer.writeln(
        '- ${r.timestamp.toLocal().toString().substring(11, 19)}: '
        '${r.label.toUpperCase()} '
        'CL=${(r.confidence * 100).toStringAsFixed(1)}% '
        'RMS=${r.rms.toStringAsFixed(3)}',
      );
    }

    return buffer.toString();
  }
}