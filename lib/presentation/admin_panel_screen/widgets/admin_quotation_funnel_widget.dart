import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class AdminQuotationFunnelWidget extends StatefulWidget {
  const AdminQuotationFunnelWidget({super.key});

  @override
  State<AdminQuotationFunnelWidget> createState() =>
      _AdminQuotationFunnelWidgetState();
}

class _AdminQuotationFunnelWidgetState extends State<AdminQuotationFunnelWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _sent = 0;
  int _accepted = 0;
  int _booked = 0;
  int _completed = 0;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadFunnelData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadFunnelData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getQuotationFunnelData();
      if (mounted) {
        setState(() {
          _sent = data['sent'] as int? ?? 0;
          _accepted = data['accepted'] as int? ?? 0;
          _booked = data['booked'] as int? ?? 0;
          _completed = data['completed'] as int? ?? 0;
          _isLoading = false;
        });
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _conversionRate(int numerator, int denominator) {
    if (denominator == 0) return 0;
    return (numerator / denominator * 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceVariant : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quotation Funnel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Conversion tracking across stages',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _loadFunnelData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(153),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? _buildSkeleton()
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) => _buildFunnel(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunnel() {
    final stages = [
      _FunnelStage(
        label: 'Sent',
        count: _sent,
        color: const Color(0xFF6366F1),
        icon: Icons.send_rounded,
        conversionLabel: null,
        conversionRate: null,
      ),
      _FunnelStage(
        label: 'Accepted',
        count: _accepted,
        color: const Color(0xFF3B82F6),
        icon: Icons.check_circle_rounded,
        conversionLabel: 'Sent → Accepted',
        conversionRate: _conversionRate(_accepted, _sent),
      ),
      _FunnelStage(
        label: 'Booked',
        count: _booked,
        color: const Color(0xFF10B981),
        icon: Icons.calendar_today_rounded,
        conversionLabel: 'Accepted → Booked',
        conversionRate: _conversionRate(_booked, _accepted),
      ),
      _FunnelStage(
        label: 'Completed',
        count: _completed,
        color: const Color(0xFFF59E0B),
        icon: Icons.task_alt_rounded,
        conversionLabel: 'Booked → Completed',
        conversionRate: _conversionRate(_completed, _booked),
      ),
    ];

    final maxCount = stages
        .map((s) => s.count)
        .fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          _buildFunnelBar(stages[i], maxCount),
          if (i < stages.length - 1) _buildConversionArrow(stages[i + 1]),
        ],
        const SizedBox(height: 16),
        _buildOverallConversion(),
      ],
    );
  }

  Widget _buildFunnelBar(_FunnelStage stage, int maxCount) {
    final fraction = maxCount == 0 ? 0.0 : stage.count / maxCount;
    final animatedFraction = fraction * _animation.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Funnel shape: each bar is narrower based on fraction, min 40%
        final barWidth = maxWidth * (0.4 + animatedFraction * 0.6);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: barWidth,
                      height: 52,
                      decoration: BoxDecoration(
                        color: stage.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(stage.icon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stage.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${stage.count}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversionArrow(_FunnelStage nextStage) {
    final rate = nextStage.conversionRate ?? 0;
    final rateStr = '${rate.toStringAsFixed(1)}%';
    final isGood = rate >= 50;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isGood
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: 20,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isGood
                  ? const Color(0xFF10B981).withAlpha(31)
                  : const Color(0xFFEF4444).withAlpha(31),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isGood
                    ? const Color(0xFF10B981).withAlpha(77)
                    : const Color(0xFFEF4444).withAlpha(77),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nextStage.conversionLabel ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  rateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isGood
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallConversion() {
    final overallRate = _conversionRate(_completed, _sent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(51)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Overall Conversion (Sent → Completed)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
          ),
          Text(
            '${overallRate.toStringAsFixed(1)}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(4, (i) {
        final widths = [1.0, 0.8, 0.65, 0.5];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: widths[i],
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FunnelStage {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final String? conversionLabel;
  final double? conversionRate;

  const _FunnelStage({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.conversionLabel,
    required this.conversionRate,
  });
}
