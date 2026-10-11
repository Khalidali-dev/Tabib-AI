import 'package:flutter/material.dart';
import '../../domain/domain.dart';
import '../theme/app_theme.dart';
import 'app_spacing.dart';

/// Modal bottom sheet for region and emergency protocol selection.
class EmergencyRegionBottomSheet extends StatelessWidget {
  final EmergencyCountryInfo currentCountry;
  final ValueChanged<EmergencyCountryInfo> onSelected;

  const EmergencyRegionBottomSheet({
    super.key,
    required this.currentCountry,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required EmergencyCountryInfo currentCountry,
    required ValueChanged<EmergencyCountryInfo> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencyRegionBottomSheet(
        currentCountry: currentCountry,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            AppGap.h16,
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppTheme.primaryTeal, size: 22),
                AppGap.w8,
                Text(
                  'Select Emergency Country',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            AppGap.h6,
            Text(
              'Emergency numbers adapt automatically to your selected region.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            AppGap.h14,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: EmergencyService.supportedCountries.length,
                separatorBuilder: (_, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final item = EmergencyService.supportedCountries[index];
                  final isSelected =
                      item.countryCode == currentCountry.countryCode;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Text(
                      item.flagEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Row(
                      children: [
                        Text(
                          item.countryName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14.5,
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.emergencyRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dial ${item.emergencyNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emergencyRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${item.serviceName} • ${item.nationalLanguageName}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.accentEmerald, size: 22)
                        : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
