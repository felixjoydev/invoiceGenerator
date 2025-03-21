import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  final ImagePicker _picker = ImagePicker();

  // Create a separate method channel specifically for document picker
  static const MethodChannel _documentPickerChannel = MethodChannel(
    'com.invoicegenerator/document_picker',
  );

  // Log storage for tracking issues
  final List<String> _logEntries = [];

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  // Log an error with timestamp
  void _logError(String message, [Object? error]) {
    final timestamp = DateTime.now().toString();
    final logEntry = '[$timestamp] $message ${error != null ? '- $error' : ''}';
    debugPrint(logEntry);
    _logEntries.add(logEntry);
    // Keep only the latest 50 log entries
    if (_logEntries.length > 50) {
      _logEntries.removeAt(0);
    }
  }

  // Get all logs as a string
  String getErrorLogs() {
    return _logEntries.join('\n');
  }

  /// Show a bottom sheet with options to pick from gallery or camera
  Future<String?> pickImage(
    BuildContext context, {
    bool? usePhotoLibrary,
  }) async {
    try {
      // If usePhotoLibrary is provided, bypass the bottom sheet
      if (usePhotoLibrary != null) {
        if (usePhotoLibrary) {
          return _pickFromSource(ImageSource.gallery);
        } else {
          return _openDocumentPicker();
        }
      }

      // Show a bottom sheet with options
      final dynamic source = await showModalBottomSheet<dynamic>(
        context: context,
        backgroundColor: Colors.white,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'SELECT IMAGE FROM',
                    style: TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF373C3A),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Color(0xFF373C3A)),
                  title: Text(
                    'Photo Library',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.folder, color: Color(0xFF373C3A)),
                  title: Text(
                    'Files',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'files'),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      );

      if (source == null) return null;

      if (source == 'files') {
        // Directly open document picker for files option
        return _openDocumentPicker();
      } else {
        return _pickFromSource(source);
      }
    } catch (e) {
      _logError('Error picking image', e);
      rethrow;
    }
  }

  /// Open iOS document picker using a direct platform channel call
  Future<String?> _openDocumentPicker() async {
    try {
      _logError('Opening document picker directly...');

      // Simple method channel call with fewer options to reduce potential issues
      final String? filePath = await _documentPickerChannel
          .invokeMethod<String>('openDocumentPicker');

      _logError('Response from document picker: $filePath');

      if (filePath == null || filePath.isEmpty) {
        _logError('No file selected from document picker');
        return null;
      }

      _logError('File selected from document picker: $filePath');
      return _processPickedFile(File(filePath));
    } on PlatformException catch (e) {
      _logError('Platform exception with document picker', e);
      return null;
    } catch (e) {
      _logError('Error with document picker', e);
      return null;
    }
  }

  /// Pick image from gallery
  Future<String?> _pickFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
      );

      if (image == null) return null;
      return _processPickedFile(File(image.path));
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        _logError('Photo access denied', e);
        throw Exception('Please grant permission to access photos.');
      } else {
        _logError('Error picking image', e);
        throw Exception('Failed to pick image: ${e.message}');
      }
    } catch (e) {
      _logError('Error picking image', e);
      rethrow;
    }
  }

  /// Process the picked file
  Future<String?> _processPickedFile(File file) async {
    _logError('Processing picked file: ${file.path}');
    final fileExtension = path.extension(file.path).toLowerCase();

    // Check if the file is one of the supported types
    if (!['.jpg', '.jpeg', '.png', '.svg'].contains(fileExtension)) {
      throw Exception('Unsupported file format. Please use PNG, JPG or SVG.');
    }

    // Check file size
    final int fileSize = await file.length();
    _logError('File size: $fileSize bytes');
    if (fileSize > 1024 * 1024) {
      // 1MB
      throw Exception('File size should not exceed 1MB.');
    }

    // Copy file to app documents directory with a unique name
    final appDir = await getApplicationDocumentsDirectory();
    final uuid = const Uuid().v4();
    final targetDir = Directory('${appDir.path}/logos');

    // Create directory if it doesn't exist
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetPath = '${targetDir.path}/$uuid$fileExtension';
    _logError('Copying file to: $targetPath');

    try {
      // Copy the file
      await file.copy(targetPath);
      _logError('File successfully copied');

      // Verify the file was copied
      final copiedFile = File(targetPath);
      final exists = await copiedFile.exists();
      _logError('Verified file exists at target path: $exists');

      if (!exists) {
        _logError('WARNING: File was not copied successfully!');
        return null;
      }

      return targetPath;
    } catch (e) {
      _logError('Error copying file: $e');
      return null;
    }
  }

  /// Get a widget to display the logo with proper constraints
  Widget getLogoWidget(
    String? logoPath, {
    double maxWidth = 120,
    double maxHeight = 75,
  }) {
    if (logoPath == null || logoPath.isEmpty) {
      _logError('getLogoWidget called with null or empty path');
      return const SizedBox.shrink();
    }

    // Check if file exists first
    final file = File(logoPath);
    if (!file.existsSync()) {
      _logError('Logo file does not exist: $logoPath');

      // Try to see if there's a backup in the logos_backup directory
      try {
        final fileName = path.basename(logoPath);
        // This is an async method - we need to use a synchronous approach instead
        final pathComponents = logoPath.split('/');
        final appDirPath = pathComponents
            .sublist(0, pathComponents.indexOf('logos') + 1)
            .join('/');
        final backupDir = '$appDirPath/../logos_backup';
        final backupPath = '$backupDir/$fileName';
        _logError('Trying backup path: $backupPath');

        final backupFile = File(backupPath);
        if (backupFile.existsSync()) {
          _logError('Found backup logo file at: $backupPath');

          // Use appropriate widget based on file extension
          final fileExtension = path.extension(backupPath).toLowerCase();
          if (fileExtension == '.svg') {
            // SVG file
            return SvgPicture.file(
              backupFile,
              fit: BoxFit.contain,
              width: maxWidth,
              height: maxHeight,
            );
          } else {
            // Image file
            return Image.file(
              backupFile,
              fit: BoxFit.contain,
              width: maxWidth,
              height: maxHeight,
            );
          }
        }
      } catch (e) {
        _logError('Error trying to find backup file', e);
      }

      // Fall back to placeholder if no file exists
      return Container(
        width: maxWidth,
        height: maxHeight,
        decoration: BoxDecoration(
          color: Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(Icons.image, color: Color(0xFF8D9694), size: 24),
        ),
      );
    }

    // Use appropriate widget based on file extension
    final fileExtension = path.extension(logoPath).toLowerCase();
    if (fileExtension == '.svg') {
      // SVG file
      return SvgPicture.file(
        file,
        fit: BoxFit.contain,
        width: maxWidth,
        height: maxHeight,
      );
    } else {
      // Image file
      return Image.file(
        file,
        fit: BoxFit.contain,
        width: maxWidth,
        height: maxHeight,
      );
    }
  }

  /// Delete a logo file
  Future<void> deleteLogo(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty) return;

    try {
      final file = File(logoPath);
      if (await file.exists()) {
        // Before deleting, check if this path is used in current company info
        bool shouldDelete = true;
        _logError('Checking if logo should be deleted: $logoPath');

        // Only delete if we're sure it's safe to do so
        if (shouldDelete) {
          await file.delete();
          _logError('Logo file deleted: $logoPath');
        // ignore: dead_code
        } else {
        }
      }
    } catch (e) {
      _logError('Error deleting logo file', e);
    }
  }
}
