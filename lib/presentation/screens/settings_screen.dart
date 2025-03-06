import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/backup_service.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
import '../bloc/language/language_bloc.dart';
import '../bloc/language/language_event.dart';
import '../bloc/language/language_state.dart';
import '../bloc/currency/currency_bloc.dart';
import '../bloc/currency/currency_event.dart';
import '../bloc/currency/currency_state.dart';

// Enum pour le mode d'accessibilité
enum AccessibilityMode {
  standard,  // Mode standard
  senior,    // Mode pour personnes âgées (plus grand)
  contrast,  // Mode contraste élevé
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AccessibilityMode _accessibilityMode = AccessibilityMode.standard;
  bool _enableTutorials = true;
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Charger le mode d'accessibilité
      final accessModeIndex = prefs.getInt('accessibility_mode') ?? 0;
      _accessibilityMode = AccessibilityMode.values[accessModeIndex];
      
      // Charger la préférence des tutoriels
      _enableTutorials = prefs.getBool('enable_tutorials') ?? true;
    });
  }
  
  Future<void> _saveAccessibilityMode(AccessibilityMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accessibility_mode', mode.index);
  }
  
  Future<void> _saveTutorialsPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_tutorials', enabled);
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Initialiser les blocs
    context.read<LanguageBloc>().add(const LoadLanguage());
    context.read<LanguageBloc>().add(const LoadLanguage());
    context.read<CurrencyBloc>().add(const LoadCurrency());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          // Section Apparence
          _buildSectionHeader(l10n?.appearance ?? 'Appearance'),
          
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(l10n?.theme ?? 'Theme'),
                subtitle: Text(_getThemeModeName(state.themeMode, l10n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, state.themeMode),
              );
            },
          ),
          
          // Accessibilité
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text(l10n?.accessibility ?? 'Accessibility'),
            subtitle: Text(_getAccessibilityModeDescription(l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAccessibilityDialog(context),
          ),
          
          // Tutoriels
          SwitchListTile(
            secondary: const Icon(Icons.help_outline),
            title: Text(l10n?.tutorials ?? 'Tutorials & Help'),
            subtitle: Text(
              l10n?.tutorialsDescription ?? 
              'Show guided tours and help for complex features'
            ),
            value: _enableTutorials,
            onChanged: (value) {
              setState(() {
                _enableTutorials = value;
              });
              _saveTutorialsPreference(value);
            },
          ),
          
          const Divider(),

          // Section Langue
          _buildSectionHeader(l10n?.language ?? 'Language'),
          
          BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, state) {
              final languageBloc = context.read<LanguageBloc>();
              final currentLocale = state.locale;
              final languageName =
                  languageBloc.getLanguageName(currentLocale.languageCode);

              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n?.language ?? 'Language'),
                subtitle: Text(languageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, currentLocale),
              );
            },
          ),
          
          const Divider(),

          // Section Devise
          _buildSectionHeader(l10n?.currency ?? 'Currency'),
          
          BlocBuilder<CurrencyBloc, CurrencyState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: Text(l10n?.currency ?? 'Currency'),
                subtitle: Text(
                    '${state.activeCurrency.name} (${state.activeCurrency.symbol})'),
                trailing: state.status == CurrencyStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyDialog(context, state),
              );
            },
          ),
          
          BlocBuilder<CurrencyBloc, CurrencyState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.update),
                title: Text(l10n?.updateExchangeRates ?? 'Update Exchange Rates'),
                subtitle: state.lastUpdated != null
                    ? Text(
                        '${l10n?.lastUpdated ?? 'Last updated'}: ${_formatDateTime(state.lastUpdated!)}')
                    : Text(l10n?.neverUpdated ?? 'Never updated'),
                onTap: () {
                  context.read<CurrencyBloc>().add(const UpdateExchangeRates());
                },
              );
            },
          ),
          
          BlocBuilder<CurrencyBloc, CurrencyState>(
            builder: (context, state) {
              if (state.status == CurrencyStatus.error &&
                  state.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const Divider(),

          // Section Sauvegarde & Restauration
          _buildSectionHeader(l10n?.backupRestore ?? 'Backup & Restore'),
          
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(l10n?.createBackup ?? 'Create Backup'),
            subtitle: Text(l10n?.createBackupDescription ?? 'Create a backup of all your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _createBackup(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l10n?.restoreBackup ?? 'Restore Backup'),
            subtitle: Text(l10n?.restoreBackupDescription ?? 'Restore data from a backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restoreBackup(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l10n?.shareBackup ?? 'Share Backup'),
            subtitle: Text(l10n?.shareBackupDescription ?? 'Share backup file with others'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _shareBackup(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(l10n?.exportBackup ?? 'Export Backup'),
            subtitle: Text(l10n?.exportBackupDescription ?? 'Save backup file to device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportBackup(context),
          ),
          
          const Divider(),
          
          // Section À propos
          _buildSectionHeader(l10n?.about ?? 'About'),
          
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n?.resetTutorials ?? 'Reset Tutorials'),
            subtitle: Text(l10n?.resetTutorialsDesc ?? 'Show all tutorials again'),
            onTap: () => _resetTutorials(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String? title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title ?? '',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode, AppLocalizations? l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n?.system ?? 'System';
      case ThemeMode.light:
        return l10n?.light ?? 'Light';
      case ThemeMode.dark:
        return l10n?.dark ?? 'Dark';
    }
  }

  String _getAccessibilityModeDescription(AppLocalizations? l10n) {
    switch (_accessibilityMode) {
      case AccessibilityMode.standard:
        return l10n?.standardMode ?? 'Standard Mode';
      case AccessibilityMode.senior:
        return l10n?.seniorMode ?? 'Senior Mode (Larger Text)';
      case AccessibilityMode.contrast:
        return l10n?.contrastMode ?? 'High Contrast Mode';
    }
  }

  Future<void> _showThemeDialog(BuildContext context, ThemeMode currentMode) async {
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.selectTheme ?? 'Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ThemeMode.system,
              currentMode,
              l10n?.system ?? 'System',
              Icons.brightness_auto,
              l10n?.systemThemeDesc ?? 'Follow system theme',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              ThemeMode.light,
              currentMode,
              l10n?.light ?? 'Light',
              Icons.brightness_5,
              l10n?.lightThemeDesc ?? 'Light theme for daytime use',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              ThemeMode.dark,
              currentMode,
              l10n?.dark ?? 'Dark',
              Icons.brightness_3,
              l10n?.darkThemeDesc ?? 'Dark theme for nighttime use',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode option,
    ThemeMode currentMode,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = option == currentMode;
    
    return InkWell(
      onTap: () {
        context.read<ThemeBloc>().add(ChangeTheme(option));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccessibilityDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.accessibility ?? 'Accessibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccessibilityOption(
              context,
              AccessibilityMode.standard,
              l10n?.standardMode ?? 'Standard Mode',
              Icons.settings,
              l10n?.standardModeDesc ?? 'Default interface settings',
            ),
            const SizedBox(height: 8),
            _buildAccessibilityOption(
              context,
              AccessibilityMode.senior,
              l10n?.seniorMode ?? 'Senior Mode',
              Icons.accessibility,
              l10n?.seniorModeDesc ?? 'Larger text and simpler interface',
            ),
            const SizedBox(height: 8),
            _buildAccessibilityOption(
              context,
              AccessibilityMode.contrast,
              l10n?.contrastMode ?? 'High Contrast Mode',
              Icons.contrast,
              l10n?.contrastModeDesc ?? 'Improved contrast for better visibility',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityOption(
    BuildContext context,
    AccessibilityMode mode,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = mode == _accessibilityMode;
    
    return InkWell(
      onTap: () {
        setState(() {
          _accessibilityMode = mode;
        });
        _saveAccessibilityMode(mode);
        _applyAccessibilityMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _applyAccessibilityMode(AccessibilityMode mode) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.accessibilityModeChanged ?? 'Accessibility mode changed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context, Locale currentLocale) {
    final l10n = AppLocalizations.of(context);
    final languageBloc = context.read<LanguageBloc>();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.selectLanguage ?? 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languageBloc.supportedLocales.map((locale) {
            final languageName =
                languageBloc.getLanguageName(locale.languageCode);

            return RadioListTile<String>(
              title: Text(languageName),
              value: locale.languageCode,
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  languageBloc.add(ChangeLanguage(Locale(value)));
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyDialog(BuildContext context, CurrencyState state) async {
    final l10n = AppLocalizations.of(context);
    final currencyBloc = context.read<CurrencyBloc>();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.selectCurrency ?? 'Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: state.supportedCurrencies.map<Widget>((currency) {
              return ListTile(
                title: Text(currency.name),
                subtitle: Text('${l10n?.exchangeRate ?? 'Exchange Rate'}: ${currency.exchangeRate}'),
                trailing: currency.code == state.activeCurrency.code
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  currencyBloc.add(ChangeCurrency(currency.code));
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n?.creating ?? 'Creating backup...'),
            ],
          ),
        ),
      );
      await BackupService.createBackup();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.backupCreated ?? 'Backup created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, '${l10n?.backupError ?? 'Failed to create backup'}: $e');
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
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
            title: Text(l10n?.restoreBackup ?? 'Restore Backup'),
            content: Text(
              l10n?.restoreConfirmation ?? 
              'This will replace all current data with the backup data. '
              'This action cannot be undone. Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(l10n?.restore ?? 'Restore'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(l10n?.restoringBackup ?? 'Restoring backup...'),
                ],
              ),
            ),
          );
          final backupFile = File(file.path);
          await BackupService.restoreBackup(backupFile);
          if (context.mounted) {
            Navigator.pop(context); // Dismiss loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n?.backupRestored ?? 'Backup restored successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog if shown
        _showErrorDialog(context, l10n?.restoreError ?? 'Failed to restore backup: $e');
      }
    }
  }

  Future<void> _shareBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n?.preparing ?? 'Preparing backup...'),
            ],
          ),
        ),
      );
      await BackupService.shareBackup();
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, '${l10n?.sharingError ?? 'Failed to share backup'}: $e');
      }
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n?.exporting ?? 'Exporting backup...'),
            ],
          ),
        ),
      );
      await BackupService.exportBackup();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.backupExported ?? 'Backup exported successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        await _showErrorDialog(context, '${l10n?.exportError ?? 'Failed to export backup'}: $e');
      }
    }
  }

  Future<void> _resetTutorials(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.tutorials ?? 'Reset Tutorials'),
        content: Text(
          l10n?.resetTutorialsConfirm ?? 
          'Are you sure you want to reset all tutorials? You will see all tutorial dialogs again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.reset ?? 'Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('showcase_') || key.startsWith('tutorial_')) {
          await prefs.remove(key);
        }
      }
      
      setState(() {
        _enableTutorials = true;
      });
      await _saveTutorialsPreference(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.tutorialsReset ?? 'Tutorials have been reset'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.error ?? 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }
}