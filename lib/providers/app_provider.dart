import 'package:flutter/foundation.dart';
import '../models/inference_record.dart';
import '../models/app_settings.dart';
import '../services/inference_service.dart';
import '../services/audio_service.dart';
import '../services/alarm_service.dart';

enum AppState { idle, listening, processing, alerting }

class AppProvider extends ChangeNotifier {
  final _inferSvc = InferenceService();
  final _audioSvc = AudioService();
  final _alarmSvc = AlarmService();

  AppState              state        = AppState.idle;
  AppSettings           settings     = AppSettings();
  InferenceResult?      lastResult;
  List<InferenceRecord> history      = [];
  List<double>          embeddingVis = List.filled(64, 0.0);
  double                liveRms      = 0;
  bool                  modelsReady  = false;
  String?               errorMessage;

  // Consecutive FILLED windows counter
  int  _consecutiveFilled = 0;
  bool _alarmTriggered    = false;
  bool _inferring         = false;

  Future<void> init() async {
    settings = await AppSettings.load();
    history  = await HistoryDatabase.fetchAll();
    await AlarmService.initNotifications();

    try {
      await _inferSvc.load();
      modelsReady = true;
      debugPrint('[AppProvider] Models ready.');
    } catch (e) {
      errorMessage = 'Failed to load models: $e';
      debugPrint('[AppProvider] $errorMessage');
    }

    _audioSvc.onWindow    = _onAudioWindow;
    _audioSvc.onAmplitude = (rms) { liveRms = rms; };

    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (state == AppState.idle) {
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  Future<void> _startListening() async {
    if (!modelsReady) {
      errorMessage = 'Models not ready yet.';
      notifyListeners();
      return;
    }
    _consecutiveFilled = 0;
    _alarmTriggered    = false;
    _inferring         = false;

    final ok = await _audioSvc.startRecording(
        saveAudio: settings.saveAudio);
    if (!ok) {
      errorMessage = 'Microphone permission denied.';
      notifyListeners();
      return;
    }
    state = AppState.listening;
    notifyListeners();
  }

  Future<void> _stopListening() async {
    await _audioSvc.stopRecording();
    await _alarmSvc.stop();
    _alarmTriggered    = false;
    _consecutiveFilled = 0;
    _inferring         = false;
    state = AppState.idle;
    notifyListeners();
  }

  Future<void> _onAudioWindow(List<double> pcm) async {
    if (state == AppState.idle) return;
    if (_inferring) {
      debugPrint('[AppProvider] Skipping window — busy.');
      return;
    }

    _inferring = true;
    state = AppState.processing;
    notifyListeners();

    // Pass filledThreshold so inference_service uses it for classification
    final result = await _inferSvc.infer(
      pcm,
      filledThreshold: settings.filledThreshold,
    );

    if (state == AppState.idle) {
      _inferring = false;
      return;
    }

    if (result != null) {
      lastResult = result;

      // Update embedding visualizer
      final step = result.embeddings.length ~/ 64;
      for (int i = 0; i < 64; i++) {
        embeddingVis[i] = result.embeddings[i * step];
      }

      // Save every result to history
      final record = InferenceRecord(
        label:      result.label,
        confidence: result.confidence,
        rms:        result.rms,
        timestamp:  DateTime.now(),
      );
      await HistoryDatabase.insert(record);
      history.insert(0, record);
      if (history.length > 500) history.removeLast();

      // ── Alarm logic: fire only when FILLED confirmed ──────────────────
      // result.label is already threshold-filtered by inference_service:
      //   'filled'  → filledProb >= filledThreshold (e.g. 70%)
      //   'filling' → filledProb <  filledThreshold
      if (result.label == 'filled') {
        _consecutiveFilled++;
        debugPrint('[AppProvider] Filled streak: '
            '$_consecutiveFilled/${settings.filledWindows} '
            '(filledProb=${result.filledProb.toStringAsFixed(3)})');
      } else {
        // FILLING detected — reset filled streak
        if (_consecutiveFilled > 0) {
          debugPrint('[AppProvider] Filled streak reset — FILLING detected');
        }
        _consecutiveFilled = 0;
      }

      // Trigger alarm after N consecutive filled windows
      if (_consecutiveFilled >= settings.filledWindows &&
          !_alarmTriggered) {
        _alarmTriggered = true;
        state = AppState.alerting;
        await _alarmSvc.trigger(soundName: settings.alarmSound);
        debugPrint('[AppProvider] 🔔 ALARM — tank FILLED confirmed '
            '(${settings.filledWindows} windows × '
            '${settings.filledThreshold * 100}% threshold)');
      } else if (state != AppState.alerting) {
        state = AppState.listening;
      }

    } else {
      state = AppState.listening;
    }

    _inferring = false;
    notifyListeners();
  }

  Future<void> dismissAlarm() async {
    await _alarmSvc.stop();
    await _audioSvc.stopRecording();
    _alarmTriggered    = false;
    _consecutiveFilled = 0;
    _inferring         = false;
    state = AppState.idle;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings s) async {
    settings = s;
    await s.save();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    settings.isDark = !settings.isDark;
    await settings.save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await HistoryDatabase.clear();
    history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _inferSvc.dispose();
    _audioSvc.dispose();
    _alarmSvc.dispose();
    super.dispose();
  }
}