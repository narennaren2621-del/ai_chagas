import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/care_plan_model.dart';

class CarePlanService {
  static final CarePlanService _instance = CarePlanService._internal();
  factory CarePlanService() => _instance;
  CarePlanService._internal();

  // Cache generated plans in memory per "year-month" key (e.g. "2026-8")
  final Map<String, MonthlyCarePlan> _monthlyPlanCache = {};

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String getMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  MonthlyCarePlan getMonthlyCarePlan(int year, int month) {
    final key = '$year-$month';
    if (_monthlyPlanCache.containsKey(key)) {
      return _monthlyPlanCache[key]!;
    }

    final plan = _generateMonthlyPlan(year, month);
    _monthlyPlanCache[key] = plan;
    return plan;
  }

  void toggleItemCompletion(int year, int month, int day, String itemId) {
    final key = '$year-$month';
    final monthlyPlan = getMonthlyCarePlan(year, month);
    final dailyPlan = monthlyPlan.dailyPlans[day];
    if (dailyPlan != null) {
      for (var item in dailyPlan.items) {
        if (item.id == itemId) {
          item.isCompleted = !item.isCompleted;
          break;
        }
      }
    }
    _monthlyPlanCache[key] = monthlyPlan;
  }

  void addCustomItem(int year, int month, int day, CarePlanItem newItem) {
    final key = '$year-$month';
    final monthlyPlan = getMonthlyCarePlan(year, month);
    final dailyPlan = monthlyPlan.dailyPlans[day];
    if (dailyPlan != null) {
      dailyPlan.items.add(newItem);
    }
    _monthlyPlanCache[key] = monthlyPlan;
  }

  MonthlyCarePlan _generateMonthlyPlan(int year, int month) {
    final daysCount = getDaysInMonth(year, month);
    final mName = getMonthName(month);

    final Map<int, DailyCarePlan> dailyPlansMap = {};

    final now = DateTime.now();

    for (int day = 1; day <= daysCount; day++) {
      final date = DateTime(year, month, day);
      final weekday = date.weekday; // 1 = Mon, 7 = Sun
      final items = _generateDailyItemsForDate(date, day, weekday, now);
      dailyPlansMap[day] = DailyCarePlan(date: date, items: items);
    }

    final goals = [
      'Maintain < 1,500mg daily sodium intake for optimal cardiac load.',
      'Complete at least 15 mins of daily vagus nerve cardiac meditation.',
      '100% adherence to prescribed antiparasitic / cardiovascular medications.',
      'Perform weekly resting ECG & pulse trend logging every Sunday.',
    ];

    return MonthlyCarePlan(
      year: year,
      month: month,
      monthName: '$mName $year',
      daysInMonth: daysCount,
      dailyPlans: dailyPlansMap,
      monthlyFocusGoals: goals,
    );
  }

  List<CarePlanItem> _generateDailyItemsForDate(
    DateTime date,
    int day,
    int weekday,
    DateTime now,
  ) {
    final String dateKey =
        '${date.year}_${date.month}_${date.day}';

    final List<CarePlanItem> items = [];

    // -------------------------------------------------------------
    // FOOD & NUTRITION PLAN (5 scheduled items)
    // -------------------------------------------------------------
    items.add(
      CarePlanItem(
        id: '${dateKey}_food_1',
        title: 'Heart-Healthy Breakfast & Hydration',
        description:
            'Warm oatmeal with blueberries, chia seeds, & zero added salt + 400ml warm lemon water.',
        category: CarePlanCategory.food,
        timeSlot: '08:00 AM',
        targetValue: '400 ml water',
        icon: Icons.breakfast_dining_rounded,
        durationMinutes: 20,
        isCompleted: false,
        recommendationNote:
            'High fiber & antioxidants reduce inflammation & cardiac strain.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_food_2',
        title: 'Mid-Morning Potassium Hydration',
        description:
            'Fresh coconut water or raw papaya slices with unsalted almonds.',
        category: CarePlanCategory.food,
        timeSlot: '10:30 AM',
        targetValue: '350 ml intake',
        icon: Icons.local_drink_rounded,
        durationMinutes: 10,
        isCompleted: false,
        recommendationNote:
            'Potassium helps regulate electrolytes and cardiac electric stability.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_food_3',
        title: 'Low-Sodium Mediterranean Lunch',
        description:
            weekday % 2 == 0
                ? 'Baked salmon/tofu with quinoa, steamed spinach, & olive oil dressing.'
                : 'Lentil stew with steamed sweet potatoes & mixed leafy greens.',
        category: CarePlanCategory.food,
        timeSlot: '01:15 PM',
        targetValue: 'Balanced Plate',
        icon: Icons.lunch_dining_rounded,
        durationMinutes: 30,
        isCompleted: false,
        recommendationNote:
            'Avoid processed meats & high-sodium sauces to prevent fluid retention.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_food_4',
        title: 'Afternoon Vitality Snack & Green Tea',
        description:
            'Decaf hibiscus or green tea with 1/2 green apple & walnuts.',
        category: CarePlanCategory.food,
        timeSlot: '04:30 PM',
        targetValue: '250 ml tea',
        icon: Icons.bakery_dining_rounded,
        durationMinutes: 15,
        isCompleted: false,
        recommendationNote:
            'Flavones assist vascular relaxation and steady blood pressure.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_food_5',
        title: 'Light Cardiac-Easy Dinner',
        description:
            'Steamed zucchini soup with brown rice & grilled vegetables.',
        category: CarePlanCategory.food,
        timeSlot: '07:30 PM',
        targetValue: 'Light Portion',
        icon: Icons.dinner_dining_rounded,
        durationMinutes: 25,
        isCompleted: false,
        recommendationNote:
            'Eating dinner early prevents nocturnal gastric pressure on the chest.',
      ),
    );

    // -------------------------------------------------------------
    // MEDITATION & MINDFULNESS PLAN (3 scheduled sessions)
    // -------------------------------------------------------------
    items.add(
      CarePlanItem(
        id: '${dateKey}_med_1',
        title: 'Morning Vagus Nerve & Cardiac Rhythm Breathing',
        description:
            '10-minute diaphragmatic 4-7-8 breathing to boost HRV & calm autonomic cardiac control.',
        category: CarePlanCategory.meditation,
        timeSlot: '07:15 AM',
        targetValue: '10 Mins Session',
        icon: Icons.self_improvement_rounded,
        durationMinutes: 10,
        isCompleted: false,
        recommendationNote:
            'Stimulates vagal tone to support healthy resting cardiac rhythms.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_med_2',
        title: 'Midday Cardiac Mindfulness & Stress Release',
        description:
            '15-minute soothing auditory guided relaxation to lower stress cortisol.',
        category: CarePlanCategory.meditation,
        timeSlot: '02:00 PM',
        targetValue: '15 Mins Session',
        icon: Icons.spa_rounded,
        durationMinutes: 15,
        isCompleted: false,
        recommendationNote:
            'Lowering stress prevents sudden arrhythmia spikes.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_med_3',
        title: 'Night Body Scan & Deep Restful Sleep Meditation',
        description:
            '15-minute gentle muscle scan meditation to reduce nighttime hypertension.',
        category: CarePlanCategory.meditation,
        timeSlot: '09:30 PM',
        targetValue: '15 Mins Session',
        icon: Icons.bedtime_rounded,
        durationMinutes: 15,
        isCompleted: false,
        recommendationNote:
            'Restorative slow-wave sleep is essential for myocardial recovery.',
      ),
    );

    // -------------------------------------------------------------
    // OVERALL HEALTH & MEDICATION PLAN (4 scheduled activities)
    // -------------------------------------------------------------
    items.add(
      CarePlanItem(
        id: '${dateKey}_health_1',
        title: 'Morning Medication & Vitals Log',
        description:
            'Take prescribed morning cardiotonic/antiparasitic meds. Measure Blood Pressure & Resting HR.',
        category: CarePlanCategory.health,
        timeSlot: '08:30 AM',
        targetValue: '1 Dose + BP Log',
        icon: Icons.medication_rounded,
        durationMinutes: 5,
        isCompleted: false,
        recommendationNote:
            'Log BP readings if feeling fatigued or dizzy.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_health_2',
        title: weekday == 6 || weekday == 7
            ? 'Gentle 25-Min Cardiac Nature Walk'
            : '20-Min Low-Impact Stretching & Light Aerobics',
        description: weekday == 6 || weekday == 7
            ? 'Slow pace outdoor walk in green area. Keep heart rate below 110 bpm.'
            : 'Controlled low-impact physical exercise to maintain cardiac micro-circulation.',
        category: CarePlanCategory.health,
        timeSlot: '05:00 PM',
        targetValue: '20-25 Mins',
        icon: Icons.directions_walk_rounded,
        durationMinutes: 20,
        isCompleted: false,
        recommendationNote:
            'Stop immediately if experiencing chest tightness, breathlessness, or dizziness.',
      ),
    );

    items.add(
      CarePlanItem(
        id: '${dateKey}_health_3',
        title: 'Evening Cardiac Medication Dose',
        description:
            'Take prescribed evening cardiac medication with a glass of water after dinner.',
        category: CarePlanCategory.health,
        timeSlot: '08:30 PM',
        targetValue: '1 Dose',
        icon: Icons.medical_services_rounded,
        durationMinutes: 5,
        isCompleted: false,
        recommendationNote:
            'Consistent dosage times maintain steady therapeutic drug levels.',
      ),
    );

    if (weekday == 7) {
      // Sunday Weekly Milestone Check
      items.add(
        CarePlanItem(
          id: '${dateKey}_health_4',
          title: 'Weekly ECG & Symptom Trend Log',
          description:
              'Record a 1-min real-time ECG lead sample & log weekly palpitations or fatigue notes.',
          category: CarePlanCategory.health,
          timeSlot: '06:00 PM',
          targetValue: '1 ECG Session',
          icon: Icons.monitor_heart_rounded,
          durationMinutes: 10,
          isCompleted: false,
          recommendationNote:
              'Helps your attending physician evaluate Chagas risk progression.',
        ),
      );
    }

    return items;
  }
}
