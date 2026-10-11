import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tabib.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, state) {
        if (state is DownloadCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.accentEmerald,
              content: Text('Medical model verified and initialized!'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChatScreen(modelPath: state.modelPath),
            ),
          );
        }
      },
      builder: (context, state) {
        final isDownloading = state is DownloadingState;
        final isError = state is DownloadError;

        double progress = 0.0;
        double receivedMB = 0.0;
        double totalMB = 1850.0;
        double speedMBps = 0.0;
        String statusText = 'Ready to download medical AI weights';

        if (state is DownloadingState) {
          progress = state.progress;
          receivedMB = state.receivedMB;
          totalMB = state.totalMB > 0 ? state.totalMB : 1850.0;
          speedMBps = state.speedMBps;
          statusText = state.statusMessage;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: AppTheme.primaryTeal,
                  size: 24,
                ),
                AppGap.w8,
                Text(
                  'Tabib Setup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            elevation: 0,
          ),
          body: ResponsiveContainer(
            maxWidth: 720,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppGap.h12,
                  // Model Identity Card using reusable AppGlassCard
                  AppGlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.memory_rounded,
                                color: AppTheme.primaryTeal,
                                size: 28,
                              ),
                            ),
                            AppGap.w14,
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tabib Clinical AI Model',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppGap.h2,
                                  Text(
                                    'Quantization: Q4_K_M • Format: GGUF',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppGap.h16,
                        const Divider(height: 1),
                        AppGap.h16,
                        _buildFeatureRow(
                          icon: Icons.offline_bolt_rounded,
                          title: '100% Offline Medical Intelligence',
                          subtitle: 'Once downloaded, all clinical diagnosis and reasoning runs directly on your device CPU/NPU without internet.',
                          isDark: isDark,
                        ),
                        AppGap.h12,
                        _buildFeatureRow(
                          icon: Icons.verified_user_rounded,
                          title: 'Zero Cloud Data Leaks',
                          subtitle: 'Your health queries and symptoms remain strictly private on device local storage.',
                          isDark: isDark,
                        ),
                        AppGap.h12,
                        _buildFeatureRow(
                          icon: Icons.storage_rounded,
                          title: 'Storage Footprint: ~1.85 GB',
                          subtitle: 'Strict integrity verification ensures no truncated model weights are loaded.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  AppGap.h24,

                  // Progress Panel
                  if (isDownloading) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${receivedMB.toStringAsFixed(1)} MB / ${totalMB.toStringAsFixed(1)} MB',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            AppGap.h2,
                            Text(
                              '⚡ ${speedMBps.toStringAsFixed(2)} MB/s',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentEmerald,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppGap.h12,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress > 0.0 ? progress : null,
                        minHeight: 12,
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                    AppGap.h14,
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppGap.h16,
                  ],

                  if (state is DownloadError) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.emergencyRed,
                          ),
                          AppGap.w12,
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                color: AppTheme.emergencyRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppGap.h16,
                  ],

                  // Persistent Background Wake-Lock Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.screen_lock_portrait_rounded,
                          size: 18,
                          color: AppTheme.primaryTeal,
                        ),
                        AppGap.w10,
                        Expanded(
                          child: Text(
                            'WAKE-LOCK ACTIVE: Screen is prevented from sleeping while downloading.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppGap.h20,

                  // Action Buttons
                  if (!isDownloading) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<DownloadBloc>().add(
                          const StartDownloadEvent(),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        isError
                            ? 'Retry Download'
                            : 'Start Model Setup (1.8GB)',
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.emergencyRed,
                        side: const BorderSide(color: AppTheme.emergencyRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context.read<DownloadBloc>().add(
                          const CancelDownloadEvent(),
                        );
                      },
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Cancel Download'),
                    ),
                  ],
                  AppGap.h12,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryTeal),
        AppGap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppGap.h2,
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
