import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../tabib.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final ModelDownloader modelDownloader;
  StreamSubscription<ModelDownloadProgress>? _progressSubscription;

  DownloadBloc({required this.modelDownloader})
    : super(const DownloadInitial()) {
    on<CheckModelStatusEvent>(_onCheckModelStatus);
    on<StartDownloadEvent>(_onStartDownload);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<CancelDownloadEvent>(_onCancelDownload);
    on<RetryDownloadEvent>(_onRetryDownload);
  }

  Future<void> _onCheckModelStatus(
    CheckModelStatusEvent event,
    Emitter<DownloadState> emit,
  ) async {
    emit(const DownloadChecking());
    try {
      final isDownloaded = await modelDownloader.isModelDownloaded();
      final modelPath = await modelDownloader.getModelFilePath();
      if (isDownloaded) {
        emit(ModelAvailable(modelPath));
      } else {
        emit(const DownloadInitial());
      }
    } catch (e) {
      emit(DownloadError('Failed to inspect model file status: $e'));
    }
  }

  Future<void> _onStartDownload(
    StartDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      _enableWakelock();

      emit(
        const DownloadingState(
          progress: 0.0,
          receivedMB: 0.0,
          totalMB: 1850.0,
          speedMBps: 0.0,
          statusMessage: 'Connecting to Server...',
        ),
      );

      await _progressSubscription?.cancel();
      _progressSubscription = modelDownloader.progressStream.listen(
        (progress) {
          add(UpdateProgressEvent(progress));
        },
        onError: (err) {
          add(CancelDownloadEvent());
        },
      );

      final path = await modelDownloader.downloadModel();
      _disableWakelock();
      emit(DownloadCompleted(path));
    } catch (e) {
      _disableWakelock();
      emit(DownloadError('Download failed: $e'));
    }
  }

  void _onUpdateProgress(
    UpdateProgressEvent event,
    Emitter<DownloadState> emit,
  ) {
    if (state is DownloadingState) {
      emit(
        DownloadingState(
          progress: event.progress.progress,
          receivedMB: event.progress.receivedMB,
          totalMB: event.progress.totalMB,
          speedMBps: event.progress.speedMBps,
          statusMessage: event.progress.statusMessage,
        ),
      );
    }
  }

  Future<void> _onCancelDownload(
    CancelDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    modelDownloader.cancelDownload();
    await _progressSubscription?.cancel();
    _disableWakelock();
    emit(const DownloadInitial());
  }

  Future<void> _onRetryDownload(
    RetryDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    add(const StartDownloadEvent());
  }

  void _enableWakelock() {
    try {
      WakelockPlus.enable();
    } catch (e) {
      debugPrint('[DownloadBloc] Wakelock enable error: $e');
    }
  }

  void _disableWakelock() {
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('[DownloadBloc] Wakelock disable error: $e');
    }
  }

  @override
  Future<void> close() {
    _disableWakelock();
    _progressSubscription?.cancel();
    return super.close();
  }
}
