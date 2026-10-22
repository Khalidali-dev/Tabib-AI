import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tabib.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _entranceController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _badgeFade;
  late Animation<double> _loaderFade;

  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  bool _minSplashDurationPassed = false;
  DownloadState? _pendingState;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance choreography controller (1600ms smooth build-up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeIn),
      ),
    );

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous Organic Pulse for Logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 3. Ambient Glow oscillation behind medical icon
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _glowRadius = Tween<double>(begin: 20.0, end: 42.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      }
    });

    // 4. Ensure a minimum luxurious delay for the splash animation (2.6 seconds)
    _splashTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _minSplashDurationPassed = true;
      });
      if (_pendingState != null) {
        _processDestination(_pendingState!);
      }
    });

    // Dispatch background check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadBloc>().add(const CheckModelStatusEvent());
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _processDestination(DownloadState state) {
    if (state is ModelAvailable) {
      _navigateToChat(context, state.modelPath);
    } else if (state is DownloadInitial || state is DownloadError) {
      _navigateToDownload(context);
    }
  }

  void _navigateToChat(BuildContext context, String modelPath) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(modelPath: modelPath),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToDownload(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DownloadScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<DownloadBloc, DownloadState>(
      listener: (context, state) {
        _pendingState = state;
        if (_minSplashDurationPassed) {
          _processDestination(state);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0A0F1D),
                      const Color(0xFF0F1A2C),
                      const Color(0xFF050B14),
                    ]
                  : [
                      const Color(0xFFF0FDFA),
                      const Color(0xFFE6FFFA),
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
                  const Spacer(flex: 3),

                  // Animated Emblem + Icon
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _entranceController,
                      _pulseController,
                      _glowController,
                    ]),
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale:
                              _logoScale.value *
                              (_entranceController.isCompleted
                                  ? _pulseAnimation.value
                                  : 1.0),
                          child: Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF14B8A6),
                                  Color(0xFF0D9488),
                                  Color(0xFF0F766E),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.45),
                                  blurRadius: _entranceController.isCompleted
                                      ? _glowRadius.value
                                      : 28.0,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.local_hospital_rounded,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  Positioned(
                                    bottom: 30,
                                    child: Icon(
                                      Icons.show_chart_rounded,
                                      size: 26,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  AppGap.h32,

                  // Title and Subtitle with slide & fade
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TABIB',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              AppGap.w8,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppGap.h8,
                          Text(
                            'Offline Clinical Decision Support',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppGap.h16,

                  // Clinical Badge with Fade
                  FadeTransition(
                    opacity: _badgeFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 15,
                            color: Color(0xFF0D9488),
                          ),
                          AppGap.w8,
                          Text(
                            '100% On-Device Private Intelligence',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Loader Indicator & Status Text
                  FadeTransition(
                    opacity: _loaderFade,
                    child: Column(
                      children: [
                        const AppSpinner(
                          size: 28,
                          strokeWidth: 2.8,
                          color: Color(0xFF0D9488),
                        ),
                        AppGap.h16,
                        Text(
                          'Initializing on-device clinical weights...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppGap.h32,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
