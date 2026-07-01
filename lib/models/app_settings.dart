import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _kTheme           = 'theme_dark';
  static const _kAlarmSound      = 'alarm_sound';
  static const _kSaveAudio       = 'save_audio';
  static const _kFilledThreshold = 'filled_threshold'; // NEW
  static const _kFilledWindows   = 'filled_windows';   // NEW
  static const _kGroqKey         = 'groq_api_key';
  static const _kUserName        = 'user_name';

  bool   isDark           = true;
  String alarmSound       = 'alarm_default';
  bool   saveAudio        = false;

  /// Minimum softmax probability for "filled" to count as FILLED.
  /// If filledProb < filledThreshold → classify as FILLING regardless of argmax.
  /// Default: 0.70 (70%)
  double filledThreshold  = 0.70;

  /// Number of consecutive FILLED windows before alarm fires.
  /// Default: 2 (10 seconds of confirmed silence)
  int    filledWindows    = 2;

  String groqApiKey       = '';
  String userName         = 'User';

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final s = AppSettings();
    s.isDark          = p.getBool(_kTheme)             ?? true;
    s.alarmSound      = p.getString(_kAlarmSound)      ?? 'alarm_default';
    s.saveAudio       = p.getBool(_kSaveAudio)         ?? false;
    s.filledThreshold = p.getDouble(_kFilledThreshold) ?? 0.70;
    s.filledWindows   = p.getInt(_kFilledWindows)      ?? 2;
    s.groqApiKey      = p.getString(_kGroqKey)         ?? '';
    s.userName        = p.getString(_kUserName)        ?? 'User';
    return s;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kTheme,              isDark);
    await p.setString(_kAlarmSound,       alarmSound);
    await p.setBool(_kSaveAudio,          saveAudio);
    await p.setDouble(_kFilledThreshold,
        double.parse(filledThreshold.toStringAsFixed(2)));
    await p.setInt(_kFilledWindows,       filledWindows);
    await p.setString(_kGroqKey,          groqApiKey);
    await p.setString(_kUserName,         userName);
  }
}