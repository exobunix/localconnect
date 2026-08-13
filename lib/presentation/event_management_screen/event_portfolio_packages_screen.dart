import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../utils/image_upload_helper.dart';

/// Event Management Portfolio & Packages Screen
/// Providers can upload portfolio photos, add social links, and create packages
class EventPortfolioPackagesScreen extends StatefulWidget {
  const EventPortfolioPackagesScreen({super.key});

  @override
  State<EventPortfolioPackagesScreen> createState() =>
      _EventPortfolioPackagesScreenState();
}

class _EventPortfolioPackagesScreenState
    extends State<EventPortfolioPackagesScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFFAD1457);
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _providerId;
  String? _portfolioId;

  // Portfolio
  List<String> _portfolioPhotos = [];
  final List<TextEditingController> _reelLinkCtrls = [];
  final List<TextEditingController> _postLinkCtrls = [];
  final List<TextEditingController> _youtubeLinkCtrls = [];
  final _portfolioDescCtrl = TextEditingController();
  final _eventsCompletedCtrl = TextEditingController();
  final _availableCitiesCtrl = TextEditingController();
  final _travelChargesCtrl = TextEditingController();
  final _startingPriceCtrl = TextEditingController();
  bool _isUploadingPhoto = false;

  // Packages
  List<Map<String, dynamic>> _packages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize 5 controllers for each link type
    for (int i = 0; i < 5; i++) {
      _reelLinkCtrls.add(TextEditingController());
      _postLinkCtrls.add(TextEditingController());
      _youtubeLinkCtrls.add(TextEditingController());
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _portfolioDescCtrl.dispose();
    _eventsCompletedCtrl.dispose();
    _availableCitiesCtrl.dispose();
    _travelChargesCtrl.dispose();
    _startingPriceCtrl.dispose();
    for (final c in _reelLinkCtrls) {
      c.dispose();
    }
    for (final c in _postLinkCtrls) {
      c.dispose();
    }
    for (final c in _youtubeLinkCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final provider = await Supabase.instance.client
            .from('service_providers')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (provider != null) {
          _providerId = provider['id'] as String?;
          await Future.wait([_loadPortfolio(), _loadPackages()]);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPortfolio() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_portfolio')
          .select()
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (data != null && mounted) {
        _portfolioId = data['id'] as String?;
        final photos = data['photo_urls'];
        if (photos is List) _portfolioPhotos = List<String>.from(photos);
        final reels = data['instagram_reel_links'];
        if (reels is List) {
          for (int i = 0; i < reels.length && i < 5; i++) {
            _reelLinkCtrls[i].text = reels[i] as String? ?? '';
          }
        }
        final posts = data['instagram_post_links'];
        if (posts is List) {
          for (int i = 0; i < posts.length && i < 5; i++) {
            _postLinkCtrls[i].text = posts[i] as String? ?? '';
          }
        }
        final yt = data['youtube_links'];
        if (yt is List) {
          for (int i = 0; i < yt.length && i < 5; i++) {
            _youtubeLinkCtrls[i].text = yt[i] as String? ?? '';
          }
        }
        _portfolioDescCtrl.text =
            data['portfolio_description'] as String? ?? '';
        _eventsCompletedCtrl.text = (data['events_completed'] as int? ?? 0)
            .toString();
        final cities = data['available_cities'];
        if (cities is List) _availableCitiesCtrl.text = cities.join(', ');
        _travelChargesCtrl.text = data['travel_charges'] as String? ?? '';
        _startingPriceCtrl.text =
            (data['starting_price'] as num?)?.toStringAsFixed(0) ?? '';
      }
    } catch (_) {}
  }

  Future<void> _loadPackages() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_packages')
          .select()
          .eq('provider_id', _providerId!)
          .order('sort_order');
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        _packages = list.isEmpty ? _defaultPackages() : list;
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _defaultPackages() {
    return [
      {
        'package_name': 'Basic Package',
        'package_type': 'basic',
        'price': 5000.0,
        'duration': '4 hours',
        'description': 'Essential coverage for small events',
        'features': ['100+ photos', 'Basic editing', 'Digital delivery'],
        'deliverables': ['Edited photos', 'Online album'],
        'is_popular': false,
        'is_enabled': true,
      },
      {
        'package_name': 'Standard Package',
        'package_type': 'standard',
        'price': 12000.0,
        'duration': '8 hours',
        'description': 'Perfect for weddings and large events',
        'features': [
          '300+ photos',
          'Professional editing',
          'Same-day preview',
          'Drone shots',
        ],
        'deliverables': ['Edited photos', 'Online album', 'USB drive'],
        'is_popular': true,
        'is_enabled': true,
      },
      {
        'package_name': 'Premium Package',
        'package_type': 'premium',
        'price': 25000.0,
        'duration': '2 days',
        'description': 'Complete wedding coverage with video',
        'features': [
          '500+ photos',
          'Cinematic video',
          'Drone coverage',
          'Same-day highlights',
        ],
        'deliverables': [
          'Edited photos',
          'Highlight video',
          'Full video',
          'USB drive',
          'Printed album',
        ],
        'is_popular': false,
        'is_enabled': true,
      },
    ];
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_portfolioPhotos.length >= 20) {
      _showSnack('Maximum 20 portfolio photos allowed.');
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (images.isEmpty || _providerId == null) return;

      setState(() => _isUploadingPhoto = true);

      for (final image in images) {
        if (_portfolioPhotos.length >= 20) break;

        final result = await ImageUploadHelper.validateAndCompress(image);
        if (!result.isValid) {
          _showSnack('${image.name}: ${result.errorMessage}');
          continue;
        }

        final ext = image.name.split('.').last.toLowerCase();
        final fileName =
            'portfolio_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = '$_providerId/$fileName';

        await Supabase.instance.client.storage
            .from('provider-photos')
            .uploadBinary(
              path,
              result.bytes!,
              fileOptions: FileOptions(
                contentType: result.mimeType!,
                upsert: true,
              ),
            );

        final url = Supabase.instance.client.storage
            .from('provider-photos')
            .getPublicUrl(path);

        setState(() => _portfolioPhotos.add(url));
      }

      _showSnack('Photos uploaded!', isSuccess: true);
    } catch (e) {
      _showSnack('Failed to upload photos.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _savePortfolio() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);
    try {
      final reels = _reelLinkCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final posts = _postLinkCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final yt = _youtubeLinkCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final cities = _availableCitiesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final portfolioData = {
        'provider_id': _providerId,
        'photo_urls': _portfolioPhotos,
        'instagram_reel_links': reels,
        'instagram_post_links': posts,
        'youtube_links': yt,
        'portfolio_description': _portfolioDescCtrl.text.trim(),
        'events_completed': int.tryParse(_eventsCompletedCtrl.text) ?? 0,
        'available_cities': cities,
        'travel_charges': _travelChargesCtrl.text.trim(),
        'starting_price': double.tryParse(_startingPriceCtrl.text) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_portfolioId != null) {
        await Supabase.instance.client
            .from('provider_portfolio')
            .update(portfolioData)
            .eq('id', _portfolioId!);
      } else {
        await Supabase.instance.client
            .from('provider_portfolio')
            .insert(portfolioData);
      }

      _showSnack('Portfolio saved!', isSuccess: true);
    } catch (e) {
      _showSnack('Failed to save portfolio.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePackages() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('provider_packages')
          .delete()
          .eq('provider_id', _providerId!);

      final toInsert = _packages.asMap().entries.map((e) {
        final p = Map<String, dynamic>.from(e.value);
        p['provider_id'] = _providerId;
        p['sort_order'] = e.key;
        p.remove('id');
        p.remove('created_at');
        p.remove('updated_at');
        return p;
      }).toList();

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('provider_packages')
            .insert(toInsert);
      }

      _showSnack('Packages saved!', isSuccess: true);
    } catch (e) {
      _showSnack('Failed to save packages.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Portfolio & Packages',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Packages'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildPortfolioTab(), _buildPackagesTab()],
            ),
    );
  }

  Widget _buildPortfolioTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats
        _buildSection('Portfolio Info', Icons.info_outline_rounded, [
          _buildField(
            'Events Completed',
            _eventsCompletedCtrl,
            isNumber: true,
            hint: '50',
          ),
          _buildField(
            'Starting Price (₹)',
            _startingPriceCtrl,
            isNumber: true,
            hint: '5000',
          ),
          _buildField(
            'Available Cities',
            _availableCitiesCtrl,
            hint: 'Pune, Mumbai, Nashik',
          ),
          _buildField(
            'Travel Charges',
            _travelChargesCtrl,
            hint: 'e.g. ₹5/km outside city',
          ),
          _buildField(
            'Portfolio Description',
            _portfolioDescCtrl,
            maxLines: 3,
            hint: 'Describe your work style and specializations...',
          ),
        ]),
        const SizedBox(height: 16),
        // Photos
        _buildSection(
          'Portfolio Photos (Max 20)',
          Icons.photo_library_rounded,
          [
            if (_portfolioPhotos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _portfolioPhotos.length,
                itemBuilder: (ctx, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _portfolioPhotos[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          semanticLabel: 'Portfolio photo ${i + 1}',
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _portfolioPhotos.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              icon: _isUploadingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded),
              label: Text(
                _isUploadingPhoto
                    ? 'Uploading...'
                    : 'Add Photos (${_portfolioPhotos.length}/20)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Instagram Reels
        _buildSection(
          'Instagram Reel Links (Max 5)',
          Icons.video_collection_rounded,
          List.generate(
            5,
            (i) => _buildField(
              'Reel Link ${i + 1}',
              _reelLinkCtrls[i],
              hint: 'https://www.instagram.com/reel/...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Instagram Posts
        _buildSection(
          'Instagram Post Links (Max 5)',
          Icons.photo_camera_rounded,
          List.generate(
            5,
            (i) => _buildField(
              'Post Link ${i + 1}',
              _postLinkCtrls[i],
              hint: 'https://www.instagram.com/p/...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        // YouTube
        _buildSection(
          'YouTube Video Links (Max 5)',
          Icons.play_circle_outline_rounded,
          List.generate(
            5,
            (i) => _buildField(
              'YouTube Link ${i + 1}',
              _youtubeLinkCtrls[i],
              hint: 'https://www.youtube.com/watch?v=...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePortfolio,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save Portfolio',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPackagesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Service Packages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _packages.add({
                    'package_name': 'Custom Package',
                    'package_type': 'custom',
                    'price': 0.0,
                    'duration': '',
                    'description': '',
                    'features': <String>[],
                    'deliverables': <String>[],
                    'is_popular': false,
                    'is_enabled': true,
                  });
                });
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Add Package',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: _primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._packages.asMap().entries.map((e) {
          return _buildPackageCard(e.key, e.value);
        }),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePackages,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save Packages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPackageCard(int index, Map<String, dynamic> pkg) {
    final nameCtrl = TextEditingController(
      text: pkg['package_name'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (pkg['price'] as num?)?.toStringAsFixed(0) ?? '0',
    );
    final durationCtrl = TextEditingController(
      text: pkg['duration'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: pkg['description'] as String? ?? '',
    );
    final featuresCtrl = TextEditingController(
      text: (pkg['features'] is List)
          ? (pkg['features'] as List).join(', ')
          : '',
    );
    final deliverablesCtrl = TextEditingController(
      text: (pkg['deliverables'] is List)
          ? (pkg['deliverables'] as List).join(', ')
          : '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (pkg['is_popular'] as bool? ?? false)
              ? _primary.withValues(alpha: 0.4)
              : Colors.grey[200]!,
          width: (pkg['is_popular'] as bool? ?? false) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Package name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[400],
                    ),
                  ),
                  onChanged: (v) => _packages[index]['package_name'] = v,
                ),
              ),
              if (pkg['is_popular'] as bool? ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Popular',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: () => setState(() => _packages.removeAt(index)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniField(
                  'Price (₹)',
                  priceCtrl,
                  isNumber: true,
                  onChanged: (v) =>
                      _packages[index]['price'] = double.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField(
                  'Duration',
                  durationCtrl,
                  onChanged: (v) => _packages[index]['duration'] = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniField(
            'Description',
            descCtrl,
            onChanged: (v) => _packages[index]['description'] = v,
          ),
          const SizedBox(height: 8),
          _miniField(
            'Features (comma separated)',
            featuresCtrl,
            onChanged: (v) => _packages[index]['features'] = v
                .split(',')
                .map((e) => e.trim())
                .toList(),
          ),
          const SizedBox(height: 8),
          _miniField(
            'Deliverables (comma separated)',
            deliverablesCtrl,
            onChanged: (v) => _packages[index]['deliverables'] = v
                .split(',')
                .map((e) => e.trim())
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chipToggle(
                'Popular',
                pkg['is_popular'] as bool? ?? false,
                (v) => setState(() => _packages[index]['is_popular'] = v),
                activeColor: _primary,
              ),
              const SizedBox(width: 8),
              _chipToggle(
                'Enabled',
                pkg['is_enabled'] as bool? ?? true,
                (v) => setState(() => _packages[index]['is_enabled'] = v),
                activeColor: Colors.green[700]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: ctrl,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.12) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? activeColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: value ? activeColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

