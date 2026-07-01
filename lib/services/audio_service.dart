import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class AudioService {
  static const int _sampleRate     = 16000;
  static const int _windowSamples  = 80000; // 5 seconds
  static const int _hopSamples     = 80000; // NO overlap — emit every 5s exactly
  static const int _bytesPerSample = 2;     // PCM 16-bit LE

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final List<int> _buffer = [];

  Function(List<double> pcmFloat)? onWindow;
  Function(double rms)? onAmplitude;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  IOSink? _audioSink;
  String? _savedAudioPath;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording({bool saveAudio = false}) async {
    if (_isRecording) return true;

    final granted = await requestPermission();
    if (!granted) {
      debugPrint('[AudioService] Permission denied.');
      return false;
    }

    try {
      if (saveAudio) {
        final dir  = await getApplicationDocumentsDirectory();
        final name = 'jal_${DateTime.now().millisecondsSinceEpoch}.pcm';
        _savedAudioPath = p.join(dir.path, 'recordings', name);
        await Directory(p.dirname(_savedAudioPath!))
            .create(recursive: true);
        _audioSink = File(_savedAudioPath!).openWrite();
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder:     AudioEncoder.pcm16bits,
          sampleRate:  _sampleRate,
          numChannels: 1,
        ),
      );

      _buffer.clear();

      _sub = stream.listen(
        (Uint8List chunk) {
          _audioSink?.add(chunk);

          // Parse PCM 16-bit little-endian
          final data = chunk.buffer.asByteData();
          for (int i = 0; i + 1 < data.lengthInBytes; i += _bytesPerSample) {
            _buffer.add(data.getInt16(i, Endian.little));
          }

          // Live RMS for amplitude indicator
          if (_buffer.length >= 1600) {
            final recent = _buffer.sublist(
                math.max(0, _buffer.length - 1600));
            double sum = 0;
            for (final s in recent) {
              final f = s / 32768.0;
              sum += f * f;
            }
            onAmplitude?.call(math.sqrt(sum / recent.length));
          }

          // Emit a full 5-second window (no overlap — clean non-repeating windows)
          while (_buffer.length >= _windowSamples) {
            final window = _buffer.sublist(0, _windowSamples);
            _buffer.removeRange(0, _windowSamples); // consume full window

            final floats =
                window.map((s) => s / 32768.0).toList();
            debugPrint('[AudioService] Emitting window: '
                '${_windowSamples} samples');
            onWindow?.call(floats);
          }
        },
        onError: (e) =>
            debugPrint('[AudioService] Stream error: $e'),
      );

      _isRecording = true;
      debugPrint('[AudioService] Started @ ${_sampleRate}Hz');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Start error: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
    await _audioSink?.flush();
    await _audioSink?.close();
    _audioSink = null;
    _buffer.clear();
    _isRecording = false;
    final saved = _savedAudioPath;
    _savedAudioPath = null;
    debugPrint('[AudioService] Stopped. Saved: $saved');
    return saved;
  }

  void dispose() {
    stopRecording();
    _recorder.dispose();
  }
}