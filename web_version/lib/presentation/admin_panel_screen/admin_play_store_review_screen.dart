import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AdminPlayStoreReviewScreen extends StatefulWidget {
  const AdminPlayStoreReviewScreen({super.key});

  @override
  State<AdminPlayStoreReviewScreen> createState() =>
      _AdminPlayStoreReviewScreenState();
}

class _AdminPlayStoreReviewScreenState
    extends State<AdminPlayStoreReviewScreen> {
  // Checkpoint states: null = not checked, true = pass, false = fail
  final Map<String, bool?> _checkpoints = {
    'app_name': null,
    'short_description': null,
    'full_description': null,
    'screenshots_phone': null,
    'screenshots_tablet': null,
    'icon_512': null,
    'feature_graphic': null,
    'version_code': null,
    'version_name': null,
    'privacy_policy': null,
    'terms_of_service': null,
    'min_sdk': null,
    'target_sdk': null,
    'content_rating': null,
    'billing_compliance': null,
    'in_app_purchases': null,
    'data_safety': null,
    'permissions_declared': null,
  };

  static const Color _primary = Color(0xFF0D1B4B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _red = Color(0xFFC62828);
  static const Color _amber = Color(0xFFE65100);

  int get _passCount => _checkpoints.values.where((v) => v == true).length;
  int get _failCount => _checkpoints.values.where((v) => v == false).length;
  int get _totalChecked => _checkpoints.values.where((v) => v != null).length;
  int get _total => _checkpoints.length;

  double get _progress => _total == 0 ? 0 : _passCount / _total;

  Color get _statusColor {
    if (_passCount == _total) return _green;
    if (_failCount > 0) return _red;
    if (_totalChecked > 0) return _amber;
    return const Color(0xFF607D8B);
  }

  String get _statusLabel {
    if (_passCount == _total) return 'READY FOR SUBMISSION';
    if (_failCount > 0) {
      return '$_failCount ISSUE${_failCount > 1 ? 'S' : ''} FOUND';
    }
    if (_totalChecked > 0) return 'IN PROGRESS';
    return 'NOT STARTED';
  }

  void _toggleCheckpoint(String key, bool value) {
    setState(() {
      _checkpoints[key] = _checkpoints[key] == value ? null : value;
    });
  }

  void _resetAll() {
    setState(() {
      for (final key in _checkpoints.keys) {
        _checkpoints[key] = null;
      }
    });
  }

  void _markAllPass() {
    setState(() {
      for (final key in _checkpoints.keys) {
        _checkpoints[key] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Play Store Review',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'reset') _resetAll();
              if (v == 'pass_all') _markAllPass();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pass_all',
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mark All Pass',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF607D8B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reset All',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.info_outline_rounded,
              title: 'App Identity',
              color: const Color(0xFF1565C0),
              items: [
                _CheckItem(
                  key: 'app_name',
                  title: 'App Name',
                  description:
                      'Max 30 characters. Must be unique and accurately represent the app.',
                  spec: 'LocalConnect — max 30 chars',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'short_description',
                  title: 'Short Description',
                  description:
                      'Up to 80 characters. Appears in search results below the app name.',
                  spec: 'Max 80 characters',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'full_description',
                  title: 'Full Description',
                  description:
                      'Up to 4000 characters. Describe features, benefits, and use cases clearly.',
                  spec: 'Max 4000 characters',
                  requirement: 'Required',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.photo_library_rounded,
              title: 'Screenshots & Graphics',
              color: const Color(0xFF7B1FA2),
              items: [
                _CheckItem(
                  key: 'screenshots_phone',
                  title: 'Phone Screenshots',
                  description:
                      'Minimum 2, maximum 8 screenshots. JPEG or 24-bit PNG, no alpha.',
                  spec: '320–3840 px, 16:9 or 9:16 ratio',
                  requirement: 'Min 2 required',
                ),
                _CheckItem(
                  key: 'screenshots_tablet',
                  title: 'Tablet Screenshots (7" & 10")',
                  description:
                      'Recommended for better store visibility. Same format as phone screenshots.',
                  spec: '1080×1920 px recommended',
                  requirement: 'Recommended',
                ),
                _CheckItem(
                  key: 'icon_512',
                  title: 'App Icon',
                  description:
                      'High-resolution icon. PNG format, no alpha channel, no rounded corners.',
                  spec: '512×512 px, PNG, ≤1 MB',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'feature_graphic',
                  title: 'Feature Graphic',
                  description:
                      'Displayed at the top of the store listing. JPEG or 24-bit PNG.',
                  spec: '1024×500 px, JPEG or PNG',
                  requirement: 'Required',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.code_rounded,
              title: 'Version & SDK',
              color: const Color(0xFF00695C),
              items: [
                _CheckItem(
                  key: 'version_code',
                  title: 'Version Code',
                  description:
                      'Integer that must be incremented with each release. Used internally by Play Store.',
                  spec: 'Integer, must increase each release',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'version_name',
                  title: 'Version Name',
                  description:
                      'User-visible version string shown on the store listing (e.g., 1.0.2).',
                  spec: 'Semantic versioning (e.g., 1.0.2)',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'min_sdk',
                  title: 'Minimum SDK Version',
                  description:
                      'Google Play requires minimum SDK 21 (Android 5.0) or higher for new apps.',
                  spec: 'minSdkVersion ≥ 21',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'target_sdk',
                  title: 'Target SDK Version',
                  description:
                      'Must target Android 14 (API 34) or higher for new apps submitted after Aug 2024.',
                  spec: 'targetSdkVersion ≥ 34',
                  requirement: 'Required',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.gavel_rounded,
              title: 'Legal & Policies',
              color: const Color(0xFFB71C1C),
              items: [
                _CheckItem(
                  key: 'privacy_policy',
                  title: 'Privacy Policy Link',
                  description:
                      'A valid, publicly accessible URL to your privacy policy. Required for all apps.',
                  spec: 'Public HTTPS URL',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'terms_of_service',
                  title: 'Terms of Service',
                  description:
                      'URL to your terms of service. Strongly recommended for marketplace apps.',
                  spec: 'Public HTTPS URL',
                  requirement: 'Recommended',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.shield_rounded,
              title: 'Content & Compliance',
              color: const Color(0xFF4527A0),
              items: [
                _CheckItem(
                  key: 'content_rating',
                  title: 'Content Rating',
                  description:
                      'Complete the IARC content rating questionnaire in Play Console. Required for all apps.',
                  spec: 'IARC questionnaire completed',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'data_safety',
                  title: 'Data Safety Section',
                  description:
                      'Declare what data your app collects, shares, and how it is secured.',
                  spec: 'All data types declared accurately',
                  requirement: 'Required',
                ),
                _CheckItem(
                  key: 'permissions_declared',
                  title: 'Permissions Declared',
                  description:
                      'All AndroidManifest permissions must be justified. Remove unused permissions.',
                  spec: 'Only necessary permissions included',
                  requirement: 'Required',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.payment_rounded,
              title: 'Billing & Monetization',
              color: const Color(0xFF1B5E20),
              items: [
                _CheckItem(
                  key: 'billing_compliance',
                  title: 'Billing Compliance',
                  description:
                      'If the app sells digital goods or subscriptions, Google Play Billing must be used. Physical goods/services are exempt.',
                  spec: 'Google Play Billing API integrated (if applicable)',
                  requirement: 'Conditional',
                ),
                _CheckItem(
                  key: 'in_app_purchases',
                  title: 'In-App Purchases Declared',
                  description:
                      'All in-app products and subscriptions must be declared in Play Console.',
                  spec: 'All SKUs listed in Play Console',
                  requirement: 'Conditional',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLegend(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, const Color(0xFF1A3A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Play Store Readiness',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Google Play submission checklist',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ScorePill(
                label: 'Pass',
                count: _passCount,
                color: const Color(0xFF66BB6A),
              ),
              const SizedBox(width: 10),
              _ScorePill(
                label: 'Fail',
                count: _failCount,
                color: const Color(0xFFEF5350),
              ),
              const SizedBox(width: 10),
              _ScorePill(
                label: 'Pending',
                count: _total - _totalChecked,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _passCount == _total
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFF42A5F5),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_passCount of $_total requirements verified',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<_CheckItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _buildCheckpointCard(item, color)),
      ],
    );
  }

  Widget _buildCheckpointCard(_CheckItem item, Color sectionColor) {
    final status = _checkpoints[item.key];
    final isPass = status == true;
    final isFail = status == false;

    Color borderColor = const Color(0xFFE0E0E0);
    Color bgColor = Colors.white;
    if (isPass) {
      borderColor = const Color(0xFF66BB6A);
      bgColor = const Color(0xFFF1F8E9);
    } else if (isFail) {
      borderColor = const Color(0xFFEF5350);
      bgColor = const Color(0xFFFFEBEE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.requirement == 'Required'
                                  ? const Color(0xFFFFEBEE)
                                  : item.requirement == 'Recommended'
                                  ? const Color(0xFFFFF8E1)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.requirement,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                                color: item.requirement == 'Required'
                                    ? const Color(0xFFC62828)
                                    : item.requirement == 'Recommended'
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: const Color(0xFF5C6370),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: sectionColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.spec,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: sectionColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Pass',
                    icon: Icons.check_circle_rounded,
                    isActive: isPass,
                    activeColor: _green,
                    onTap: () => _toggleCheckpoint(item.key, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Fail',
                    icon: Icons.cancel_rounded,
                    isActive: isFail,
                    activeColor: _red,
                    onTap: () => _toggleCheckpoint(item.key, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requirement Types',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 10),
          _LegendRow(
            color: const Color(0xFFC62828),
            label: 'Required',
            desc: 'Must be completed before submission',
          ),
          const SizedBox(height: 6),
          _LegendRow(
            color: const Color(0xFFE65100),
            label: 'Recommended',
            desc: 'Improves visibility and user trust',
          ),
          const SizedBox(height: 6),
          _LegendRow(
            color: const Color(0xFF2E7D32),
            label: 'Conditional',
            desc: 'Required only if feature is used',
          ),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String key;
  final String title;
  final String description;
  final String spec;
  final String requirement;

  const _CheckItem({
    required this.key,
    required this.title,
    required this.description,
    required this.spec,
    required this.requirement,
  });
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ScorePill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : const Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: const Color(0xFF5C6370),
            ),
          ),
        ),
      ],
    );
  }
}
