import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/services/emergency_service.dart';
import '../theme/app_theme.dart';
import 'app_spacing.dart';

Future<bool> launchEmergencyDialer(String number) async {
  final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
  final phoneUri = Uri(scheme: 'tel', path: cleanNumber);
  try {
    final launched = await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return true;
  } catch (_) {}

  try {
    if (await canLaunchUrl(phoneUri)) {
      return await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (_) {}

  return false;
}

class EmergencyBanner extends StatelessWidget {
  final EmergencyCountryInfo currentCountry;
  final Animation<double>? pulseAnimation;
  final bool isDark;

  const EmergencyBanner({
    super.key,
    required this.currentCountry,
    required this.isDark,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final bannerIcon = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.emergencyRed.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: AppTheme.emergencyRed,
        size: 19,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.emergencyRed.withValues(alpha: isDark ? 0.18 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.emergencyRed.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (pulseAnimation != null)
            ScaleTransition(
              scale: pulseAnimation!,
              child: bannerIcon,
            )
          else
            bannerIcon,
          AppGap.w8,
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                ),
                children: [
                  const TextSpan(
                    text: 'EMERGENCY TRIAGE: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(
                    text:
                        'For acute chest pain, severe dyspnea, or uncontrolled bleeding, dial ',
                  ),
                  TextSpan(
                    text: '${currentCountry.emergencyNumber} (${currentCountry.serviceName})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' immediately.'),
                ],
              ),
            ),
          ),
          AppGap.w8,
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.call_rounded, size: 13),
            label: Text(
              currentCountry.emergencyNumber,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              launchEmergencyDialer(currentCountry.emergencyNumber);
            },
          ),
        ],
      ),
    );
  }
}
