import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/media_import_service.dart';
import '../../tasks/providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../services/backup_service.dart';

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
                  value: theme.notificationsEnabled,
                  onChanged: (v) {
                    ref.read(themeProvider.notifier).toggleNotifications(v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(v ? 'Reminders enabled' : 'All reminders cancelled'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
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
                onTap: () => _showInfoDialog(context, 'Language', 'English is currently the only supported language.'),
              ),
            ],
            theme.isDark,
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Data',
            [
              _buildSettingItem(
                Icons.file_upload_outlined,
                'Export Backup (JSON)',
                theme.isDark,
                onTap: () async {
                  try {
                    final path = await BackupService.exportToFile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Backup saved to $path')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export failed. Please try again.')),
                      );
                    }
                  }
                },
              ),
              _buildSettingItem(
                Icons.file_download_outlined,
                'Import Backup (JSON)',
                theme.isDark,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  final path = result?.files.single.path;
                  if (path == null) return;
                  try {
                    final imported = await BackupService.importFromFile(path);
                    // Refresh in-memory lists so imported rows appear immediately.
                    ref.invalidate(taskListProvider);
                    ref.invalidate(categoryListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Imported ${imported.tasks} tasks, ${imported.categories} categories',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import failed: not a valid Flow backup.')),
                      );
                    }
                  }
                },
              ),
              _buildSettingItem(
                Icons.wallpaper_rounded,
                'App Wallpaper',
                theme.isDark,
                trailing: theme.appWallpaperPath != null
                    ? TextButton(
                        onPressed: () {
                          ref.read(themeProvider.notifier).updateAppWallpaper(null);
                        },
                        child: const Text('Clear', style: TextStyle(fontSize: 13)),
                      )
                    : const Text(
                        'Not set',
                        style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
                      ),
                onTap: () async {
                  final path = await MediaImportService.pickAndSaveImage();
                  if (path != null) {
                    await ref.read(themeProvider.notifier).updateAppWallpaper(path);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('App wallpaper updated')),
                      );
                    }
                  }
                },
              ),
            ],
            theme.isDark,
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'About',
            [
              _buildSettingItem(Icons.info_outline_rounded, 'Version', theme.isDark, trailing: const Text('1.0.0', style: TextStyle(fontFamily: 'Inter', color: Colors.grey))),
              _buildSettingItem(
                Icons.description_outlined,
                'Terms of Service',
                theme.isDark,
                onTap: () => _showInfoDialog(
                  context,
                  'Terms of Service',
                  'Flow is provided as-is for personal productivity. Your data stays on your device unless you export it.',
                ),
              ),
              _buildSettingItem(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                theme.isDark,
                onTap: () => _showInfoDialog(
                  context,
                  'Privacy Policy',
                  'Flow collects no analytics and sends no data anywhere. Backups you export are plain JSON files under your control.',
                ),
              ),
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

  Widget _buildSettingItem(IconData icon, String title, bool isDark, {Widget? trailing, VoidCallback? onTap}) {
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
      onTap: trailing is Switch ? null : onTap,
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
