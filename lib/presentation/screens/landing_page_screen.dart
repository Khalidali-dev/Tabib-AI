import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tabib.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _architectureKey = GlobalKey();
  final GlobalKey _safetyKey = GlobalKey();
  final GlobalKey _docsKey = GlobalKey();

  int _selectedSimTab = 0;

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 840;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildNavigationBar(isMobile, isDark),
      ),
      endDrawer: isMobile ? _buildMobileDrawer(context) : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(isMobile),
            _buildFeatureBadgesBar(isMobile),
            _buildInteractiveMockupSection(isMobile),
            _buildArchitecturalPillars(isMobile),
            _buildLiveWorkflowShowcase(isMobile),
            _buildSafetySpecsMatrix(isMobile),
            _buildCtaBanner(isMobile),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(bool isMobile, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      AppGap.w12,
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Tabib',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              AppGap.w4,
                              Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D9488),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'CLINICAL INTELLIGENCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isMobile) ...[
                  _buildNavLink('Features', () => _scrollToKey(_featuresKey)),
                  AppGap.w24,
                  _buildNavLink('Architecture', () => _scrollToKey(_architectureKey)),
                  AppGap.w24,
                  _buildNavLink('Safety Core', () => _scrollToKey(_safetyKey)),
                  AppGap.w24,
                  _buildNavLink('Docs', () => _scrollToKey(_docsKey)),
                  AppGap.w32,
                  _buildHeaderActionButton(),
                ] else ...[
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI/releases');
      },
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text(
        'Download APK',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  AppGap.w10,
                  const Text(
                    'Tabib AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('Features', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToKey(_featuresKey);
                },
              ),
              ListTile(
                title: const Text('Architecture', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToKey(_architectureKey);
                },
              ),
              ListTile(
                title: const Text('Safety Core', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToKey(_safetyKey);
                },
              ),
              ListTile(
                title: const Text('Documentation', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToKey(_docsKey);
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI/releases');
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Android APK', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0FDFA),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E), size: 16),
                    AppGap.w8,
                    Text(
                      'CLINICAL DECISION SUPPORT • 100% AIR-GAPPED PRIVACY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
              AppGap.h24,
              Text(
                'On-Device Clinical Intelligence.\nZero Cloud. Total Privacy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 56,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: const Color(0xFF0F172A),
                ),
              ),
              AppGap.h20,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  'Tabib AI is an offline clinical decision support and triage assistant engineered for physicians, clinical officers, and remote healthcare facilities. Powered by local neural inference and deterministic pharmacology safety guardrails.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 19,
                    height: 1.6,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              AppGap.h32,
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI/releases');
                    },
                    icon: const Icon(Icons.android_rounded, size: 22),
                    label: const Text(
                      'Download APK (Release v1.0)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI');
                    },
                    icon: const Icon(Icons.code_rounded, size: 20),
                    label: const Text(
                      'View Source on GitHub',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadgesBar(bool isMobile) {
    final badges = [
      {'icon': Icons.cloud_off_rounded, 'title': '100% Offline', 'subtitle': 'No API keys required'},
      {'icon': Icons.lock_outline_rounded, 'title': 'Total HIPAA Privacy', 'subtitle': 'Data never leaves phone'},
      {'icon': Icons.health_and_safety_outlined, 'title': 'Pharmacology Guard', 'subtitle': '4,000 mg ceiling lock'},
      {'icon': Icons.child_care_rounded, 'title': 'Pediatric Safety Engine', 'subtitle': 'mg/kg deterministic math'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 16,
            children: badges.map((b) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(b['icon'] as IconData, color: const Color(0xFF0D9488), size: 20),
                  ),
                  AppGap.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        b['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveMockupSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 40 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                      AppGap.w6,
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      AppGap.w6,
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      AppGap.w16,
                      const Icon(Icons.shield_rounded, size: 15, color: Color(0xFF0D9488)),
                      AppGap.w6,
                      const Text(
                        'Tabib Air-Gapped Clinical Console • On-Device Llama Engine (Q4_K_M)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF0D9488),
                              child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                            ),
                            AppGap.w12,
                            Expanded(
                              child: Text(
                                'Patient: 28-year-old female presenting with 2-day bilateral throbbing headache, mild photophobia, no fever, no focal neurological deficits.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppGap.h20,
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medical_services_rounded, color: Color(0xFF0D9488), size: 20),
                                AppGap.w8,
                                Text(
                                  '### 🩺 Clinical Assessment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                            AppGap.h10,
                            const Text(
                              'Symptom constellation is clinically suggestive of episodic tension-type headache or mild migraine without aura. No intracranial red flags or meningeal signs noted.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            AppGap.h16,
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCCFBF1)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '### 💊 Verified Medication & Dosage',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  AppGap.h6,
                                  Text(
                                    '• Generic Name: Paracetamol (Panadol, Calpol)\n• Therapeutic Class: Analgesic & Antipyretic\n• Verified Adult Dose: 500 mg to 1000 mg every 4-6 hours PO as needed\n• Ceiling Limit: 4000 mg (4 grams / 8 x 500mg tablets) per 24 hours\n• Absolute Contraindications: Severe active hepatic failure, acute hepatitis',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppGap.h16,
                            const Text(
                              '### 🚨 Emergency Red Flags\n• Sudden severe "thunderclap" headache reaching peak intensity in seconds.\n• Any new focal neurologic deficits (facial droop, arm weakness, speech slurring).\n• Onset with high fever, neck stiffness, confusion, or rash (Dial emergency services immediately).',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchitecturalPillars(bool isMobile) {
    final pillars = [
      {
        'icon': Icons.memory_rounded,
        'title': 'Local Neural Inference',
        'desc':
            'Executes quantized weights (Q4_K_M) on-device via native C++ llama bindings with zero reliance on cloud APIs, cellular signal, or third-party servers.',
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Deterministic Pharmacology',
        'desc':
            'Offline SQLite database coupled with strict algorithmic post-processors eliminates LLM dosage hallucinations and enforces hard adult ceiling limits.',
      },
      {
        'icon': Icons.emergency_rounded,
        'title': 'Emergency Red-Flag Interceptors',
        'desc':
            'Sub-millisecond triage interceptor instantly intercepts surgical emergencies (appendicitis, peritonitis, stroke, massive GI hemorrhage) before model inference.',
      },
      {
        'icon': Icons.calculate_rounded,
        'title': 'Pediatric Weight Math Engine',
        'desc':
            'Computes exact mg/kg dosing and commercial suspension volume (mL) calculations deterministically, preventing dangerous pediatric toxicity.',
      },
      {
        'icon': Icons.translate_rounded,
        'title': 'Multi-Regional Clinical Context',
        'desc':
            'Pre-configured clinical emergency numbers and medicine registries supporting Pakistan (1122), United Kingdom (999), United States (911), and Saudi Arabia (997).',
      },
      {
        'icon': Icons.history_edu_rounded,
        'title': 'Local Consultation Archives',
        'desc':
            'All clinical interactions and patient triage histories are stored strictly in local device memory, guaranteeing total HIPAA, GDPR, and clinical confidentiality.',
      },
    ];

    return Container(
      key: _architectureKey,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'SYSTEM ARCHITECTURE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Color(0xFF0D9488),
                ),
              ),
              AppGap.h12,
              Text(
                'Clinical Safety by Mathematical Architecture',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 38,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              AppGap.h16,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: const Text(
                  'Generative models must not act as unconstrained clinical authorities. Tabib AI sandwiches local neural reasoning between deterministic gatekeepers and pharmacology guardrails.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.55),
                ),
              ),
              AppGap.h48,
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width < 1000 ? 2 : 3),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isMobile ? 1.9 : 1.35,
                ),
                itemCount: pillars.length,
                itemBuilder: (context, index) {
                  final p = pillars[index];
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p['icon'] as IconData, color: const Color(0xFF0D9488), size: 24),
                        ),
                        AppGap.h16,
                        Text(
                          p['title'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        AppGap.h8,
                        Expanded(
                          child: Text(
                            p['desc'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveWorkflowShowcase(bool isMobile) {
    final simulations = [
      {
        'title': 'Pediatric Dosing Engine',
        'query': 'Child 12 kg with 38.5 C fever',
        'output':
            '⚖️ Pediatric Dosing Calculation (Deterministic Math):\n• Patient Weight: 12.0 kg\n• Paracetamol Target Dose: 15 mg/kg (Single dose: 180 mg)\n• Suspension (120 mg / 5 mL): 7.5 mL per dose every 4-6 hours PRN\n• Max 24h Ceiling Limit: 720 mg (30.0 mL max/day)\n\n⚠️ Caution: Never exceed 60 mg/kg/day in pediatric patients.',
      },
      {
        'title': 'Acute Triage Guard vs Masking',
        'query': 'Severe acute lower right quadrant pain with nausea and rebound tenderness',
        'output':
            '🚨 CRITICAL MEDICAL TRIAGE ALERT: SUSPECTED ACUTE ABDOMEN\n\n• Symptoms are clinically pathognomonic for Acute Appendicitis or acute peritoneal irritation.\n• CONTRAINDICATION: Oral analgesics and NSAIDs are withheld until surgical evaluation to prevent masking peritonitis.\n• ACTION REQUIRED: Proceed immediately to the nearest Emergency Department. Contact 1122 / 911 now.',
      },
      {
        'title': 'Ceiling Limit Enforcement',
        'query': 'Severe dental toothache taking 6 grams paracetamol',
        'output':
            '⚠️ TOXICITY WARNING: CEILING DOSE EXCEEDED\n\n• Reported dose (6,000 mg) exceeds the safe therapeutic ceiling.\n• MAXIMUM SAFE CEILING: 4,000 mg (4 grams / 8 x 500mg tablets) in 24 hours.\n• Hepatic Toxicity Risk: Excess ingestion causes acute glutathione depletion and acetaminophen-induced liver necrosis.\n• Recommendation: Discontinue further intake immediately and seek urgent medical evaluation.',
      },
    ];

    return Container(
      key: _featuresKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'LIVE WORKFLOW SIMULATIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Color(0xFF0D9488),
                ),
              ),
              AppGap.h12,
              Text(
                'Deterministic Safety in Action',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 38,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              AppGap.h32,
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(simulations.length, (index) {
                  final isSelected = _selectedSimTab == index;
                  return ChoiceChip(
                    label: Text(simulations[index]['title']!),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedSimTab = index);
                    },
                    selectedColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }),
              ),
              AppGap.h28,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.input_rounded, size: 16, color: Color(0xFF64748B)),
                        AppGap.w8,
                        const Text(
                          'CLINICAL PROMPT / QUERY:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Deterministic Pipeline',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    AppGap.h8,
                    Text(
                      '"${simulations[_selectedSimTab]['query']}"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.output_rounded, size: 16, color: Color(0xFF0D9488)),
                        AppGap.w8,
                        const Text(
                          'TABIB SAFETY PROTOCOL RESPONSE:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                    AppGap.h12,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        simulations[_selectedSimTab]['output']!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          fontFamily: 'monospace',
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetySpecsMatrix(bool isMobile) {
    return Container(
      key: _safetyKey,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'SPECIFICATIONS & BENCHMARKS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Color(0xFF0D9488),
                ),
              ),
              AppGap.h12,
              Text(
                'Deterministic Safety Matrix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 38,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              AppGap.h32,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Table(
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(3.0),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      children: [
                        _buildTableHeaderCell('Clinical Dimension'),
                        _buildTableHeaderCell('Standard LLM Vulnerability'),
                        _buildTableHeaderCell('Tabib Architectural Guard'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('Pharmacology Dosages', isBold: true),
                        _buildTableCell('Unbounded dose hallucinations'),
                        _buildTableCell('4,000 mg Paracetamol ceiling lock & SQLite verified records'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('Pediatric Formulations', isBold: true),
                        _buildTableCell('Approximated adult fraction doses'),
                        _buildTableCell('Exact mg/kg equation with commercial suspension (mg/mL) math'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('Surgical Emergencies', isBold: true),
                        _buildTableCell('Suggests oral pain relievers'),
                        _buildTableCell('Sub-millisecond triage interceptor disallowing analgesic masking'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('Patient Privacy', isBold: true),
                        _buildTableCell('Sends telemetry and query to cloud'),
                        _buildTableCell('100% Air-Gapped local runtime, zero cloud ingress/egress'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCtaBanner(bool isMobile) {
    return Container(
      key: _docsKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 72,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0D9488),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 48),
              AppGap.h20,
              Text(
                'Equip Your Clinical Workflow with Local AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              AppGap.h16,
              const Text(
                'Free, open source, and built for austere healthcare environments without internet access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCCFBF1),
                  height: 1.5,
                ),
              ),
              AppGap.h32,
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI/releases');
                    },
                    icon: const Icon(Icons.android_rounded, size: 22),
                    label: const Text(
                      'Download APK for Android',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI#readme');
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text(
                      'Read Full Documentation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 32 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      AppGap.w10,
                      const Text(
                        'Tabib AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
                    onPressed: () {
                      _launchExternalUrl('https://github.com/mian-khalid/Tabib-AI');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('GitHub Repository'),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 40),
              const Text(
                'CLINICAL DISCLAIMER: Tabib AI is designed solely for clinical decision support, triage assistance, and educational reference. It does not establish a doctor-patient relationship and must never supersede in-person physical clinical examination, emergency services, or clinical judgment of licensed medical personnel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.6,
                  color: Color(0xFF64748B),
                ),
              ),
              AppGap.h20,
              Text(
                '© ${DateTime.now().year} Tabib AI. Released under Apache-2.0 License.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
