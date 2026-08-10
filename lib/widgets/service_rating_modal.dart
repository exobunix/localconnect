import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';

/// Shows the service rating modal as a bottom sheet.
/// Returns true if the user submitted a rating, false/null if dismissed.
Future<bool?> showServiceRatingModal(
  BuildContext context, {
  required String bookingId,
  String? providerName,
  String? serviceName,
  bool isOrder = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServiceRatingModal(
      bookingId: bookingId,
      providerName: providerName,
      serviceName: serviceName,
      isOrder: isOrder,
    ),
  );
}

class _ServiceRatingModal extends StatefulWidget {
  final String bookingId;
  final String? providerName;
  final String? serviceName;
  final bool isOrder;

  const _ServiceRatingModal({
    required this.bookingId,
    this.providerName,
    this.serviceName,
    this.isOrder = false,
  });

  @override
  State<_ServiceRatingModal> createState() => _ServiceRatingModalState();
}

class _ServiceRatingModalState extends State<_ServiceRatingModal>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final int _hoverRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const List<String> _quickTags = [
    'Excellent work',
    'On time',
    'Professional',
    'Good value',
    'Friendly',
    'Would recommend',
  ];
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  Color get _ratingColor {
    switch (_rating) {
      case 1:
        return AppTheme.error;
      case 2:
        return AppTheme.warning;
      case 3:
        return const Color(0xFFFFC107);
      case 4:
        return AppTheme.catGrocery;
      case 5:
        return AppTheme.success;
      default:
        return AppTheme.outline;
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a star rating',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final reviewText = _reviewController.text.trim();
      final tags = _selectedTags.toList();
      final fullReview = [
        if (tags.isNotEmpty) tags.join(', '),
        if (reviewText.isNotEmpty) reviewText,
      ].join('. ');

      // Insert review into reviews table
      await Supabase.instance.client.from('reviews').insert({
        if (widget.isOrder)
          'order_id': widget.bookingId
        else
          'booking_id': widget.bookingId,
        'customer_id': userId,
        'rating': _rating,
        'review_text': fullReview.isNotEmpty ? fullReview : null,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
        // Auto-close after showing success
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit review. Please try again.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _submitted ? _buildSuccessView() : _buildRatingView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Thank You!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your review has been submitted successfully.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRatingView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC107),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Rate Your Experience',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.serviceName?.isNotEmpty == true
                  ? 'How was ${widget.serviceName}?'
                  : widget.providerName?.isNotEmpty == true
                  ? 'How was your service with ${widget.providerName}?'
                  : 'How was your service experience?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 24),

            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final filled =
                    starIndex <= (_hoverRating > 0 ? _hoverRating : _rating);
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  onPanUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final localPos = box.globalToLocal(details.globalPosition);
                    final starWidth = box.size.width / 5;
                    final newRating = (localPos.dx / starWidth).ceil().clamp(
                      1,
                      5,
                    );
                    setState(() => _rating = newRating);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled
                          ? const Color(0xFFFFC107)
                          : AppTheme.outline.withValues(alpha: 0.4),
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rating label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabel,
                key: ValueKey(_rating),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ratingColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickTags.map((tag) {
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
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.background,
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.outline.withValues(alpha: 0.3),
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppTheme.primary : AppTheme.outline,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Review text field
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 3,
                maxLength: 300,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF1A1C1E),
                ),
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.outline,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Review',
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
}
