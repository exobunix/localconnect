import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

/// Shows real-time availability calendar + slot picker for customers
/// before they confirm checkout.
class CustomerAvailabilityWidget extends StatefulWidget {
  final String providerId;
  final ValueChanged<Map<String, dynamic>?> onSlotSelected;
  final Map<String, dynamic>? initialSelection;

  const CustomerAvailabilityWidget({
    super.key,
    required this.providerId,
    required this.onSlotSelected,
    this.initialSelection,
  });

  @override
  State<CustomerAvailabilityWidget> createState() =>
      _CustomerAvailabilityWidgetState();
}

class _CustomerAvailabilityWidgetState
    extends State<CustomerAvailabilityWidget> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _loading = false;
  String? _selectedSlotTime;
  String? _selectedSlotDisplay;

  // Days off set for quick lookup
  final Set<String> _daysOffSet = {};

  static const List<String> _dayShort = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const List<String> _monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedSlotTime = widget.initialSelection!['time'] as String?;
      _selectedSlotDisplay = widget.initialSelection!['display'] as String?;
    }
    _loadDaysOff();
    _loadSlots();
  }

  Future<void> _loadDaysOff() async {
    final daysOff = await SupabaseService.instance.getProviderDaysOff(
      widget.providerId,
    );
    if (mounted) {
      setState(() {
        _daysOffSet.clear();
        for (final d in daysOff) {
          _daysOffSet.add(d['off_date'] as String? ?? '');
        }
      });
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _slots = [];
    });
    final slots = await SupabaseService.instance.getAvailableSlots(
      providerId: widget.providerId,
      date: _selectedDate,
    );
    if (mounted) {
      setState(() {
        _slots = slots;
        _loading = false;
      });
    }
  }

  bool _isDayOff(DateTime date) {
    final str =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _daysOffSet.contains(str);
  }

  void _selectSlot(Map<String, dynamic> slot) {
    final time = slot['time'] as String;
    final display = slot['display'] as String? ?? time;
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      _selectedSlotTime = time;
      _selectedSlotDisplay = display;
    });

    widget.onSlotSelected({
      'time': time,
      'display': display,
      'date': dateStr,
      'dateDisplay':
          '${_dayShort[_selectedDate.weekday % 7]}, ${_selectedDate.day} ${_monthNames[_selectedDate.month]}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Date & Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if (_selectedSlotTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedSlotDisplay ?? _selectedSlotTime!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Date strip
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 14,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final date = DateTime.now().add(Duration(days: i));
                final isSelected =
                    _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;
                final isDayOff = _isDayOff(date);

                return GestureDetector(
                  onTap: isDayOff
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlotTime = null;
                            _selectedSlotDisplay = null;
                          });
                          widget.onSlotSelected(null);
                          _loadSlots();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    decoration: BoxDecoration(
                      color: isDayOff
                          ? const Color(0xFFF5F5F5)
                          : isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDayOff
                            ? AppTheme.outlineVariant
                            : isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineVariant,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayShort[date.weekday % 7],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDayOff
                                    ? AppTheme.outline
                                    : isSelected
                                    ? Colors.white70
                                    : const Color(0xFF74777F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.day}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDayOff
                                    ? AppTheme.outline
                                    : isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1C1E),
                              ),
                            ),
                          ],
                        ),
                        if (isDayOff)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Slots
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : _slots.isEmpty
                ? _buildNoSlots()
                : _buildSlotsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlots() {
    final isDayOff = _isDayOff(_selectedDate);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDayOff ? Icons.event_busy_rounded : Icons.schedule_rounded,
            size: 40,
            color: isDayOff
                ? AppTheme.error.withValues(alpha: 0.4)
                : AppTheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            isDayOff
                ? 'Provider is off on this day'
                : 'No slots available on this date',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please select another date',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsGrid() {
    final available = _slots
        .where(
          (s) =>
              (s['is_available'] as bool? ?? true) &&
              !(s['is_past'] as bool? ?? false),
        )
        .toList();
    final unavailable = _slots
        .where(
          (s) =>
              !(s['is_available'] as bool? ?? true) ||
              (s['is_past'] as bool? ?? false),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (available.isNotEmpty) ...[
          Text(
            'Available Slots',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available.map((slot) {
              final time = slot['time'] as String;
              final isSelected = _selectedSlotTime == time;
              return GestureDetector(
                onTap: () => _selectSlot(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.success.withValues(alpha: 0.4),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        slot['display'] as String? ?? time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (unavailable.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unavailable.map((slot) {
              final time = slot['time'] as String;
              final isBooked = slot['is_booked'] as bool? ?? false;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isBooked
                      ? AppTheme.errorContainer
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBooked
                        ? AppTheme.error.withValues(alpha: 0.3)
                        : AppTheme.outlineVariant,
                  ),
                ),
                child: Text(
                  slot['display'] as String? ?? time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isBooked ? AppTheme.error : AppTheme.outline,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
