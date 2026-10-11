import 'package:equatable/equatable.dart';

abstract class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

class DownloadInitial extends DownloadState {
  const DownloadInitial();
}

class DownloadChecking extends DownloadState {
  const DownloadChecking();
}

class ModelAvailable extends DownloadState {
  final String modelPath;

  const ModelAvailable(this.modelPath);

  @override
  List<Object?> get props => [modelPath];
}

class DownloadingState extends DownloadState {
  final double progress; // 0.0 to 1.0
  final double receivedMB;
  final double totalMB;
  final double speedMBps;
  final String statusMessage;

  const DownloadingState({
    required this.progress,
    required this.receivedMB,
    required this.totalMB,
    required this.speedMBps,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [
        progress,
        receivedMB,
        totalMB,
        speedMBps,
        statusMessage,
      ];
}

class DownloadCompleted extends DownloadState {
  final String modelPath;

  const DownloadCompleted(this.modelPath);

  @override
  List<Object?> get props => [modelPath];
}

class DownloadError extends DownloadState {
  final String message;

  const DownloadError(this.message);

  @override
  List<Object?> get props => [message];
}
