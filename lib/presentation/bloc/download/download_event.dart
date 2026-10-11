import 'package:equatable/equatable.dart';
import '../../../tabib.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class CheckModelStatusEvent extends DownloadEvent {
  const CheckModelStatusEvent();
}

class StartDownloadEvent extends DownloadEvent {
  const StartDownloadEvent();
}

class UpdateProgressEvent extends DownloadEvent {
  final ModelDownloadProgress progress;

  const UpdateProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class CancelDownloadEvent extends DownloadEvent {
  const CancelDownloadEvent();
}

class RetryDownloadEvent extends DownloadEvent {
  const RetryDownloadEvent();
}
