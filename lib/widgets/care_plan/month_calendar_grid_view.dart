import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/care_plan_model.dart';

class MonthCalendarGridView extends StatelessWidget {
  final MonthlyCarePlan monthlyPlan;
  final int selectedDay;
  final ValueChanged<int> onSelectDay;

  const MonthCalendarGridView({
    super.key,
    required this.monthlyPlan,
    required this.selectedDay,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(monthlyPlan.year, monthlyPlan.month, 1);
    // DateTime.weekday: Mon=1 ... Sun=7
    final leadingEmptyDays = firstDayOfMonth.weekday - 1; // 0 for Mon, 6 for Sun

    const weekDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B67).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    '${monthlyPlan.monthName} Overview',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123230),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any date to view or complete daily plan activities',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFF006B67), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${(monthlyPlan.overallCompletionRate * 100).toInt()}% Avg Plan',
                      style: const TextStyle(
                        color: Color(0xFF006B67),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weekday header strip
          Row(
            children: weekDays.map((day) {
              final isWeekend = day == 'SAT' || day == 'SUN';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isWeekend
                          ? const Color(0xFFE46A4A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyDays + monthlyPlan.daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - leadingEmptyDays + 1;
              final todayDate = DateTime(now.year, now.month, now.day);
              final cellDate = DateTime(monthlyPlan.year, monthlyPlan.month, dayNumber);

              final isToday = cellDate.isAtSameMomentAs(todayDate);
              final isFuture = cellDate.isAfter(todayDate);
              final isSelected = selectedDay == dayNumber;

              final dailyPlan = monthlyPlan.dailyPlans[dayNumber];
              final completionRate = dailyPlan?.completionRate ?? 0.0;

              return InkWell(
                onTap: () => onSelectDay(dayNumber),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF006B67)
                        : (isToday
                            ? const Color(0xFFCCFBF1)
                            : (isFuture
                                ? const Color(0xFFF1F5F9)
                                : (completionRate > 0.8
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFF8FAFC)))),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF006B67)
                          : (isToday
                              ? const Color(0xFF0D9488)
                              : Colors.grey.shade200),
                      width: isToday || isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF006B67).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isToday
                                        ? const Color(0xFF0F766E)
                                        : (isFuture
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF1E293B))),
                              ),
                            ),
                            if (isToday)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFFDBA74)
                                      : const Color(0xFF0D9488),
                                ),
                              )
                            else if (isFuture)
                              const Icon(Icons.lock_outline_rounded, size: 10, color: Color(0xFF94A3B8)),
                          ],
                        ),

                        // Mini category dots
                        if (dailyPlan != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMiniDot(
                                completed: dailyPlan.completedFoodItems > 0,
                                color: isSelected
                                    ? const Color(0xFFFFEDD5)
                                    : const Color(0xFFE46A4A),
                              ),
                              const SizedBox(width: 3),
                              _buildMiniDot(
                                completed: dailyPlan.completedMeditationItems > 0,
                                color: isSelected
                                    ? const Color(0xFFDDD6FE)
                                    : const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 3),
                              _buildMiniDot(
                                completed: dailyPlan.completedHealthItems > 0,
                                color: isSelected
                                    ? const Color(0xFF99F6E4)
                                    : const Color(0xFF006B67),
                              ),
                            ],
                          ),

                        // Completion indicator text
                        Text(
                          '${(completionRate * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : (completionRate == 1.0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Food Plan', const Color(0xFFE46A4A)),
              const SizedBox(width: 16),
              _buildLegendItem('Meditation', const Color(0xFF7C3AED)),
              const SizedBox(width: 16),
              _buildLegendItem('Health & Meds', const Color(0xFF006B67)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDot({required bool completed, required Color color}) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? color : color.withOpacity(0.25),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
