import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  final String providerId;

  const ProviderAvailabilityScreen({super.key, required this.providerId});

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState extends State<ProviderAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;

  // Working hours state: index = day_of_week (0=Sun..6=Sat)
  final List<_DayHours> _workingHours = List.generate(
    7,
    (i) => _DayHours(
      dayOfWeek: i,
      isOpen: i >= 1 && i <= 6, // Mon-Sat open by default
      openTime: const TimeOfDay(hour: 9, minute: 0),
      closeTime: const TimeOfDay(hour: 18, minute: 0),
      slotDuration: 60,
    ),
  );

  // Days off
  List<Map<String, dynamic>> _daysOff = [];

  // Slot management
  DateTime _selectedSlotDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;

  static const List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<int> _slotDurations = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _slots.isEmpty) {
        _loadSlots();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [hoursData, daysOffData] = await Future.wait([
        SupabaseService.instance.getProviderWorkingHours(widget.providerId),
        SupabaseService.instance.getProviderDaysOff(widget.providerId),
      ]);

      // Populate working hours
      for (final h in hoursData) {
        final day = h['day_of_week'] as int? ?? 0;
        if (day >= 0 && day < 7) {
          final openStr = h['open_time'] as String? ?? '09:00';
          final closeStr = h['close_time'] as String? ?? '18:00';
          _workingHours[day] = _DayHours(
            dayOfWeek: day,
            isOpen: h['is_open'] as bool? ?? true,
            openTime: _parseTime(openStr),
            closeTime: _parseTime(closeStr),
            slotDuration: h['slot_duration_minutes'] as int? ?? 60,
          );
        }
      }

      setState(() {
        _daysOff = List<Map<String, dynamic>>.from(daysOffData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _timeToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);
    try {
      for (final day in _workingHours) {
        await SupabaseService.instance.upsertWorkingHours(
          providerId: widget.providerId,
          dayOfWeek: day.dayOfWeek,
          isOpen: day.isOpen,
          openTime: _timeToString(day.openTime),
          closeTime: _timeToString(day.closeTime),
          slotDurationMinutes: day.slotDuration,
        );
      }
      Fluttertoast.showToast(
        msg: 'Working hours saved!',
        backgroundColor: AppTheme.success,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to save. Try again.',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addDayOff() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    String reason = '';
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Day Off',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dayNames[picked.weekday % 7]}, ${picked.day}/${picked.month}/${picked.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Reason (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => reason = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await SupabaseService.instance.addProviderDayOff(
      providerId: widget.providerId,
      date: picked,
      reason: reason,
    );
    await _loadData();
    Fluttertoast.showToast(
      msg: 'Day off added!',
      backgroundColor: AppTheme.success,
      textColor: Colors.white,
    );
  }

  Future<void> _removeDayOff(String id) async {
    await SupabaseService.instance.removeProviderDayOff(id);
    await _loadData();
    Fluttertoast.showToast(
      msg: 'Day off removed.',
      backgroundColor: AppTheme.warning,
      textColor: Colors.white,
    );
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    final slots = await SupabaseService.instance.getAvailableSlots(
      providerId: widget.providerId,
      date: _selectedSlotDate,
    );
    if (mounted) {
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _toggleSlot(Map<String, dynamic> slot) async {
    final isAvailable = slot['is_available'] as bool? ?? true;
    final isBooked = slot['is_booked'] as bool? ?? false;
    if (isBooked) {
      Fluttertoast.showToast(
        msg: 'This slot is already booked.',
        backgroundColor: AppTheme.warning,
        textColor: Colors.white,
      );
      return;
    }
    await SupabaseService.instance.toggleSlotAvailability(
      providerId: widget.providerId,
      date: _selectedSlotDate,
      slotTime: slot['time'] as String,
      isAvailable: !isAvailable,
    );
    await _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Availability Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Working Hours'),
            Tab(text: 'Days Off'),
            Tab(text: 'Slots'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkingHoursTab(),
                _buildDaysOffTab(),
                _buildSlotsTab(),
              ],
            ),
    );
  }

  // ─── Working Hours Tab ────────────────────────────────────────────────────

  Widget _buildWorkingHoursTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DayHoursCard(
              dayHours: _workingHours[i],
              dayName: _dayNames[i],
              slotDurations: _slotDurations,
              onToggle: (val) => setState(
                () => _workingHours[i] = _workingHours[i].copyWith(isOpen: val),
              ),
              onOpenTimeTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _workingHours[i].openTime,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) {
                  setState(
                    () => _workingHours[i] = _workingHours[i].copyWith(
                      openTime: t,
                    ),
                  );
                }
              },
              onCloseTimeTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _workingHours[i].closeTime,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) {
                  setState(
                    () => _workingHours[i] = _workingHours[i].copyWith(
                      closeTime: t,
                    ),
                  );
                }
              },
              onDurationChanged: (val) => setState(
                () => _workingHours[i] = _workingHours[i].copyWith(
                  slotDuration: val,
                ),
              ),
            ),
          ),
        ),
        _buildSaveBar(),
      ],
    );
  }

  Widget _buildSaveBar() {
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
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveWorkingHours,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(
            _isSaving ? 'Saving...' : 'Save Working Hours',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Days Off Tab ─────────────────────────────────────────────────────────

  Widget _buildDaysOffTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mark dates when you\'re unavailable',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addDayOff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _daysOff.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 56,
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No days off scheduled',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF74777F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add" to mark a day off',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _daysOff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _daysOff[i];
                    final dateStr = d['off_date'] as String? ?? '';
                    DateTime? date;
                    try {
                      date = DateTime.parse(dateStr);
                    } catch (_) {}
                    final reason = d['reason'] as String? ?? '';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.errorContainer,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event_busy_rounded,
                              color: AppTheme.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  date != null
                                      ? '${_dayNames[date.weekday % 7]}, ${date.day}/${date.month}/${date.year}'
                                      : dateStr,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                if (reason.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    reason,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF74777F),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.error,
                            ),
                            onPressed: () =>
                                _removeDayOff(d['id'] as String? ?? ''),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Slots Tab ────────────────────────────────────────────────────────────

  Widget _buildSlotsTab() {
    return Column(
      children: [
        // Date picker strip
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Date to Manage Slots',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final date = DateTime.now().add(Duration(days: i));
                    final isSelected =
                        _selectedSlotDate.year == date.year &&
                        _selectedSlotDate.month == date.month &&
                        _selectedSlotDate.day == date.day;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSlotDate = date);
                        _loadSlots();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              [
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                              ][date.weekday % 7],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
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
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1C1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Slots grid
        Expanded(
          child: _loadingSlots
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _slots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 56,
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No slots available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF74777F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set working hours first to generate slots',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          _LegendDot(
                            color: AppTheme.success,
                            label: 'Available',
                          ),
                          const SizedBox(width: 16),
                          _LegendDot(color: AppTheme.error, label: 'Booked'),
                          const SizedBox(width: 16),
                          _LegendDot(color: AppTheme.outline, label: 'Blocked'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: _slots.length,
                        itemBuilder: (_, i) {
                          final slot = _slots[i];
                          final isBooked = slot['is_booked'] as bool? ?? false;
                          final isAvailable =
                              slot['is_available'] as bool? ?? true;
                          final isPast = slot['is_past'] as bool? ?? false;

                          Color bgColor;
                          Color textColor;
                          if (isBooked) {
                            bgColor = AppTheme.errorContainer;
                            textColor = AppTheme.error;
                          } else if (!isAvailable || isPast) {
                            bgColor = const Color(0xFFEEEEEE);
                            textColor = AppTheme.outline;
                          } else {
                            bgColor = AppTheme.successContainer;
                            textColor = AppTheme.success;
                          }

                          return GestureDetector(
                            onTap: isPast || isBooked
                                ? null
                                : () => _toggleSlot(slot),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.3),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                slot['display'] as String? ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Day Hours Card ───────────────────────────────────────────────────────────

class _DayHoursCard extends StatelessWidget {
  final _DayHours dayHours;
  final String dayName;
  final List<int> slotDurations;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenTimeTap;
  final VoidCallback onCloseTimeTap;
  final ValueChanged<int> onDurationChanged;

  const _DayHoursCard({
    required this.dayHours,
    required this.dayName,
    required this.slotDurations,
    required this.onToggle,
    required this.onOpenTimeTap,
    required this.onCloseTimeTap,
    required this.onDurationChanged,
  });

  String _fmt(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayH:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dayHours.isOpen
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dayHours.isOpen
                      ? AppTheme.primaryContainer
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayName.substring(0, 3),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: dayHours.isOpen
                        ? AppTheme.primary
                        : AppTheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dayHours.isOpen
                        ? const Color(0xFF1A1C1E)
                        : AppTheme.outline,
                  ),
                ),
              ),
              Switch(
                value: dayHours.isOpen,
                onChanged: onToggle,
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
          if (dayHours.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Opens',
                    time: _fmt(dayHours.openTime),
                    onTap: onOpenTimeTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'Closes',
                    time: _fmt(dayHours.closeTime),
                    onTap: onCloseTimeTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Slot duration:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF74777F),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: slotDurations.map((d) {
                        final selected = dayHours.slotDuration == d;
                        return GestureDetector(
                          onTap: () => onDurationChanged(d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '${d}m',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF74777F),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF74777F),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF74777F),
          ),
        ),
      ],
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _DayHours {
  final int dayOfWeek;
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final int slotDuration;

  const _DayHours({
    required this.dayOfWeek,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    required this.slotDuration,
  });

  _DayHours copyWith({
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    int? slotDuration,
  }) {
    return _DayHours(
      dayOfWeek: dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      slotDuration: slotDuration ?? this.slotDuration,
    );
  }
}
