import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaImportService {
  /// Picks an image file and saves it persistently to the application's documents directory
  /// inside a sub-directory named 'wallpapers'.
  /// Returns the persistent path of the saved file, or null if cancelled/failed.
  static Future<String?> pickAndSaveImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.isEmpty) return null;
      final String? sourcePath = result.files.first.path;
      if (sourcePath == null) return null;

      final File sourceFile = File(sourcePath);
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      final String ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'png';
      final String uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
      final String newDir = '${appDocDir.path}/wallpapers';
      
      // Ensure directory exists
      await Directory(newDir).create(recursive: true);
      
      final String targetPath = '$newDir/$uniqueId.$ext';
      final File targetFile = await sourceFile.copy(targetPath);
      
      return targetFile.path;
    } catch (e) {
      // Graceful fallback on error
      return null;
    }
  }

  /// Picks an audio file and saves it persistently to the application's documents directory
  /// inside a sub-directory named 'sounds'.
  /// Returns the persistent path of the saved file, or null if cancelled/failed.
  static Future<String?> pickAndSaveAudio() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result == null || result.files.isEmpty) return null;
      final String? sourcePath = result.files.first.path;
      if (sourcePath == null) return null;

      final File sourceFile = File(sourcePath);
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      final String ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'mp3';
      final String uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
      final String newDir = '${appDocDir.path}/sounds';
      
      // Ensure directory exists
      await Directory(newDir).create(recursive: true);
      
      final String targetPath = '$newDir/$uniqueId.$ext';
      final File targetFile = await sourceFile.copy(targetPath);
      
      return targetFile.path;
    } catch (e) {
      // Graceful fallback on error
      return null;
    }
  }
}
