import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_export.dart';

class RentRatingsScreen extends StatefulWidget {
  const RentRatingsScreen({super.key});

  @override
  State<RentRatingsScreen> createState() => _RentRatingsScreenState();
}

class _RentRatingsScreenState extends State<RentRatingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Rating state
  double _overallRating = 0;
  final Map<String, double> _categoryRatings = {
    'Cleanliness': 0,
    'Accuracy': 0,
    'Communication': 0,
    'Location': 0,
    'Value': 0,
  };
  final _reviewController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _submitted = false;

  // Quick tags
  final List<String> _positiveTags = [
    'Clean & Tidy',
    'Great Location',
    'Responsive Owner',
    'Good Value',
    'As Described',
    'Safe Neighbourhood',
    'Good Amenities',
    'Spacious',
  ];
  final Set<String> _selectedTags = {};

  // Existing reviews mock data
  final List<Map<String, dynamic>> _existingReviews = [
    {
      'name': 'Anita M.',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ae4dcd08-1774432739808.png',
      'rating': 5.0,
      'date': '2 weeks ago',
      'review':
          'Absolutely loved the place! The room was exactly as described, very clean and well-maintained. The owner was super responsive and helpful throughout the stay.',
      'subcategory': 'Room',
      'tags': ['Clean & Tidy', 'Responsive Owner', 'As Described'],
      'helpful': 12,
    },
    {
      'name': 'Ravi J.',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_194483566-1768470402496.png',
      'rating': 4.0,
      'date': '1 month ago',
      'review':
          'Good PG accommodation with all basic amenities. Food quality could be better but overall a comfortable stay. Location is very convenient.',
      'subcategory': 'PG',
      'tags': ['Great Location', 'Good Value'],
      'helpful': 8,
    },
    {
      'name': 'Priya S.',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1bdd9aaaa-1768657682490.png',
      'rating': 4.5,
      'date': '3 weeks ago',
      'review':
          'The villa was stunning! Perfect for our family vacation. Swimming pool was clean and the garden was beautiful. Will definitely book again.',
      'subcategory': 'Villa',
      'tags': ['Clean & Tidy', 'Spacious', 'Good Amenities'],
      'helpful': 24,
    },
    {
      'name': 'Deepak N.',
      'avatar': 'https://images.unsplash.com/photo-1621841325840-e63a2d907c51',
      'rating': 3.5,
      'date': '2 months ago',
      'review':
          'The tools were in decent condition. Delivery was on time. However, the drill bit was slightly worn. Would recommend checking equipment before use.',
      'subcategory': 'Tools',
      'tags': ['Good Value'],
      'helpful': 5,
    },
    {
      'name': 'Kavita P.',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_11360a534-1772248210132.png',
      'rating': 5.0,
      'date': '1 week ago',
      'review':
          'Best hostel experience! Very clean dorms, great common areas, and the staff was incredibly helpful. Made many friends here. Highly recommended!',
      'subcategory': 'Hostel',
      'tags': ['Clean & Tidy', 'Responsive Owner', 'Good Amenities'],
      'helpful': 18,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final listingTitle = args['listingTitle'] as String? ?? 'Your Rental';
    final subcategory = args['subcategory'] as String? ?? 'Room';
    final bookingType = args['bookingType'] as String? ?? 'book';
    final subcategoryColor = _getSubcategoryColor(subcategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: subcategoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ratings & Reviews',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Write a Review'),
            Tab(text: 'All Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWriteReviewTab(
            listingTitle: listingTitle,
            subcategory: subcategory,
            subcategoryColor: subcategoryColor,
          ),
          _buildAllReviewsTab(subcategoryColor: subcategoryColor),
        ],
      ),
    );
  }

  // ── Write Review Tab ──────────────────────────────────────────────────────
  Widget _buildWriteReviewTab({
    required String listingTitle,
    required String subcategory,
    required Color subcategoryColor,
  }) {
    if (_submitted) {
      return _buildSubmittedState(subcategoryColor);
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Listing info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: subcategoryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: subcategoryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: subcategoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSubcategoryIcon(subcategory),
                    color: subcategoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listingTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subcategory,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: subcategoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overall rating
          _buildSectionLabel('Overall Rating'),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _overallRating = i + 1.0);
                        HapticFeedback.selectionClick();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < _overallRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < _overallRating
                              ? const Color(0xFFF9A825)
                              : const Color(0xFFCFD8DC),
                          size: 44,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _overallRating == 0
                      ? 'Tap to rate'
                      : _getRatingLabel(_overallRating),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _overallRating == 0
                        ? const Color(0xFF78909C)
                        : const Color(0xFFF9A825),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category ratings
          _buildSectionLabel('Rate by Category'),
          const SizedBox(height: 12),
          ..._categoryRatings.entries.map((e) {
            return _buildCategoryRatingRow(e.key, e.value, subcategoryColor);
          }),
          const SizedBox(height: 24),

          // Quick tags
          _buildSectionLabel('What did you like?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _positiveTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? subcategoryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? subcategoryColor
                          : const Color(0xFFE0E0E0),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: subcategoryColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF44474E),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Written review
          _buildSectionLabel('Write Your Review'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 500,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF1A1C1E),
              ),
              decoration: InputDecoration(
                hintText:
                    'Share your experience — what did you love? What could be improved?',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF90A4AE),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Anonymous toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                const Icon(
                  Icons.visibility_off_rounded,
                  size: 20,
                  color: Color(0xFF78909C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Anonymously',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        'Your name will be hidden from the review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  activeThumbColor: subcategoryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _overallRating == 0 ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: subcategoryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCFD8DC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryRatingRow(String category, double rating, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              category,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF44474E),
              ),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () {
                  setState(() => _categoryRatings[category] = i + 1.0);
                  HapticFeedback.selectionClick();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < rating
                        ? const Color(0xFFF9A825)
                        : const Color(0xFFCFD8DC),
                    size: 26,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            rating == 0 ? '' : rating.toStringAsFixed(0),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9A825),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedState(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: color, size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'Review Submitted!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Thank you for sharing your experience.\nYour review helps others make better decisions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF78909C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'See All Reviews',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── All Reviews Tab ───────────────────────────────────────────────────────
  Widget _buildAllReviewsTab({required Color subcategoryColor}) {
    // Rating summary
    final avgRating =
        _existingReviews.fold<double>(
          0,
          (sum, r) => sum + (r['rating'] as double),
        ) /
        _existingReviews.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating summary card
          _buildRatingSummaryCard(avgRating, subcategoryColor),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.rate_review_rounded,
                size: 18,
                color: Color(0xFF1A1C1E),
              ),
              const SizedBox(width: 8),
              Text(
                '${_existingReviews.length} Reviews',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._existingReviews.map((r) => _buildReviewCard(r, subcategoryColor)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard(double avgRating, Color color) {
    final ratingCounts = [0, 0, 0, 0, 0];
    for (final r in _existingReviews) {
      final star = (r['rating'] as double).round();
      if (star >= 1 && star <= 5) ratingCounts[star - 1]++;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                  height: 1,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < avgRating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF9A825),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_existingReviews.length} reviews',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF78909C),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = ratingCounts[star - 1];
                final pct = count / _existingReviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF78909C),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Color(0xFFF9A825),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFF5F6FA),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r, Color color) {
    final subcategoryColor = _getSubcategoryColor(r['subcategory'] as String);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  r['avatar'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: color.withValues(alpha: 0.15),
                    child: Icon(Icons.person_rounded, color: color, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      r['date'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFF9A825),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        (r['rating'] as double).toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: subcategoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r['subcategory'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: subcategoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r['review'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF44474E),
              height: 1.5,
            ),
          ),
          if ((r['tags'] as List).isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (r['tags'] as List).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF546E7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      size: 14,
                      color: Color(0xFF78909C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${r['helpful']})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Report',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF90A4AE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }

  Color _getSubcategoryColor(String subcategory) {
    const colors = {
      'Room': Color(0xFF26A69A),
      'PG': Color(0xFF7B1FA2),
      'Hostel': Color(0xFF1565C0),
      'Villa': Color(0xFFE65100),
      'Tools': Color(0xFF2E7D32),
    };
    return colors[subcategory] ?? const Color(0xFF26A69A);
  }

  IconData _getSubcategoryIcon(String subcategory) {
    const icons = {
      'Room': Icons.bedroom_parent_rounded,
      'PG': Icons.apartment_rounded,
      'Hostel': Icons.hotel_rounded,
      'Villa': Icons.villa_rounded,
      'Tools': Icons.build_rounded,
    };
    return icons[subcategory] ?? Icons.home_rounded;
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5) return 'Excellent!';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
      HapticFeedback.mediumImpact();
    }
  }
}
