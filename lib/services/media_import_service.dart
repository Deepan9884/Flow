import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaImportService {
  static const _imageExts = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'};
  static const _audioExts = {'mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'opus'};

  /// Picks an image file and saves it persistently to the application's
  /// documents directory inside a sub-directory named 'wallpapers'.
  /// Returns the persistent path of the saved file, or null if cancelled/failed.
  static Future<String?> pickAndSaveImage() => _pickAndSave(
        type: FileType.image,
        subDir: 'wallpapers',
        allowed: _imageExts,
        fallbackExt: 'png',
      );

  /// Picks an audio file and saves it persistently to the application's
  /// documents directory inside a sub-directory named 'sounds'.
  /// Returns the persistent path of the saved file, or null if cancelled/failed.
  static Future<String?> pickAndSaveAudio() => _pickAndSave(
        type: FileType.audio,
        subDir: 'sounds',
        allowed: _audioExts,
        fallbackExt: 'mp3',
      );

  static Future<String?> _pickAndSave({
    required FileType type,
    required String subDir,
    required Set<String> allowed,
    required String fallbackExt,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
      if (result == null || result.files.isEmpty) return null;
      final PlatformFile picked = result.files.first;
      final String? sourcePath = picked.path;
      if (sourcePath == null) return null;

      // Prefer file_picker's own extension; sanitize against an allowlist so
      // dotted directory names can never produce an illegal target filename.
      var ext = (picked.extension ?? '').toLowerCase();
      if (!allowed.contains(ext)) {
        final dot = sourcePath.lastIndexOf('.');
        final fromPath = dot == -1 ? '' : sourcePath.substring(dot + 1).toLowerCase();
        ext = allowed.contains(fromPath) ? fromPath : fallbackExt;
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String newDir = '${appDocDir.path}/$subDir';
      await Directory(newDir).create(recursive: true);

      final String uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
      final File targetFile = await sourceFile.copy('$newDir/$uniqueId.$ext');
      return targetFile.path;
    } catch (_) {
      // Cancellation and failures are both reported as null (no user feedback
      // needed: pickers simply close).
      return null;
    }
  }
}
