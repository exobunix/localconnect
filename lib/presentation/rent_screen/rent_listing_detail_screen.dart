import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class RentListingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  final String subcategory;
  final Color color;

  const RentListingDetailScreen({
    super.key,
    required this.listing,
    required this.subcategory,
    required this.color,
  });

  @override
  State<RentListingDetailScreen> createState() =>
      _RentListingDetailScreenState();
}

class _RentListingDetailScreenState extends State<RentListingDetailScreen> {
  bool _isFavourite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Inquiry form
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  // Mock similar listings
  List<Map<String, dynamic>> get _similarListings => [
    {
      'title': 'Similar Room Nearby',
      'price': 7500,
      'priceUnit': '/month',
      'rating': 4.3,
      'distance': 1.8,
      'image':
          'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'available': true,
    },
    {
      'title': 'Budget Option',
      'price': 5000,
      'priceUnit': '/month',
      'rating': 4.0,
      'distance': 2.5,
      'image':
          'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
      'available': true,
    },
    {
      'title': 'Premium Choice',
      'price': 12000,
      'priceUnit': '/month',
      'rating': 4.8,
      'distance': 3.1,
      'image':
          'https://images.pexels.com/photos/1643383/pexels-photo-1643383.jpeg',
      'available': true,
    },
  ];

  // Mock reviews
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Rahul V.',
      'rating': 5,
      'comment':
          'Excellent place, very clean and well maintained. Owner is very cooperative.',
      'date': '2 weeks ago',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1e67e82d4-1773543072183.png',
    },
    {
      'name': 'Sneha K.',
      'rating': 4,
      'comment': 'Good location, close to metro. Wi-Fi speed could be better.',
      'date': '1 month ago',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c385d6a8-1776973146619.png',
    },
    {
      'name': 'Amit S.',
      'rating': 5,
      'comment': 'Best PG I have stayed in. Highly recommended!',
      'date': '2 months ago',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19b9e581c-1782821190671.png',
    },
  ];

  List<String> get _images => [
    widget.listing['image'] as String,
    'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
    'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPrice(num price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return price.toString();
  }

  void _showInquirySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InquirySheet(
        listing: widget.listing,
        color: widget.color,
        nameController: _nameController,
        phoneController: _phoneController,
        messageController: _messageController,
        onSubmit: _submitInquiry,
      ),
    );
  }

  Future<void> _submitInquiry() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Inquiry sent! Provider will contact you soon.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showReportSheet() {
    final reasons = [
      'Incorrect information',
      'Spam or fake listing',
      'Inappropriate content',
      'Already rented',
      'Other',
    ];
    String? selected;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Listing',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setS(() => selected = v),
                  title: Text(
                    r,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: widget.color,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Report submitted. Thank you!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Report',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final color = widget.color;
    final isAvailable = listing['available'] as bool;
    final amenities = List<String>.from(listing['amenities'] as List);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Image gallery app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavourite ? Colors.red : Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => setState(() => _isFavourite = !_isFavourite),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: _showReportSheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _images[i],
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: color.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.image_rounded,
                          color: color,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  // Image counter
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_images.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Dots
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(
                        children: [
                          if (listing['isFeatured'] == true)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF9A825),
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Featured',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (listing['isVerified'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 11,
                                  color: isAvailable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAvailable ? 'Available' : 'Not Available',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        listing['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              listing['location'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Icon(Icons.near_me_rounded, size: 13, color: color),
                          const SizedBox(width: 3),
                          Text(
                            '${listing['distance']} km away',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${_formatPrice(listing['price'] as num)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    listing['priceUnit'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              if ((listing['deposit'] as num? ?? 0) > 0)
                                Text(
                                  'Security Deposit: ₹${_formatPrice(listing['deposit'] as num)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${listing['rating']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${listing['reviews']} reviews',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Provider card
                _buildProviderCard(listing, color),

                // Subcategory-specific details
                _buildSubcategoryDetails(listing, color),

                // Amenities
                _buildSection(
                  'Amenities & Features',
                  _buildAmenities(amenities, color),
                ),

                // Location
                _buildSection('Location', _buildLocationCard(listing, color)),

                // Reviews
                _buildSection('Ratings & Reviews', _buildReviews(color)),

                // Similar listings
                _buildSection('Similar Listings', _buildSimilarListings(color)),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isAvailable, color),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> listing, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      listing['provider'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (listing['isVerified'] == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                    ],
                  ],
                ),
                Text(
                  'Property Owner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _providerActionBtn(
                Icons.chat_bubble_rounded,
                color,
                () => Navigator.pushNamed(context, AppRoutes.chatDetailScreen),
              ),
              const SizedBox(width: 8),
              _providerActionBtn(
                Icons.phone_rounded,
                Colors.green.shade600,
                () {},
              ),
              const SizedBox(width: 8),
              _providerActionBtn(
                Icons.message_rounded,
                Colors.green.shade700,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _providerActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildSubcategoryDetails(Map<String, dynamic> listing, Color color) {
    final details = <Map<String, dynamic>>[];
    switch (widget.subcategory) {
      case 'room':
        if (listing['furnished'] != null) {
          details.add({
            'icon': Icons.chair_rounded,
            'label': 'Furnished',
            'value': listing['furnished'],
          });
        }
        if (listing['occupancy'] != null) {
          details.add({
            'icon': Icons.people_rounded,
            'label': 'Occupancy',
            'value': listing['occupancy'],
          });
        }
        if (listing['bathroom'] != null) {
          details.add({
            'icon': Icons.bathroom_rounded,
            'label': 'Bathroom',
            'value': listing['bathroom'],
          });
        }
        if (listing['gender'] != null) {
          details.add({
            'icon': Icons.wc_rounded,
            'label': 'For',
            'value': listing['gender'],
          });
        }
        break;
      case 'pg':
        if (listing['type'] != null) {
          details.add({
            'icon': Icons.apartment_rounded,
            'label': 'Type',
            'value': listing['type'],
          });
        }
        if (listing['sharing'] != null) {
          details.add({
            'icon': Icons.people_rounded,
            'label': 'Sharing',
            'value': listing['sharing'],
          });
        }
        if (listing['food'] != null) {
          details.add({
            'icon': Icons.restaurant_rounded,
            'label': 'Food',
            'value': listing['food'],
          });
        }
        if (listing['gender'] != null) {
          details.add({
            'icon': Icons.wc_rounded,
            'label': 'For',
            'value': listing['gender'],
          });
        }
        break;
      case 'hostel':
        if (listing['type'] != null) {
          details.add({
            'icon': Icons.hotel_rounded,
            'label': 'Type',
            'value': listing['type'],
          });
        }
        if (listing['roomType'] != null) {
          details.add({
            'icon': Icons.bed_rounded,
            'label': 'Room Type',
            'value': listing['roomType'],
          });
        }
        if (listing['food'] != null) {
          details.add({
            'icon': Icons.restaurant_rounded,
            'label': 'Food',
            'value': listing['food'],
          });
        }
        break;
      case 'hotel':
        if (listing['roomType'] != null) {
          details.add({
            'icon': Icons.bed_rounded,
            'label': 'Room Type',
            'value': listing['roomType'],
          });
        }
        if (listing['checkIn'] != null) {
          details.add({
            'icon': Icons.login_rounded,
            'label': 'Check-in',
            'value': listing['checkIn'],
          });
        }
        if (listing['checkOut'] != null) {
          details.add({
            'icon': Icons.logout_rounded,
            'label': 'Check-out',
            'value': listing['checkOut'],
          });
        }
        break;
      case 'villa':
        if (listing['bedrooms'] != null) {
          details.add({
            'icon': Icons.bed_rounded,
            'label': 'Bedrooms',
            'value': '${listing['bedrooms']}',
          });
        }
        if (listing['bathrooms'] != null) {
          details.add({
            'icon': Icons.bathroom_rounded,
            'label': 'Bathrooms',
            'value': '${listing['bathrooms']}',
          });
        }
        if (listing['guests'] != null) {
          details.add({
            'icon': Icons.people_rounded,
            'label': 'Max Guests',
            'value': '${listing['guests']}',
          });
        }
        if (listing['rentalType'] != null) {
          details.add({
            'icon': Icons.calendar_today_rounded,
            'label': 'Rental',
            'value': listing['rentalType'],
          });
        }
        break;
      case 'tools':
        if (listing['brand'] != null) {
          details.add({
            'icon': Icons.business_rounded,
            'label': 'Brand',
            'value': listing['brand'],
          });
        }
        if (listing['condition'] != null) {
          details.add({
            'icon': Icons.star_rounded,
            'label': 'Condition',
            'value': listing['condition'],
          });
        }
        if (listing['category'] != null) {
          details.add({
            'icon': Icons.category_rounded,
            'label': 'Category',
            'value': listing['category'],
          });
        }
        if (listing['rentalPeriod'] != null) {
          details.add({
            'icon': Icons.schedule_rounded,
            'label': 'Period',
            'value': listing['rentalPeriod'],
          });
        }
        break;
    }
    if (details.isEmpty) return const SizedBox.shrink();
    return _buildSection(
      '${widget.subcategory[0].toUpperCase()}${widget.subcategory.substring(1)} Details',
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: details
            .map(
              (d) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(d['icon'] as IconData, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            d['value'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAmenities(List<String> amenities, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities
          .map(
            (a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_amenityIcon(a), size: 13, color: color),
                  const SizedBox(width: 5),
                  Text(
                    a,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _amenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wi-fi':
        return Icons.wifi_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'cctv':
        return Icons.videocam_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'delivery':
        return Icons.delivery_dining_rounded;
      case 'garden':
        return Icons.park_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Widget _buildLocationCard(Map<String, dynamic> listing, Color color) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl:
                  'https://maps.googleapis.com/maps/api/staticmap?center=${listing['location']}&zoom=14&size=400x200&maptype=roadmap',
              fit: BoxFit.cover,
              width: double.infinity,
              errorWidget: (_, __, ___) => Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 40,
                      color: color.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing['location'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.mapDiscoveryScreen),
              icon: const Icon(Icons.directions_rounded, size: 14),
              label: Text(
                'Directions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(Color color) {
    return Column(
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    '${widget.listing['rating']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: i < (widget.listing['rating'] as num).round()
                            ? Colors.amber.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.listing['reviews']} reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final pct = star == 5
                        ? 0.6
                        : star == 4
                        ? 0.25
                        : star == 3
                        ? 0.1
                        : 0.03;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(r['avatar'] as String),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded, size: 16, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        r['rating'] as int,
                        (_) => Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r['date'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r['comment'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.rentRatingsScreen),
          child: Text(
            'View all reviews',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarListings(Color color) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _similarListings.length,
        itemBuilder: (_, i) {
          final s = _similarListings[i];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: s['image'] as String,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 90,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '₹${s['price']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          Text(
                            s['priceUnit'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.amber.shade600,
                          ),
                          Text(
                            '${s['rating']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isAvailable, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isAvailable ? _showInquirySheet : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                'Inquiry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isAvailable ? () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookingCheckoutScreen,
                  arguments: {
                    'providerId': widget.listing['provider_id'] as String?,
                    'providerName': widget.listing['provider'] as String? ?? 'Provider',
                    'providerImage': widget.listing['provider_avatar'] as String? ?? '',
                    'providerRating': widget.listing['rating'] as double? ?? 4.8,
                    'service': widget.listing['title'] as String? ?? 'Rent Booking',
                    'category': 'rent',
                    'scheduledDate': 'Now',
                    'scheduledTime': 'Flexible',
                    'amount': widget.listing['price'] != null ? '₹${widget.listing['price']}' : '₹2000',
                  },
                );
              } : null,
              icon: const Icon(Icons.shopping_bag_rounded, size: 16),
              label: Text(
                'Book Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inquiry Sheet ──────────────────────────────────────────────────────────
class _InquirySheet extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Color color;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final VoidCallback onSubmit;

  const _InquirySheet({
    required this.listing,
    required this.color,
    required this.nameController,
    required this.phoneController,
    required this.messageController,
    required this.onSubmit,
  });

  @override
  State<_InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends State<_InquirySheet> {
  String _contactMethod = 'chat';
  DateTime? _moveInDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Send Inquiry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.listing['image'] as String,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: widget.color.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.listing['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹${widget.listing['price']}${widget.listing['priceUnit']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: widget.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'Your Name',
                    widget.nameController,
                    Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    'Phone Number',
                    widget.phoneController,
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    'Message (optional)',
                    widget.messageController,
                    Icons.message_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preferred Contact Method',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _contactChip('chat', Icons.chat_bubble_rounded, 'Chat'),
                      const SizedBox(width: 8),
                      _contactChip('call', Icons.phone_rounded, 'Call'),
                      const SizedBox(width: 8),
                      _contactChip(
                        'whatsapp',
                        Icons.message_rounded,
                        'WhatsApp',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send Inquiry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: widget.color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _contactChip(String value, IconData icon, String label) {
    final sel = _contactMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _contactMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? widget.color : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? widget.color : AppTheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: sel ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
