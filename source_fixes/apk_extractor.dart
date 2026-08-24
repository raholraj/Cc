// ============================================================
// apk_extractor.dart — APK file ko extract karne ki service
// APK = just a ZIP file hota hai!
// ============================================================

import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:flutter_archive/flutter_archive.dart' as fa;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/asset_item.dart';

// ─────────────────────────────────────────────
// Progress tracking
// ─────────────────────────────────────────────

class ExtractProgress {
  final double fraction; // 0.0 to 1.0
  final String message;
  const ExtractProgress(this.fraction, this.message);
}

class ExtractResult {
  final String extractDir;
  final int totalFiles;
  final bool success;
  final String? error;
  const ExtractResult({
    required this.extractDir,
    required this.totalFiles,
    required this.success,
    this.error,
  });
}

// ─────────────────────────────────────────────
// Main service class
// ─────────────────────────────────────────────

class ApkExtractor {
  String? _currentExtractDir;
  String? get currentExtractDir => _currentExtractDir;

  /// APK extract karo — Stream ke zariye progress milti hai
  Stream<ExtractProgress> extract(String apkPath) async* {
    try {
      yield const ExtractProgress(0.05, 'APK file khul rahi hai...');

      // Temp directory mein extract karo
      final tempDir = await getTemporaryDirectory();
      final apkBaseName = p.basenameWithoutExtension(apkPath);
      final extractDir = p.join(tempDir.path, 'apk_extracted_$apkBaseName');

      // Pehle se extract hai toh delete karo
      final dir = Directory(extractDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      dir.createSync(recursive: true);
      _currentExtractDir = extractDir;

      yield const ExtractProgress(0.15, 'Native unzip se extract ho raha hai...');

      // ─── PRIMARY: Native platform unzip (Android/iOS ka system zip engine) ───
      // Real signed APKs mein APK Signing Block (v2/v3) aur zipalign extra
      // fields hote hain jo standard ZIP spec ka hissa nahi hain — pure-Dart
      // 'archive' package inhe parse karte waqt RangeError de sakta hai.
      // Native unzip in dono cheezon ko sahi handle karta hai.
      bool nativeSuccess = false;
      try {
        await fa.ZipFile.extractToDirectory(
          zipFile: File(apkPath),
          destinationDir: Directory(extractDir),
        );
        nativeSuccess = true;
      } catch (nativeErr) {
        nativeSuccess = false;
      }

      // ─── FALLBACK: pure-Dart archive package ───
      // Agar native unzip kisi wajah se fail ho jaaye (rare), toh yeh try karo.
      if (!nativeSuccess) {
        yield const ExtractProgress(0.25, 'Fallback extractor try ho raha hai...');

        Archive archive;
        try {
          final inputStream = InputFileStream(apkPath);
          archive = ZipDecoder().decodeBuffer(inputStream);
        } catch (_) {
          try {
            final bytes = File(apkPath).readAsBytesSync();
            archive = ZipDecoder().decodeBytes(bytes, verify: false);
          } catch (e2) {
            yield ExtractProgress(
              -1,
              'Extract nahi ho saka. Yeh APK corrupt hai ya split/bundle format '
              '(XAPK/APKM) ho sakti hai jo support nahi hoti. ($e2)',
            );
            return;
          }
        }

        final total = archive.files.length;
        int current = 0;

        for (final file in archive.files) {
          current++;

          if (_shouldSkip(file.name)) continue;

          if (file.isFile) {
            final outPath = p.join(extractDir, file.name.replaceAll('/', p.separator));
            final outFile = File(outPath);
            outFile.parent.createSync(recursive: true);
            try {
              final bytes = file.content as List<int>;
              outFile.writeAsBytesSync(bytes);
            } catch (_) {
              // Agar koi file fail ho toh skip karo
            }
          }

          if (current % 10 == 0) {
            final fraction = 0.25 + (current / total) * 0.65;
            yield ExtractProgress(
              fraction,
              'Extract ho raha hai... ($current/$total)',
            );
          }
        }
      }

      yield const ExtractProgress(0.95, 'Assets scan kar rahe hain...');
      await Future.delayed(const Duration(milliseconds: 100));
      yield const ExtractProgress(1.0, 'Extract complete!');
    } catch (e) {
      yield ExtractProgress(-1, 'Error: $e');
    }
  }

  /// Kuch files skip karo — sirf assets chahiye, code nahi
  bool _shouldSkip(String filename) {
    final lower = filename.toLowerCase();
    // Compiled code
    if (lower.endsWith('.dex')) return true;
    // Signature files
    if (lower.startsWith('meta-inf/')) return true;
    // Java class files
    if (lower.endsWith('.class')) return true;
    return false;
  }

  // ─────────────────────────────────────────────
  // Export functions
  // ─────────────────────────────────────────────

  /// Ek asset ko export karo
  Future<String> exportAsset(AssetItem asset, String destinationDir) async {
    final destDir = Directory(destinationDir);
    if (!destDir.existsSync()) destDir.createSync(recursive: true);

    final dest = File(p.join(destinationDir, asset.name));
    final src = File(asset.fullPath);

    if (!src.existsSync()) throw Exception('Source file nahi mila: ${asset.fullPath}');

    await src.copy(dest.path);
    return dest.path;
  }

  /// Multiple assets export karo
  Future<ExportResult> exportAssets(
    List<AssetItem> assets, {
    void Function(int done, int total)? onProgress,
  }) async {
    final downloadDir = '/storage/emulated/0/Download/APK_3D_Assets';
    final dest = Directory(downloadDir);
    if (!dest.existsSync()) dest.createSync(recursive: true);

    final List<String> exported = [];
    final List<String> failed = [];

    for (int i = 0; i < assets.length; i++) {
      try {
        final path = await exportAsset(assets[i], downloadDir);
        exported.add(path);
      } catch (e) {
        failed.add(assets[i].name);
      }
      onProgress?.call(i + 1, assets.length);
    }

    return ExportResult(
      exportedPaths: exported,
      failedNames: failed,
      outputDir: downloadDir,
    );
  }

  /// Temp files clean up karo
  void cleanup() {
    if (_currentExtractDir != null) {
      final dir = Directory(_currentExtractDir!);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      _currentExtractDir = null;
    }
  }
}

class ExportResult {
  final List<String> exportedPaths;
  final List<String> failedNames;
  final String outputDir;

  const ExportResult({
    required this.exportedPaths,
    required this.failedNames,
    required this.outputDir,
  });

  int get successCount => exportedPaths.length;
  int get failCount => failedNames.length;
  bool get allSuccess => failedNames.isEmpty;
}
