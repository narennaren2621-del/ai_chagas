import 'package:flutter/material.dart';

enum CarePlanCategory {
  food,
  meditation,
  health,
}

extension CarePlanCategoryExtension on CarePlanCategory {
  String get displayName {
    switch (this) {
      case CarePlanCategory.food:
        return 'Food & Nutrition';
      case CarePlanCategory.meditation:
        return 'Meditation & Mind';
      case CarePlanCategory.health:
        return 'Health & Meds';
    }
  }

  IconData get icon {
    switch (this) {
      case CarePlanCategory.food:
        return Icons.restaurant_rounded;
      case CarePlanCategory.meditation:
        return Icons.self_improvement_rounded;
      case CarePlanCategory.health:
        return Icons.favorite_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CarePlanCategory.food:
        return const Color(0xFFE46A4A); // Terracotta Warm Amber
      case CarePlanCategory.meditation:
        return const Color(0xFF7C3AED); // Deep Calming Purple
      case CarePlanCategory.health:
        return const Color(0xFF006B67); // Deep Teal
    }
  }
}

class CarePlanItem {
  final String id;
  final String title;
  final String description;
  final CarePlanCategory category;
  final String timeSlot;
  final String? targetValue;
  final IconData icon;
  bool isCompleted;
  final int durationMinutes;
  final String? recommendationNote;

  CarePlanItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timeSlot,
    this.targetValue,
    required this.icon,
    this.isCompleted = false,
    this.durationMinutes = 0,
    this.recommendationNote,
  });

  CarePlanItem copyWith({
    String? id,
    String? title,
    String? description,
    CarePlanCategory? category,
    String? timeSlot,
    String? targetValue,
    IconData? icon,
    bool? isCompleted,
    int? durationMinutes,
    String? recommendationNote,
  }) {
    return CarePlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timeSlot: timeSlot ?? this.timeSlot,
      targetValue: targetValue ?? this.targetValue,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recommendationNote: recommendationNote ?? this.recommendationNote,
    );
  }
}

class DailyCarePlan {
  final DateTime date;
  final List<CarePlanItem> items;

  DailyCarePlan({
    required this.date,
    required this.items,
  });

  int get totalItems => items.length;
  int get completedItems => items.where((item) => item.isCompleted).length;
  double get completionRate =>
      totalItems == 0 ? 0.0 : (completedItems / totalItems);

  int get totalFoodItems =>
      items.where((i) => i.category == CarePlanCategory.food).length;
  int get completedFoodItems => items
      .where((i) => i.category == CarePlanCategory.food && i.isCompleted)
      .length;

  int get totalMeditationItems =>
      items.where((i) => i.category == CarePlanCategory.meditation).length;
  int get completedMeditationItems => items
      .where((i) => i.category == CarePlanCategory.meditation && i.isCompleted)
      .length;

  int get totalHealthItems =>
      items.where((i) => i.category == CarePlanCategory.health).length;
  int get completedHealthItems => items
      .where((i) => i.category == CarePlanCategory.health && i.isCompleted)
      .length;
}

class MonthlyCarePlan {
  final int year;
  final int month;
  final String monthName;
  final int daysInMonth;
  final Map<int, DailyCarePlan> dailyPlans;
  final List<String> monthlyFocusGoals;

  MonthlyCarePlan({
    required this.year,
    required this.month,
    required this.monthName,
    required this.daysInMonth,
    required this.dailyPlans,
    required this.monthlyFocusGoals,
  });

  double get overallCompletionRate {
    if (dailyPlans.isEmpty) return 0.0;
    double sum = 0.0;
    for (var plan in dailyPlans.values) {
      sum += plan.completionRate;
    }
    return sum / dailyPlans.length;
  }
}
