import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/backup_service.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeName(state.themeMode)),
                onTap: () => _showThemeDialog(context, state.themeMode),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Backup & Restore'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Backup'),
            subtitle: const Text('Create a backup of all your data'),
            onTap: () => _createBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Backup'),
            subtitle: const Text('Restore data from a backup file'),
            onTap: () => _restoreBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Backup'),
            subtitle: const Text('Share backup file with others'),
            onTap: () => _shareBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Export Backup'),
            subtitle: const Text('Save backup file to device'),
            onTap: () => _exportBackup(context),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (mode) {
                context.read<ThemeBloc>().add(ChangeTheme(mode!));
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (mode) {
                context.read<ThemeBloc>().add(ChangeTheme(mode!));
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (mode) {
                context.read<ThemeBloc>().add(ChangeTheme(mode!));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final loadingDialog = _showLoadingDialog(context, 'Creating backup...');
      await BackupService.createBackup();
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showErrorDialog(context, 'Failed to create backup: $e');
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'ZIP files',
            extensions: ['zip'],
          ),
        ],
      );

      if (file != null && context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Backup'),
            content: const Text(
              'This will replace all current data with the backup data. '
              'This action cannot be undone. Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          final loadingDialog =
              _showLoadingDialog(context, 'Restoring backup...');
          final backupFile = File(file.path);
          await BackupService.restoreBackup(backupFile);
          if (context.mounted) {
            Navigator.pop(context); // Dismiss loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restored successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog if shown
        _showErrorDialog(context, 'Failed to restore backup: $e');
      }
    }
  }

  Future<void> _shareBackup(BuildContext context) async {
    try {
      final loadingDialog = _showLoadingDialog(context, 'Preparing backup...');
      await BackupService.shareBackup();
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showErrorDialog(context, 'Failed to share backup: $e');
      }
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final loadingDialog = _showLoadingDialog(context, 'Exporting backup...');
      await BackupService.exportBackup();
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showErrorDialog(context, 'Failed to export backup: $e');
      }
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoadingDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
