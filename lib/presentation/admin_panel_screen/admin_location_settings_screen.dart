import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';

/// Admin screen to configure location-based search radius settings
/// without requiring any code changes.
class AdminLocationSettingsScreen extends StatefulWidget {
  const AdminLocationSettingsScreen({super.key});

  @override
  State<AdminLocationSettingsScreen> createState() =>
      _AdminLocationSettingsScreenState();
}

class _AdminLocationSettingsScreenState
    extends State<AdminLocationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, String> _settings = {};
  final Map<String, TextEditingController> _controllers = {};

  // Setting definitions for UI rendering
  static const List<_SettingGroup> _groups = [
    _SettingGroup(
      title: 'Global Search Defaults',
      icon: Icons.public_rounded,
      color: Color(0xFF1565C0),
      settings: [
        _SettingDef(
          key: 'default_search_radius_km',
          label: 'Default Search Radius',
          description: 'Initial radius shown when customer opens discovery',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'max_search_radius_km',
          label: 'Maximum Search Radius',
          description: 'Maximum radius a customer can manually select',
          unit: 'km',
          min: 10,
          max: 500,
        ),
        _SettingDef(
          key: 'min_providers_threshold',
          label: 'Min Providers Before Expanding',
          description: 'If fewer providers found, auto-expand radius',
          unit: 'providers',
          min: 1,
          max: 20,
        ),
      ],
    ),
    _SettingGroup(
      title: 'Smart Radius Expansion Steps',
      icon: Icons.radar_rounded,
      color: Color(0xFF6A1B9A),
      settings: [
        _SettingDef(
          key: 'smart_expand_step1_km',
          label: 'Step 1 Radius',
          description: 'First search attempt radius',
          unit: 'km',
          min: 1,
          max: 50,
        ),
        _SettingDef(
          key: 'smart_expand_step2_km',
          label: 'Step 2 Radius',
          description: 'Second attempt if Step 1 has too few results',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'smart_expand_step3_km',
          label: 'Step 3 Radius',
          description: 'Third attempt if Step 2 has too few results',
          unit: 'km',
          min: 1,
          max: 200,
        ),
        _SettingDef(
          key: 'smart_expand_step4_km',
          label: 'Step 4 Radius (Final)',
          description: 'Final fallback radius — widest search',
          unit: 'km',
          min: 10,
          max: 500,
        ),
      ],
    ),
    _SettingGroup(
      title: 'Category-Specific Default Radius',
      icon: Icons.category_rounded,
      color: Color(0xFF2E7D32),
      settings: [
        _SettingDef(
          key: 'category_radius_shop',
          label: 'Shop',
          description: 'Default service radius for shop providers',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'category_radius_transport',
          label: 'Transport',
          description: 'Default service radius for transport providers',
          unit: 'km',
          min: 1,
          max: 500,
        ),
        _SettingDef(
          key: 'category_radius_home_maintenance',
          label: 'Home Maintenance',
          description: 'Default service radius for home maintenance',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'category_radius_delivery',
          label: 'Delivery',
          description: 'Default service radius for delivery providers',
          unit: 'km',
          min: 1,
          max: 200,
        ),
        _SettingDef(
          key: 'category_radius_events',
          label: 'Events',
          description: 'Default service radius for event providers',
          unit: 'km',
          min: 1,
          max: 200,
        ),
        _SettingDef(
          key: 'category_radius_rent',
          label: 'Rent',
          description: 'Default service radius for rent providers',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'category_radius_beauty',
          label: 'Beauty',
          description: 'Default service radius for beauty providers',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'category_radius_doctor',
          label: 'Doctor',
          description: 'Default service radius for doctor providers',
          unit: 'km',
          min: 1,
          max: 100,
        ),
        _SettingDef(
          key: 'category_radius_food',
          label: 'Food',
          description: 'Default service radius for food providers',
          unit: 'km',
          min: 1,
          max: 100,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await LocationService.instance.getAdminLocationSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        // Initialize controllers
        for (final group in _groups) {
          for (final def in group.settings) {
            _controllers[def.key] = TextEditingController(
              text: settings[def.key] ?? '',
            );
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      for (final group in _groups) {
        for (final def in group.settings) {
          final ctrl = _controllers[def.key];
          if (ctrl != null && ctrl.text.isNotEmpty) {
            final val = double.tryParse(ctrl.text);
            if (val != null) {
              await LocationService.instance.updateAdminLocationSetting(
                def.key,
                ctrl.text.trim(),
              );
            }
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Location Search Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1C1E),
        elevation: 0,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        'Save All',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These settings control how the GPS-based provider discovery works. Changes take effect immediately — no code deployment required.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Setting groups
                ..._groups.map((group) => _buildGroup(group)),
                const SizedBox(height: 24),
                // Save button at bottom
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAll,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save All Settings',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildGroup(_SettingGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(group.icon, size: 18, color: group.color),
                ),
                const SizedBox(width: 12),
                Text(
                  group.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: group.color,
                  ),
                ),
              ],
            ),
          ),
          // Settings
          ...group.settings.asMap().entries.map((entry) {
            final i = entry.key;
            final def = entry.value;
            final ctrl = _controllers[def.key];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              def.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          decoration: InputDecoration(
                            suffixText: def.unit,
                            suffixStyle: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: group.color,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < group.settings.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────

class _SettingGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<_SettingDef> settings;

  const _SettingGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.settings,
  });
}

class _SettingDef {
  final String key;
  final String label;
  final String description;
  final String unit;
  final double min;
  final double max;

  const _SettingDef({
    required this.key,
    required this.label,
    required this.description,
    required this.unit,
    required this.min,
    required this.max,
  });
}
