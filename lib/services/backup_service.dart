import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import '../data/datasources/database_helper.dart';

class BackupService {
  static const String _backupFileName = 'electric_meter_backup.zip';

  static Future<File> createBackup() async {
    try {
      // Get database file
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      // Get images directory
      final imagesDir = await _getImagesDirectory();
      final imageFiles = await _getImageFiles(imagesDir);

      // Create archive
      final archive = Archive();

      // Add database file to archive
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(
        ArchiveFile('database.db', dbBytes.length, dbBytes),
      );

      // Add image files to archive
      for (final imageFile in imageFiles) {
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final relativePath = path.relative(
            imageFile.path,
            from: imagesDir.path,
          );
          archive.addFile(
            ArchiveFile('images/$relativePath', imageBytes.length, imageBytes),
          );
        }
      }

      // Create zip file
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create zip archive');
      }

      // Save zip file
      final backupFile = await _getBackupFile();
      await backupFile.writeAsBytes(zipData);

      return backupFile;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  static Future<void> restoreBackup(File backupFile) async {
    try {
      // Read zip file
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Get paths
      final dbFile = await _getDatabaseFile();
      final imagesDir = await _getImagesDirectory();

      // Close database connection
      await DatabaseHelper.instance.close();

      // Restore files
      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          if (file.name == 'database.db') {
            // Restore database
            await dbFile.writeAsBytes(data);
          } else if (file.name.startsWith('images/')) {
            // Restore image
            final imageFile = File(
              path.join(imagesDir.path, file.name.substring(7)),
            );
            await imageFile.create(recursive: true);
            await imageFile.writeAsBytes(data);
          }
        }
      }

      // Reopen database
      await DatabaseHelper.instance.database;
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  static Future<void> shareBackup() async {
    try {
      final backupFile = await createBackup();
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'Electric Meter Billing Backup',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  static Future<void> exportBackup() async {
    try {
      final backupFile = await createBackup();
      final saveLocation = await getSaveLocation(
        suggestedName:
            'electric_meter_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'ZIP files',
            extensions: ['zip'],
          ),
        ],
      );

      if (saveLocation != null) {
        await backupFile.copy(saveLocation.path);
      }
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  static Future<void> importBackup() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'ZIP files',
            extensions: ['zip'],
          ),
        ],
      );

      if (file != null) {
        await restoreBackup(File(file.path));
      }
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  static Future<File> _getDatabaseFile() async {
    final databasesPath = await getDatabasesPath();
    return File(path.join(databasesPath, 'electric_meter.db'));
  }

  static Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/meter_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  static Future<List<File>> _getImageFiles(Directory directory) async {
    final List<File> files = [];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File &&
          ['.jpg', '.jpeg', '.png'].contains(path.extension(entity.path))) {
        files.add(entity);
      }
    }
    return files;
  }

  static Future<File> _getBackupFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_backupFileName');
  }
}
