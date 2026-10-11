import 'package:flutter/material.dart';

/// Clean, responsive English Welcome Card benchmarked against Claude/ChatGPT Health.
/// Replaces legacy localized templates with a standardized clinical overview.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildWelcomeCard(context);
  }

  static Widget buildWelcomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tabib Clinical Intelligence",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Welcome to Tabib AI Doctor — your private, on-device clinical decision support engine.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            isDark: isDark,
            icon: Icons.verified_user_outlined,
            title: "Verified Pharmacology",
            subtitle: "Deterministic dosage calculations and ceiling limits from verified local formularies.",
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            isDark: isDark,
            icon: Icons.lock_outline,
            title: "100% Privacy Preserved",
            subtitle: "Zero cloud telemetry. Inference executes entirely on your device's local neural runtime.",
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            isDark: isDark,
            icon: Icons.emergency_outlined,
            title: "Emergency Triage Filter",
            subtitle: "Immediate red-flag detection for time-critical conditions (Chest Pain, Stroke, DKA).",
          ),
          const SizedBox(height: 14),
          Text(
            "Type your clinical inquiry or select a quick clinical assessment chip below to begin.",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeatureItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: subtitle,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
