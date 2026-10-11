import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../tabib.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadBloc>().add(const CheckModelStatusEvent());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToChat(BuildContext context, String modelPath) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(modelPath: modelPath)),
    );
  }

  void _navigateToDownload(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DownloadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<DownloadBloc, DownloadState>(
      listener: (context, state) {
        if (state is ModelAvailable) {
          _navigateToChat(context, state.modelPath);
        } else if (state is DownloadInitial || state is DownloadError) {
          _navigateToDownload(context);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0F1A2C),
                      const Color(0xFF090E18),
                    ]
                  : [
                      const Color(0xFFE0F2F1),
                      const Color(0xFFF8FAFC),
                    ],
            ),
          ),
          child: SafeArea(
            child: ResponsiveContainer(
              maxWidth: 600,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 56,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  AppGap.h32,
                  Text(
                    'TABIB',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  AppGap.h8,
                  Text(
                    'Clinical Decision Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  AppGap.h12,
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentEmerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: AppTheme.accentEmerald),
                        AppGap.w6,
                        Text(
                          'Clinical Decision Support',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const AppSpinner(
                    size: 26,
                    strokeWidth: 2.6,
                    color: AppTheme.primaryTeal,
                  ),
                  AppGap.h16,
                  Text(
                    'Inspecting on-device clinical weights...',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  AppGap.h28,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
