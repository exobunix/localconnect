import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../widgets/offline_banner_widget.dart';
import '../../../routes/app_routes.dart';

class HomeBestOffersWidget extends StatefulWidget {
  final bool isOnline;
  const HomeBestOffersWidget({super.key, this.isOnline = true});

  @override
  State<HomeBestOffersWidget> createState() => _HomeBestOffersWidgetState();
}

class _HomeBestOffersWidgetState extends State<HomeBestOffersWidget> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String? _cacheAge;

  static const _cacheKey = 'home_best_offers';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void didUpdateWidget(HomeBestOffersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline && widget.isOnline) {
      _loadOffers();
    }
  }

  Future<void> _loadOffers() async {
    if (!widget.isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(
        _cacheKey,
      );
      if (cached != null && mounted) {
        final list = cached['data'];
        final ts = ConnectivityService.instance.getCachedTimestamp(cached);
        setState(() {
          _offers = list is List
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _cacheAge = ConnectivityService.instance.formatCacheAge(ts);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getActiveOffers(limit: 5);
      if (mounted) {
        setState(() {
          _offers = data;
          _isLoading = false;
          _cacheAge = null;
        });
        await ConnectivityService.instance.cacheData(_cacheKey, data);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _offerColor(int index) {
    final colors = [
      AppTheme.catTransport,
      AppTheme.catGrocery,
      AppTheme.catBeauty,
      AppTheme.primary,
      AppTheme.catEvents,
    ];
    return colors[index % colors.length];
  }

  IconData _offerIcon(String? discountType) {
    switch (discountType) {
      case 'percentage':
        return Icons.percent_rounded;
      case 'flat':
        return Icons.currency_rupee_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'सर्वोत्तम ऑफर',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Best Offers for You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
                if (_cacheAge != null)
                  OfflineChipWidget(cacheAge: _cacheAge)
                else
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.allCategoriesScreen,
                    ),
                    child: Text(
                      'सर्व पहा',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
              height: 112,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_offers.isEmpty)
            _buildStaticOffers()
          else
            SizedBox(
              height: 112,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _offers.length,
                itemBuilder: (_, i) {
                  final offer = _offers[i];
                  final color = _offerColor(i);
                  final discountType =
                      offer['discount_type'] as String? ?? 'percentage';
                  final discountValue = offer['discount_value'] as num? ?? 0;
                  final discountLabel = discountType == 'percentage'
                      ? '${discountValue.toInt()}% OFF'
                      : '₹${discountValue.toInt()} OFF';
                  final promoCode = offer['promo_code'] as String? ?? '';
                  final title = offer['title'] as String? ?? 'Special Offer';
                  final description = offer['description'] as String? ?? '';

                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < _offers.length - 1 ? 12 : 0,
                    ),
                    child: _OfferCard(
                      title: title,
                      subtitle: description,
                      discount: discountLabel,
                      code: promoCode,
                      color: color,
                      icon: _offerIcon(discountType),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStaticOffers() {
    final staticOffers = [
      _OfferCard(
        title: 'First Booking Free',
        subtitle: 'Any home service',
        discount: '100% OFF',
        code: 'FIRST100',
        color: AppTheme.catTransport,
        icon: Icons.home_repair_service_rounded,
      ),
      _OfferCard(
        title: 'Grocery Cashback',
        subtitle: 'Min order ₹500',
        discount: '₹75 OFF',
        code: 'GROCERY75',
        color: AppTheme.catGrocery,
        icon: Icons.shopping_basket_rounded,
      ),
      _OfferCard(
        title: 'Salon at Home',
        subtitle: 'Weekday special',
        discount: '30% OFF',
        code: 'SALON30',
        color: AppTheme.catBeauty,
        icon: Icons.face_retouching_natural_rounded,
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: staticOffers.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < staticOffers.length - 1 ? 12 : 0),
          child: staticOffers[i],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String discount;
  final String code;
  final Color color;
  final IconData icon;

  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.code,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    discount,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF74777F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Code: $code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
