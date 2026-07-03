import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: theme.isDark ? Colors.white : const Color(0xFF191C1D),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsSection(
            'App Preferences',
            [
              _buildSettingItem(
                Icons.dark_mode_outlined,
                'Dark Mode',
                theme.isDark,
                trailing: Switch(
                  value: theme.isDark,
                  onChanged: (v) {
                    ref.read(themeProvider.notifier).toggleDarkMode(v);
                  },
                  activeColor: const Color(0xFF0058BE),
                ),
              ),
              _buildSettingItem(
                Icons.notifications_none_rounded,
                'Notifications',
                theme.isDark,
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: const Color(0xFF0058BE),
                ),
              ),
              _buildSettingItem(
                Icons.language_rounded,
                'Language',
                theme.isDark,
                trailing: const Text(
                  'English',
                  style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
                ),
              ),
            ],
            theme.isDark,
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'About',
            [
              _buildSettingItem(Icons.info_outline_rounded, 'Version', theme.isDark, trailing: const Text('1.0.0', style: TextStyle(fontFamily: 'Inter', color: Colors.grey))),
              _buildSettingItem(Icons.description_outlined, 'Terms of Service', theme.isDark),
              _buildSettingItem(Icons.privacy_tip_outlined, 'Privacy Policy', theme.isDark),
            ],
            theme.isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, bool isDark, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF191C1D)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: isDark ? Colors.white : const Color(0xFF191C1D),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: trailing is Switch ? null : () {},
    );
  }
}
