import 'package:flutter_riverpod/flutter_riverpod.dart';

class PeriodFilter {
  final String period; // 'Mese' o 'Anno'
  final int month;
  final int year;
  PeriodFilter({required this.period, required this.month, required this.year});
  factory PeriodFilter.currentMonth() {
    final now = DateTime.now();
    return PeriodFilter(period: 'Mese', month: now.month, year: now.year);
  }
}

final periodFilterProvider =
    StateProvider<PeriodFilter>((ref) => PeriodFilter.currentMonth());
