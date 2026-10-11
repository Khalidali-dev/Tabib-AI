import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Progress snapshot emitted during model download.
class ModelDownloadProgress {
  final double progress; // 0.0 to 1.0
  final double receivedMB;
  final double totalMB;
  final double speedMBps;
  final String statusMessage;
  final bool isCompleted;

  const ModelDownloadProgress({
    required this.progress,
    required this.receivedMB,
    required this.totalMB,
    required this.speedMBps,
    required this.statusMessage,
    this.isCompleted = false,
  });

  factory ModelDownloadProgress.initial() {
    return const ModelDownloadProgress(
      progress: 0.0,
      receivedMB: 0.0,
      totalMB: 0.0,
      speedMBps: 0.0,
      statusMessage: 'Ready to download model...',
      isCompleted: false,
    );
  }
}

/// Robust, resumable chunked file download engine for the  Medical GGUF weights.
class ModelDownloader {
  static const String defaultModelUrl =
      'https://huggingface.co/khalidalidev/qwen2.5-3b-medical-doctor-gguf/resolve/main/Qwen2.5-3B-Instruct.Q4_K_M.gguf';

  static const String modelFileName = 'Qwen2.5-3B-Instruct.Q4_K_M.gguf';
  static const String tempFileName = 'Qwen2.5-3B-Instruct.Q4_K_M.gguf.tmp';

  /// Minimum threshold for integrity check (1.5 GB in bytes)
  static const int minValidSizeBytes =
      1500 * 1024 * 1024; // 1,572,864,000 bytes

  final Dio _dio;
  CancelToken? _cancelToken;
  final StreamController<ModelDownloadProgress> _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  ModelDownloader({Dio? dio}) : _dio = dio ?? Dio();

  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Returns target model file path on the device.
  Future<String> getModelFilePath() async {
    if (kIsWeb) {
      return '/model/$modelFileName';
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, modelFileName);
  }

  /// Returns temporary download file path.
  Future<String> getTempFilePath() async {
    if (kIsWeb) {
      return '/model/$tempFileName';
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, tempFileName);
  }

  /// Checks if the model file is already downloaded and passes the integrity threshold (>1.5 GB).
  Future<bool> isModelDownloaded() async {
    if (kIsWeb) {
      // In web fallback, check in-memory or return true if web demo mode enabled
      return true;
    }

    try {
      final targetPath = await getModelFilePath();
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        return false;
      }

      final length = await targetFile.length();
      debugPrint('[ModelDownloader] Existing model file size: $length bytes');
      return length >= minValidSizeBytes;
    } catch (e) {
      debugPrint('[ModelDownloader] Error checking model file: $e');
      return false;
    }
  }

  /// Initiates or resumes downloading the model file with chunked streaming and staging.
  Future<String> downloadModel({
    String url = defaultModelUrl,
    void Function(ModelDownloadProgress)? onProgress,
  }) async {
    if (kIsWeb) {
      _progressController.add(
        const ModelDownloadProgress(
          progress: 1.0,
          receivedMB: 1850.0,
          totalMB: 1850.0,
          speedMBps: 0.0,
          statusMessage:
              'Web environment: using cloud/direct streaming runtime.',
          isCompleted: true,
        ),
      );
      return '/model/$modelFileName';
    }

    final targetPath = await getModelFilePath();
    final tempPath = await getTempFilePath();

    final targetFile = File(targetPath);
    final tempFile = File(tempPath);

    // Verify existing target file
    if (await targetFile.exists()) {
      final existingSize = await targetFile.length();
      if (existingSize >= minValidSizeBytes) {
        final progress = ModelDownloadProgress(
          progress: 1.0,
          receivedMB: existingSize / (1024 * 1024),
          totalMB: existingSize / (1024 * 1024),
          speedMBps: 0.0,
          statusMessage: 'Model verified and ready.',
          isCompleted: true,
        );
        _progressController.add(progress);
        onProgress?.call(progress);
        return targetPath;
      } else {
        // Corrupted or incomplete, delete and redownload
        await targetFile.delete();
      }
    }

    _cancelToken = CancelToken();

    int existingBytes = 0;
    if (await tempFile.exists()) {
      existingBytes = await tempFile.length();
    }

    int lastTime = DateTime.now().millisecondsSinceEpoch;
    int lastBytes = existingBytes;

    final openMode = existingBytes > 0 ? FileMode.append : FileMode.write;
    final fileAccess = await tempFile.open(mode: openMode);

    try {
      final headers = <String, dynamic>{'Accept-Encoding': 'identity'};
      if (existingBytes > 0) {
        headers['Range'] = 'bytes=$existingBytes-';
        debugPrint(
          '[ModelDownloader] Resuming download from byte: $existingBytes',
        );
      }

      final response = await _dio.get<ResponseBody>(
        url,
        cancelToken: _cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          followRedirects: true,
          validateStatus: (status) =>
              status != null &&
              (status >= 200 && status < 300 || status == 304),
        ),
      );

      final contentLengthHeader = response.headers.value(
        Headers.contentLengthHeader,
      );
      int totalBytes = existingBytes;
      if (contentLengthHeader != null) {
        totalBytes += int.tryParse(contentLengthHeader) ?? 0;
      }
      if (totalBytes == 0) {
        // Fallback estimated Q4_K_M size (~1.86 GB)
        totalBytes = (1.86 * 1024 * 1024 * 1024).toInt();
      }

      int receivedBytes = existingBytes;

      await for (final chunk in response.data!.stream) {
        if (_cancelToken?.isCancelled ?? false) {
          break;
        }

        await fileAccess.writeFrom(chunk);
        receivedBytes += chunk.length;

        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final timeDelta = (currentTime - lastTime) / 1000.0;

        double speedMBps = 0.0;
        if (timeDelta >= 0.5) {
          final bytesDelta = receivedBytes - lastBytes;
          speedMBps = (bytesDelta / (1024 * 1024)) / timeDelta;
          lastBytes = receivedBytes;
          lastTime = currentTime;

          final progressRatio = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          final progress = ModelDownloadProgress(
            progress: progressRatio,
            receivedMB: receivedBytes / (1024 * 1024),
            totalMB: totalBytes / (1024 * 1024),
            speedMBps: speedMBps,
            statusMessage:
                'Downloading Medical Model: ${(progressRatio * 100).toStringAsFixed(1)}%',
            isCompleted: false,
          );
          _progressController.add(progress);
          onProgress?.call(progress);
        }
      }

      await fileAccess.close();

      // Integrity check
      final finalTempSize = await tempFile.length();
      debugPrint(
        '[ModelDownloader] Download finished. Staged size: $finalTempSize bytes',
      );

      if (finalTempSize < minValidSizeBytes) {
        throw Exception(
          'Model file integrity check failed: Downloaded $finalTempSize bytes, but expected >= $minValidSizeBytes bytes.',
        );
      }

      // Rename from .tmp to final .gguf file
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetPath);

      final completedProgress = ModelDownloadProgress(
        progress: 1.0,
        receivedMB: finalTempSize / (1024 * 1024),
        totalMB: finalTempSize / (1024 * 1024),
        speedMBps: 0.0,
        statusMessage: 'Model verified and staged successfully.',
        isCompleted: true,
      );
      _progressController.add(completedProgress);
      onProgress?.call(completedProgress);

      return targetPath;
    } catch (e) {
      await fileAccess.close();
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('[ModelDownloader] Download paused/cancelled by user.');
      } else {
        debugPrint('[ModelDownloader] Download failure: $e');
      }
      rethrow;
    }
  }

  /// Cancels active download stream.
  void cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = null;
  }

  void dispose() {
    cancelDownload();
    _progressController.close();
  }
}
