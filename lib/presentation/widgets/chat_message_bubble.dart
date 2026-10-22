import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/datasources/medicine_local_db.dart';
import '../../domain/domain.dart';
import '../theme/app_theme.dart';
import 'app_spacing.dart';

class VerifiedCitationsCard extends StatelessWidget {
  final List<MedicineEntity> records;
  final bool isDark;
  final bool isTablet;
  final String? activePrompt;

  const VerifiedCitationsCard({
    super.key,
    required this.records,
    required this.isDark,
    required this.isTablet,
    this.activePrompt,
  });

  @override
  Widget build(BuildContext context) {
    if (activePrompt != null &&
        PediatricMathHelper.isPediatricQuery(activePrompt!)) {
      return const SizedBox.shrink();
    }

    if (activePrompt != null &&
        TriageInterceptor.isSurgicalEmergencyOrContraindicated(activePrompt!)) {
      return const SizedBox.shrink();
    }

    final filtered = activePrompt != null && activePrompt!.isNotEmpty
        ? records
              .where(
                (m) => MedicalInferenceService.instance
                    .isMedicationRelevantToPrompt(m, activePrompt!),
              )
              .toList()
        : records;

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = filtered.length;
    final sourceLabel = count == 1 ? 'Clinical Source' : 'Clinical Sources';

    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 650 : MediaQuery.of(context).size.width * 0.88,
      ),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentEmerald.withValues(alpha: 0.35),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
          dense: true,
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: const Icon(
            Icons.menu_book_rounded,
            color: AppTheme.accentEmerald,
            size: 18,
          ),
          title: Text(
            '📚 $count $sourceLabel (Tap to expand)',
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentEmerald,
            ),
          ),
          children: filtered.map((med) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142035) : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF223555)
                      : const Color(0xFFCBD5E1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.genericName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true,
                            ),
                            if (med.brandNames.isNotEmpty) ...[
                              AppGap.h2,
                              Text(
                                med.brandNames,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : Colors.grey.shade600,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          med.therapeuticClass,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppGap.h8,
                  Text(
                    'Verified Adult Dose: ${med.adultDosage}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppGap.h4,
                  Text(
                    'Daily Maximum: ${med.maxDailyLimit}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  if (med.contraindications.isNotEmpty) ...[
                    AppGap.h4,
                    Text(
                      'Contraindications: ${med.contraindications}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        ),
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final bool isTablet;
  final String? activePrompt;
  final VoidCallback? onCopy;
  final VoidCallback? onEditPrompt;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.isTablet,
    this.activePrompt,
    this.onCopy,
    this.onEditPrompt,
  });

  static String getLocalizedSectionHeader(
    String section,
    MessageLanguage language,
  ) {
    final normSection = section.toUpperCase().trim();
    if (normSection.contains('ASSESSMENT') ||
        normSection.contains('IMPRESSION')) {
      return '\n\n### 🩺 Clinical Assessment\n\n';
    } else if (normSection.contains('MEDICATION')) {
      return '\n\n### 💊 Verified Medication & Dosage\n\n';
    } else if (normSection.contains('PRECAUTION') ||
        normSection.contains('LIFESTYLE') ||
        normSection.contains('SUPPORTIVE')) {
      return '\n\n### ⚠️ Precautions & Dietary Guidance\n\n';
    } else if (normSection.contains('EMERGENCY') ||
        normSection.contains('RED_FLAG')) {
      return '\n\n### 🚨 Emergency Red Flags\n\n';
    }
    return '\n\n### $section\n\n';
  }

  String _formatClinicalMarkdown(
    String rawText, {
    List<MedicineEntity>? verifiedMedications,
    MessageLanguage language = MessageLanguage.english,
  }) {
    if (rawText.isEmpty) return rawText;
    var text = rawText
        .replaceAll('###', '\n\n### ')
        .replaceAll('CLINICAL ASSESSMENT', '🩺 Clinical Assessment\n\n');

    final isSurgicalOrContraindicated =
        (activePrompt != null &&
            TriageInterceptor.isSurgicalEmergencyOrContraindicated(
              activePrompt!,
            )) ||
        TriageInterceptor.isSurgicalEmergencyOrContraindicated(text);

    if (!message.isStreaming &&
        !isSurgicalOrContraindicated &&
        !text.contains('RECOMMENDED_MEDICATION') &&
        !text.contains('Recommended Medication') &&
        !text.contains('Verified Medication & Dosage') &&
        !text.contains('VERIFIED MEDICATION & DOSAGE')) {
      final pedResult = activePrompt != null
          ? PediatricMathHelper.calculateFromQuery(activePrompt!)
          : null;
      if (pedResult != null) {
        final pedBlock = pedResult.toDeterministicPediatricMarkdown().trim();
        final precMatch = RegExp(
          r'(?:^|\n|\s+)(?:###\s*(?:🛡️\s*)?(?:Supportive Care|Lifestyle & Dietary Guidance|Precautions)|PRECAUTIONS:|\*\*\s*(?:⚠️|🛡️\s*)?PRECAUTIONS)',
          caseSensitive: false,
        ).firstMatch(text);
        if (precMatch != null) {
          final before = text.substring(0, precMatch.start).trimRight();
          final after = text.substring(precMatch.start).trimLeft();
          text = '$before\n\n$pedBlock\n\n$after';
        } else {
          text = '${text.trimRight()}\n\n$pedBlock';
        }
      } else if (verifiedMedications != null &&
          verifiedMedications.isNotEmpty) {
        final relevant = activePrompt != null && activePrompt!.isNotEmpty
            ? verifiedMedications
                  .where(
                    (m) => MedicalInferenceService.instance
                        .isMedicationRelevantToPrompt(m, activePrompt!),
                  )
                  .toList()
            : verifiedMedications;

        if (relevant.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.writeln('### 💊 Verified Medication & Dosage\n');
          for (final med in relevant.take(2)) {
            buffer.writeln(
              '• Generic Name: ${med.genericName} (${med.brandNames})',
            );
            buffer.writeln('• Therapeutic Class: ${med.therapeuticClass}');
            buffer.writeln('• Verified Adult Dose: ${med.adultDosage}');
            buffer.writeln('• Ceiling Limit: ${med.maxDailyLimit}');
            if (med.contraindications.isNotEmpty) {
              buffer.writeln(
                '• Absolute Contraindications: ${med.contraindications}',
              );
            }
          }
          final medBlock = buffer.toString().trim();
          final precMatch = RegExp(
            r'(?:^|\n|\s+)(?:###\s*(?:🛡️\s*)?(?:Supportive Care|Lifestyle & Dietary Guidance|Precautions)|PRECAUTIONS:|\*\*\s*(?:⚠️|🛡️\s*)?PRECAUTIONS)',
            caseSensitive: false,
          ).firstMatch(text);
          if (precMatch != null) {
            final before = text.substring(0, precMatch.start).trimRight();
            final after = text.substring(precMatch.start).trimLeft();
            text = '$before\n\n$medBlock\n\n$after';
          } else {
            text = '${text.trimRight()}\n\n$medBlock';
          }
        }
      }
    }

    text = text.replaceAllMapped(
      RegExp(
        r'(?:^|\n)\s*(?:###\s*)?(?:🩺|📋|💊|🛡️|⚠️|🚨)?\s*(CLINICAL ASSESSMENT|CLINICAL IMPRESSION|RECOMMENDED MEDICATION|VERIFIED MEDICATION & DOSAGE|PRECAUTIONS|PRECAUTIONS & DIETARY GUIDANCE|EMERGENCY RED FLAGS|NON-DRUG SUPPORTIVE CARE)\s*:?',
        caseSensitive: false,
      ),
      (match) {
        final rawTitle = match.group(1)!.toUpperCase();
        String section;
        if (rawTitle.contains('ASSESSMENT') ||
            rawTitle.contains('IMPRESSION')) {
          section = 'ASSESSMENT';
        } else if (rawTitle.contains('MEDICATION')) {
          section = 'RECOMMENDED_MEDICATION';
        } else if (rawTitle.contains('PRECAUTION') ||
            rawTitle.contains('SUPPORTIVE')) {
          section = 'PRECAUTIONS';
        } else if (rawTitle.contains('EMERGENCY')) {
          section = 'EMERGENCY_RED_FLAGS';
        } else {
          return match.group(0)!;
        }
        return getLocalizedSectionHeader(section, language);
      },
    );

    text = text.replaceAllMapped(
      RegExp(r'(?<=[^\n\d])\s*(\d+)\.\s+'),
      (match) => '\n\n${match.group(1)}. ',
    );

    text = text.replaceAllMapped(
      RegExp(r'(?<=[^\n])\s*([•\-\*])\s+'),
      (match) => '\n\n${match.group(1)} ',
    );

    text = text.replaceAllMapped(
      RegExp(r'(?<!\n\n)###\s*'),
      (match) => '\n\n### ',
    );

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    text = OutputSanitizer.cleanAsterisks(text);

    return text.trim();
  }

  String formatClinicalMarkdown(
    String rawText, {
    List<MedicineEntity>? verifiedMedications,
    MessageLanguage language = MessageLanguage.english,
  }) {
    return _formatClinicalMarkdown(
      rawText,
      verifiedMedications: verifiedMedications,
      language: language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = message.sender == MessageSender.patient;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);
    final rawFormatted = _formatClinicalMarkdown(
      message.content,
      verifiedMedications: (!isPatient && !message.isStreaming)
          ? message.verifiedReferences
          : null,
      language: MessageLanguage.english,
    );
    final dosageChecked = MedicineLocalDb.validateAndSanitizeDosages(
      rawFormatted,
    );
    final cleanContent = OutputSanitizer.cleanAsterisks(dosageChecked);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: isPatient
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isPatient
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isPatient) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: AppTheme.primaryTeal,
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
                AppGap.w6,
                const Text(
                  'Tabib AI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ] else ...[
                const Text(
                  'You',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                AppGap.w6,
                const CircleAvatar(
                  radius: 11,
                  backgroundColor: Color(0xFF64748B),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
              AppGap.w8,
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          AppGap.h6,
          Container(
            constraints: BoxConstraints(
              maxWidth: isTablet
                  ? 650
                  : MediaQuery.of(context).size.width * 0.88,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: isPatient
                  ? const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF00796B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPatient
                  ? null
                  : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isPatient ? 18 : 4),
                bottomRight: Radius.circular(isPatient ? 4 : 18),
              ),
              border: isPatient
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF243350)
                          : const Color(0xFFE2E8F0),
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cleanContent.isEmpty && message.isStreaming
                      ? Text(
                          'Analyzing symptoms against medical database...',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isPatient
                                ? Colors.white70
                                : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary),
                          ),
                        )
                      : MarkdownBody(
                          data: cleanContent,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary),
                            ),
                            h1: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary),
                            ),
                            h2: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary),
                            ),
                            h3: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF81E6D9)
                                        : AppTheme.primaryTeal),
                            ),
                            strong: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF81E6D9)
                                        : AppTheme.primaryTeal),
                            ),
                            listBullet: TextStyle(
                              fontSize: 14.5,
                              color: isPatient
                                  ? Colors.white
                                  : (isDark
                                        ? AppTheme.accentEmerald
                                        : AppTheme.primaryTeal),
                            ),
                            blockSpacing: 10.0,
                          ),
                        ),
                  if (message.isStreaming) ...[
                    AppGap.h8,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentEmerald,
                            ),
                          ),
                        ),
                        AppGap.w6,
                        Text(
                          'Generating factual response...',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isPatient &&
              !message.isStreaming &&
              message.verifiedReferences.isNotEmpty) ...[
            AppGap.h8,
            VerifiedCitationsCard(
              records: message.verifiedReferences,
              isDark: isDark,
              isTablet: isTablet,
              activePrompt: activePrompt,
            ),
          ],
          if (!message.isStreaming && message.content.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isPatient
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  _buildActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    tooltip: isPatient ? 'Copy prompt' : 'Copy clinical answer',
                    isDark: isDark,
                    onTap: () {
                      if (onCopy != null) {
                        onCopy!();
                      } else {
                        Clipboard.setData(ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                AppGap.w8,
                                Text(
                                  isPatient
                                      ? 'Prompt copied'
                                      : 'Medical response copied',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryTeal,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  if (isPatient && onEditPrompt != null) ...[
                    AppGap.w8,
                    _buildActionChip(
                      icon: Icons.edit_note_rounded,
                      label: 'Edit',
                      tooltip: 'Edit & retry prompt',
                      isDark: isDark,
                      onTap: onEditPrompt!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162238) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF243350) : const Color(0xFFCBD5E1),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              AppGap.w4,
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
