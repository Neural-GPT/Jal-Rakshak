import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;
  final _groqCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _groqVisible = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<AppProvider>().settings;
    _groqCtrl.text = _s.groqApiKey;
    _nameCtrl.text = _s.userName;
  }

  @override
  void dispose() {
    _groqCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _s.groqApiKey = _groqCtrl.text.trim();
    _s.userName   = _nameCtrl.text.trim().isEmpty ? 'User' : _nameCtrl.text.trim();
    await context.read<AppProvider>().updateSettings(_s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppColors.cyan,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    _s = prov.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(color: Colors.white.withOpacity(0.7)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _Card(children: [
            _SettingTile(
              icon:     Icons.dark_mode_outlined,
              title:    'Theme',
              subtitle: _s.isDark ? 'Dark' : 'Light',
              trailing: Switch.adaptive(
                value:          _s.isDark,
                activeColor:    AppColors.cyan,
                onChanged: (v) {
                  setState(() => _s.isDark = v);
                  prov.toggleTheme();
                },
              ),
            ),
          ]),

          // ── User ────────────────────────────────────────────────────────
          _SectionHeader('Profile'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                  prefixIcon: const Icon(Icons.person_outline,
                      size: 18, color: AppColors.cyan),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cyan)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ]),

          // ── Alarm ────────────────────────────────────────────────────────
          _SectionHeader('Alarm'),
          _Card(children: [
            _SettingTile(
              icon:  Icons.notifications_outlined,
              title: 'Alarm Sound',
              subtitle: _s.alarmSound.replaceAll('alarm_', '').capitalize(),
              trailing: DropdownButton<String>(
                value:     _s.alarmSound,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF131720),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.cyan),
                items: const [
                  DropdownMenuItem(
                      value: 'alarm_default', child: Text('Default')),
                  DropdownMenuItem(
                      value: 'alarm_gentle', child: Text('Gentle')),
                  DropdownMenuItem(
                      value: 'alarm_urgent', child: Text('Urgent')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _s.alarmSound = v);
                },
              ),
            ),
          ]),

          // ── Inference ────────────────────────────────────────────────────
          _SectionHeader('Inference'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Filled detection threshold ───────────────────────
                  Text(
                    'Filled Detection Threshold',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6)),
                  ),
                  Text(
                    'Minimum "filled" confidence to classify as FILLED',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.35)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value:     _s.filledThreshold.clamp(0.5, 0.95).toDouble(),
                          min:       0.5,
                          max:       0.95,
                          divisions: 9,
                          activeColor:   AppColors.cyan,
                          inactiveColor: AppColors.cyan.withOpacity(0.2),
                          onChanged: (v) =>
                              setState(() => _s.filledThreshold = v),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(_s.filledThreshold * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Consecutive filled windows before alarm ───────────
                  Text(
                    'Consecutive filled windows before alarm',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6)),
                  ),
                  Text(
                    'Higher = more confident, slower alarm',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.35)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value:     _s.filledWindows.toDouble().clamp(1.0, 5.0),
                          min:       1,
                          max:       5,
                          divisions: 4,
                          activeColor:   AppColors.cyan,
                          inactiveColor: AppColors.cyan.withOpacity(0.2),
                          onChanged: (v) =>
                              setState(() => _s.filledWindows = v.round()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_s.filledWindows}×',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SettingTile(
              icon:     Icons.mic_outlined,
              title:    'Save Audio Recordings',
              subtitle: 'Saves inference audio for model improvement',
              trailing: Switch.adaptive(
                value:       _s.saveAudio,
                activeColor: AppColors.cyan,
                onChanged:   (v) => setState(() => _s.saveAudio = v),
              ),
            ),
          ]),

          // ── AI Analytics ─────────────────────────────────────────────────
          _SectionHeader('AI Analytics'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller:  _groqCtrl,
                obscureText: !_groqVisible,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Groq API Key',
                  labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                  hintText: 'gsk_...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2), fontSize: 12),
                  prefixIcon: const Icon(Icons.vpn_key_outlined,
                      size: 18, color: AppColors.amber),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _groqVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: Colors.white.withOpacity(0.3)),
                    onPressed: () =>
                        setState(() => _groqVisible = !_groqVisible),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.amber)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 12, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Free at console.groq.com — powers AI analytics tab',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ],
            ),
          ]),

          // ── About / Support ───────────────────────────────────────────────
          _SectionHeader('About'),
          _Card(children: [
            _SettingTile(
              icon:     Icons.info_outline,
              title:    'Version',
              subtitle: '1.0.0 — YAMNet + MLP',
            ),
            _SettingTile(
              icon:     Icons.email_outlined,
              title:    'Developer Support',
              subtitle: 'Contact for help or feedback',
              onTap:    () async {
                final uri = Uri.parse('mailto:support@jalrakshak.app'
                    '?subject=Jal Rakshak Support');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            _SettingTile(
              icon:     Icons.open_in_new,
              title:    'Model: YAMNet Embeddings + MLP Head',
              subtitle: '96.4% accuracy · 259 KB head · On-device',
            ),
          ]),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _SettingTile extends StatelessWidget {
  final IconData   icon;
  final String     title;
  final String?    subtitle;
  final Widget?    trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.cyan.withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.35))),
                  ],
                ),
              ),
              if (trailing != null) trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right,
                    size: 16, color: Colors.white.withOpacity(0.2)),
            ],
          ),
        ),
      );
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}