import 'package:flutter/material.dart';

import 'package:chagas_predictor/models/care_plan_model.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/patient/care_plan_service.dart';
import 'package:chagas_predictor/services/pdf/pdf_report_service.dart';
import 'package:chagas_predictor/widgets/care_plan/meditation_timer_modal.dart';
import 'package:chagas_predictor/widgets/care_plan/month_calendar_grid_view.dart';

class CarePlanPage extends StatefulWidget {
  final UserProfile? profile;
  final PatientDetails? patientDetails;

  const CarePlanPage({
    super.key,
    this.profile,
    this.patientDetails,
  });

  @override
  State<CarePlanPage> createState() => _CarePlanPageState();
}

class _CarePlanPageState extends State<CarePlanPage> {
  final CarePlanService _carePlanService = CarePlanService();

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  CarePlanCategory? _selectedCategory;
  bool _isMonthOverviewMode = true;
  late ScrollController _dayRibbonScrollController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedDay = now.day;
    _dayRibbonScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void dispose() {
    _dayRibbonScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    if (_dayRibbonScrollController.hasClients) {
      const double itemWidth = 66.0;
      final double targetOffset = (_selectedDay - 1) * itemWidth - 100.0;
      final double maxScroll = _dayRibbonScrollController.position.maxScrollExtent;
      final double clampOffset = targetOffset.clamp(0.0, maxScroll);
      _dayRibbonScrollController.animateTo(
        clampOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      int newMonth = _selectedMonth + delta;
      int newYear = _selectedYear;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      _selectedMonth = newMonth;
      _selectedYear = newYear;

      // Ensure selected day is within valid range for new month
      final maxDays = _carePlanService.getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > maxDays) {
        _selectedDay = maxDays;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedYear = now.year;
      _selectedMonth = now.month;
      _selectedDay = now.day;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  bool _isTodaySelected() {
    final now = DateTime.now();
    return _selectedYear == now.year &&
        _selectedMonth == now.month &&
        _selectedDay == now.day;
  }

  void _toggleTaskCompletion(String taskId) {
    setState(() {
      _carePlanService.toggleItemCompletion(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        taskId,
      );
    });
  }

  void _openMeditationTimer(CarePlanItem item) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MeditationTimerModal(
        item: item,
        onCompleted: () {
          _toggleTaskCompletion(item.id);
        },
      ),
    );
  }

  void _showAddCustomTaskSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final timeSlotController = TextEditingController(text: '02:00 PM');
    CarePlanCategory category = CarePlanCategory.health;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Custom Care Plan Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF123230),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Selection
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: CarePlanCategory.values.map((cat) {
                      final isSel = category == cat;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              cat.displayName.split(' ').first,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSel ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: cat.color,
                            onSelected: (_) {
                              setSheetState(() => category = cat);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Activity Title',
                      hintText: 'e.g. Extra Hydration / Doctor Call',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Instructions / Description',
                      hintText: 'e.g. Drink 300ml green tea with herbal honey',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: timeSlotController,
                    decoration: InputDecoration(
                      labelText: 'Time Slot',
                      hintText: 'e.g. 04:00 PM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        final newItem = CarePlanItem(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleController.text.trim(),
                          description: descController.text.trim().isEmpty
                              ? 'Custom personal activity'
                              : descController.text.trim(),
                          category: category,
                          timeSlot: timeSlotController.text.trim(),
                          icon: category.icon,
                        );
                        _carePlanService.addCustomItem(
                          _selectedYear,
                          _selectedMonth,
                          _selectedDay,
                          newItem,
                        );
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B67),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ADD TO CARE PLAN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPlan = _carePlanService.getMonthlyCarePlan(
      _selectedYear,
      _selectedMonth,
    );
    final dailyPlan = monthlyPlan.dailyPlans[_selectedDay] ??
        DailyCarePlan(
          date: DateTime(_selectedYear, _selectedMonth, _selectedDay),
          items: [],
        );

    final filteredItems = _selectedCategory == null
        ? dailyPlan.items
        : dailyPlan.items
            .where((item) => item.category == _selectedCategory)
            .toList();

    final patientName = widget.patientDetails?.fullName.trim().split(RegExp(r'\s+')).first ??
        widget.profile?.name ??
        'Patient';

    final isCurrentRealtimeMonth = DateTime.now().year == _selectedYear &&
        DateTime.now().month == _selectedMonth;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '1-Month Care Plan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Monthly Plan',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Generating care plan PDF report for ${monthlyPlan.monthName}...',
                  ),
                  backgroundColor: const Color(0xFF006B67),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await PdfReportService().generateAndDownloadCarePlanReport(
                monthlyPlan: monthlyPlan,
                patientDetails: widget.patientDetails,
                profile: widget.profile,
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isMonthOverviewMode
                  ? Icons.view_day_outlined
                  : Icons.calendar_month_outlined,
            ),
            tooltip: _isMonthOverviewMode
                ? 'Switch to Daily View'
                : 'Switch to Month Overview Grid',
            onPressed: () {
              setState(() {
                _isMonthOverviewMode = !_isMonthOverviewMode;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Header Banner & Realtime Month Navigation Bar
                  _buildHeaderBanner(
                    patientName: patientName,
                    monthlyPlan: monthlyPlan,
                    isCurrentRealtimeMonth: isCurrentRealtimeMonth,
                  ),
                  const SizedBox(height: 20),

                  // 2. Real-Time Month Picker Bar (< August 2026 >)
                  _buildMonthSelectorBar(monthlyPlan),
                  const SizedBox(height: 12),

                  // View Mode Selector (Full Month Calendar Grid vs Day Selector Ribbon)
                  _buildViewModeToggleBar(monthlyPlan),
                  const SizedBox(height: 16),

                  // Mode view rendering
                  if (_isMonthOverviewMode) ...[
                    MonthCalendarGridView(
                      monthlyPlan: monthlyPlan,
                      selectedDay: _selectedDay,
                      onSelectDay: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                        _scrollToSelectedDay();
                      },
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Horizontal Day Ribbon Picker with navigation controls & range jump chips
                    _buildDayRibbonPicker(monthlyPlan),
                    const SizedBox(height: 20),
                  ],

                  // 3. Category Filter Tabs (All, Food, Meditation, Health)
                  _buildCategoryFilterTabs(),
                  const SizedBox(height: 20),

                  // 4. Daily Adherence Metrics Card
                  _buildDailyProgressSummaryCard(dailyPlan),
                  const SizedBox(height: 24),

                  // 5. Section Header for Daily Plan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule for ${monthlyPlan.monthName.split(' ').first} $_selectedDay, $_selectedYear',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF123230),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${filteredItems.length} activities scheduled',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showAddCustomTaskSheet,
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 20),
                        label: const Text(
                          'Add Activity',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF006B67),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Care Plan Items List
                  if (filteredItems.isEmpty)
                    _buildEmptyCategoryState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildCarePlanItemCard(filteredItems[index]);
                      },
                    ),

                  const SizedBox(height: 28),

                  // 7. Monthly Cardiac Goals Callout Card
                  _buildMonthlyGoalsCard(monthlyPlan),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomTaskSheet,
        backgroundColor: const Color(0xFF006B67),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // Header Banner Card
  Widget _buildHeaderBanner({
    required String patientName,
    required MonthlyCarePlan monthlyPlan,
    required bool isCurrentRealtimeMonth,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005B57), Color(0xFF006B67), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: Color(0xFF99F6E4), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isCurrentRealtimeMonth ? 'ACTIVE REALTIME MONTH' : 'SCHEDULED PLAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Chagas Health Protocol',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$patientName\'s Personalized Care Plan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Structured 1-Month nutrition, mindfulness meditation, & cardiac health routines.',
            style: TextStyle(
              color: Color(0xFFCCFBF1),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Realtime Month Selector Bar
  Widget _buildMonthSelectorBar(MonthlyCarePlan monthlyPlan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Previous Month',
          ),
          InkWell(
            onTap: () {
              // Toggle grid overview when clicking month title
              setState(() {
                _isMonthOverviewMode = !_isMonthOverviewMode;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Color(0xFF006B67), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    monthlyPlan.monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123230),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isMonthOverviewMode
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF006B67),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _goToToday,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: const Color(0xFFE0F2FE),
                  foregroundColor: const Color(0xFF0369A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () => _changeMonth(1),
                tooltip: 'Next Month',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // View Mode Toggle Bar (Full Month Grid vs Day Selector Ribbon)
  Widget _buildViewModeToggleBar(MonthlyCarePlan monthlyPlan) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isMonthOverviewMode = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isMonthOverviewMode ? const Color(0xFF006B67) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isMonthOverviewMode
                      ? [
                          BoxShadow(
                            color: const Color(0xFF006B67).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_view_month_rounded,
                      size: 18,
                      color: _isMonthOverviewMode ? Colors.white : const Color(0xFF4A5568),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Full Month Grid (${monthlyPlan.daysInMonth} Days)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isMonthOverviewMode ? Colors.white : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isMonthOverviewMode = false;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isMonthOverviewMode ? const Color(0xFF006B67) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isMonthOverviewMode
                      ? [
                          BoxShadow(
                            color: const Color(0xFF006B67).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_day_outlined,
                      size: 18,
                      color: !_isMonthOverviewMode ? Colors.white : const Color(0xFF4A5568),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Day Selector Ribbon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !_isMonthOverviewMode ? Colors.white : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Day Ribbon Picker (Horizontal Calendar Strip)
  Widget _buildDayRibbonPicker(MonthlyCarePlan monthlyPlan) {
    final daysCount = monthlyPlan.daysInMonth;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Day Range Jump Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRangeChip('Days 1-7', 1, monthlyPlan),
              const SizedBox(width: 6),
              _buildRangeChip('Days 8-14', 8, monthlyPlan),
              const SizedBox(width: 6),
              _buildRangeChip('Days 15-21', 15, monthlyPlan),
              const SizedBox(width: 6),
              _buildRangeChip('Days 22-$daysCount', 22, monthlyPlan),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Scrollable Ribbon with Left/Right Navigation Arrows
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () {
                if (_dayRibbonScrollController.hasClients) {
                  final newOffset = (_dayRibbonScrollController.offset - 200).clamp(
                    0.0,
                    _dayRibbonScrollController.position.maxScrollExtent,
                  );
                  _dayRibbonScrollController.animateTo(
                    newOffset,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
              tooltip: 'Scroll Left',
            ),
            Expanded(
              child: SizedBox(
                height: 75,
                child: ListView.builder(
                  controller: _dayRibbonScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: daysCount,
                  itemBuilder: (context, index) {
                    final dayNum = index + 1;
                    final date = DateTime(_selectedYear, _selectedMonth, dayNum);
                    final isSelected = dayNum == _selectedDay;
                    final isToday = now.year == _selectedYear &&
                        now.month == _selectedMonth &&
                        now.day == dayNum;

                    const weekShorts = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                    final weekStr = weekShorts[date.weekday - 1];

                    final dailyP = monthlyPlan.dailyPlans[dayNum];
                    final completionRate = dailyP?.completionRate ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedDay = dayNum);
                          _scrollToSelectedDay();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF006B67)
                                : (isToday
                                    ? const Color(0xFFCCFBF1)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF006B67)
                                  : (isToday
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFE2E8F0)),
                              width: isToday || isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white70
                                      : (date.weekday >= 6
                                          ? const Color(0xFFE46A4A)
                                          : Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF1E293B)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? (completionRate > 0.8
                                          ? const Color(0xFF4ADE80)
                                          : Colors.white70)
                                      : (completionRate > 0.8
                                          ? const Color(0xFF16A34A)
                                          : Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onPressed: () {
                if (_dayRibbonScrollController.hasClients) {
                  final newOffset = (_dayRibbonScrollController.offset + 200).clamp(
                    0.0,
                    _dayRibbonScrollController.position.maxScrollExtent,
                  );
                  _dayRibbonScrollController.animateTo(
                    newOffset,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
              tooltip: 'Scroll Right',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label, int startDay, MonthlyCarePlan monthlyPlan) {
    final endDay = (startDay + 6) < monthlyPlan.daysInMonth ? (startDay + 6) : monthlyPlan.daysInMonth;
    final isCurrentRange = _selectedDay >= startDay && _selectedDay <= endDay;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCurrentRange ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isCurrentRange,
      selectedColor: const Color(0xFF006B67),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentRange ? const Color(0xFF006B67) : const Color(0xFFCBD5E1),
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedDay = startDay;
        });
        _scrollToSelectedDay();
      },
    );
  }

  // Category Filter Tabs
  Widget _buildCategoryFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Activities',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF006B67),
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: CarePlanCategory.food.displayName,
            icon: CarePlanCategory.food.icon,
            color: CarePlanCategory.food.color,
            isSelected: _selectedCategory == CarePlanCategory.food,
            onTap: () => setState(() => _selectedCategory = CarePlanCategory.food),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: CarePlanCategory.meditation.displayName,
            icon: CarePlanCategory.meditation.icon,
            color: CarePlanCategory.meditation.color,
            isSelected: _selectedCategory == CarePlanCategory.meditation,
            onTap: () =>
                setState(() => _selectedCategory = CarePlanCategory.meditation),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: CarePlanCategory.health.displayName,
            icon: CarePlanCategory.health.icon,
            color: CarePlanCategory.health.color,
            isSelected: _selectedCategory == CarePlanCategory.health,
            onTap: () => setState(() => _selectedCategory = CarePlanCategory.health),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // Daily Progress Summary Card
  Widget _buildDailyProgressSummaryCard(DailyCarePlan dailyPlan) {
    final completionPct = (dailyPlan.completionRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B67).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: dailyPlan.completionRate,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        dailyPlan.completionRate > 0.8
                            ? const Color(0xFF10B981)
                            : const Color(0xFF006B67),
                      ),
                    ),
                  ),
                  Text(
                    '$completionPct%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF123230),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Adherence Progress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123230),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dailyPlan.completedItems} of ${dailyPlan.totalItems} care items completed today',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryMiniProgress(
                title: 'Food',
                completed: dailyPlan.completedFoodItems,
                total: dailyPlan.totalFoodItems,
                color: const Color(0xFFE46A4A),
              ),
              _buildCategoryMiniProgress(
                title: 'Meditation',
                completed: dailyPlan.completedMeditationItems,
                total: dailyPlan.totalMeditationItems,
                color: const Color(0xFF7C3AED),
              ),
              _buildCategoryMiniProgress(
                title: 'Health',
                completed: dailyPlan.completedHealthItems,
                total: dailyPlan.totalHealthItems,
                color: const Color(0xFF006B67),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMiniProgress({
    required String title,
    required int completed,
    required int total,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // Care Plan Item Card
  Widget _buildCarePlanItemCard(CarePlanItem item) {
    final catColor = item.category.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isCompleted
              ? catColor.withOpacity(0.4)
              : const Color(0xFFE2E8F0),
          width: item.isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: catColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  item.timeSlot,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.targetValue != null)
                            Text(
                              item.targetValue!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Checkbox toggle
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: item.isCompleted,
                    activeColor: catColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (_) => _toggleTaskCompletion(item.id),
                  ),
                ),
              ],
            ),

            // Action row if meditation or health tip
            if (item.category == CarePlanCategory.meditation ||
                item.recommendationNote != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.recommendationNote != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              size: 15, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.recommendationNote!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.category == CarePlanCategory.meditation)
                    ElevatedButton.icon(
                      onPressed: () => _openMeditationTimer(item),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: const Text('Start Timer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No items in this category for today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select another category filter or add a custom task.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // Monthly Focus Goals Card
  Widget _buildMonthlyGoalsCard(MonthlyCarePlan monthlyPlan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flag_rounded, color: Color(0xFF047857), size: 22),
              SizedBox(width: 10),
              Text(
                '1-Month Focus Goals & Clinical Milestones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF064E3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: monthlyPlan.monthlyFocusGoals.map((goal) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF065F46),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
