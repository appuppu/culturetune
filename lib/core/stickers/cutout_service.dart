import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';

/// 写真から被写体を自動切り抜きして透過PNGのパスを返す。
/// iOS: VisionKit(iOS 17+) / Android: ML Kit Subject Segmentation。
/// 非対応環境や被写体なしのときはnull(呼び出し側で「切り抜きなしシール」に
/// フォールバックする)。
class CutoutService {
  static const _channel = MethodChannel('culturetune/cutout');

  static Future<String?> cutoutSubject(String imagePath) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _channel.invokeMethod<String>('subject', {
          'path': imagePath,
        });
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _cutoutAndroid(imagePath);
      }
    } on PlatformException {
      // unsupported / no_subject / cutout_failed → フォールバック
    } catch (_) {}
    return null;
  }

  static Future<String?> _cutoutAndroid(String imagePath) async {
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );
    try {
      final result = await segmenter.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final bitmap = result.foregroundBitmap;
      if (bitmap == null || bitmap.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/cutout_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(bitmap);
      return out.path;
    } finally {
      segmenter.close();
    }
  }
}
