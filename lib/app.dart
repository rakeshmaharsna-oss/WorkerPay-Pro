import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color appBackground = Color(0xFFF1F7FF);
const Color primary = Color(0xFF09698D);
const Color primaryDark = Color(0xFF075B7B);
const Color textDark = Color(0xFF101827);
const Color textMuted = Color(0xFF66727E);
const Color border = Color(0xFFC2CFDC);

const Color presentColor = Color(0xFF168B50);
const Color halfDayColor = Color(0xFFC65318);
const Color absentColor = Color(0xFFB8202B);
const Color holidayColor = Color(0xFF7134C7);
const Color otColor = Color(0xFFD97900);
const Color leaveColor = Color(0xFFB18A00);

enum AttendanceStatus {
  present,
  halfDay,
  absent,
  leave,
  holiday,
}

class AttendanceRecord {
  AttendanceStatus status;
  String normalHours;
  String otHours;
  String note;

  AttendanceRecord({
    required this.status,
    required this.normalHours,
    required this.otHours,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'normalHours': normalHours,
      'otHours': otHours,
      'note': note,
    };
  }

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    int statusIndex =
        int.tryParse('${json['status']}') ?? 0;

    if (statusIndex < 0 ||
        statusIndex >= AttendanceStatus.values.length) {
      statusIndex = 0;
    }

    return AttendanceRecord(
      status: AttendanceStatus.values[statusIndex],
      normalHours:
          '${json['normalHours'] ?? '8H'}',
      otHours:
          '${json['otHours'] ?? '0H'}',
      note:
          '${json['note'] ?? ''}',
    );
  }
}

class PaymentConfig {
  String calculationMode;
  double monthlySalary;
  int standardDays;
  double normalHoursPerDay;
  double otRate;
  double advance;
  double deduction;

  PaymentConfig({
    this.calculationMode = 'Fixed Days',
    this.monthlySalary = 16200,
    this.standardDays = 30,
    this.normalHoursPerDay = 8,
    this.otRate = 67.5,
    this.advance = 0,
    this.deduction = 0,
  });

  double dailyWageForMonth(DateTime month) {
    if (calculationMode == 'Month Days') {
      final days = DateTime(
        month.year,
        month.month + 1,
        0,
      ).day;

      if (days <= 0) {
        return 0;
      }

      return monthlySalary / days;
    }

    if (standardDays <= 0) {
      return 0;
    }

    return monthlySalary / standardDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'calculationMode': calculationMode,
      'monthlySalary': monthlySalary,
      'standardDays': standardDays,
      'normalHoursPerDay': normalHoursPerDay,
      'otRate': otRate,
      'advance': advance,
      'deduction': deduction,
    };
  }

  factory PaymentConfig.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentConfig(
      calculationMode:
          '${json['calculationMode'] ?? 'Fixed Days'}',
      monthlySalary:
          double.tryParse(
                '${json['monthlySalary'] ?? 16200}',
              ) ??
              16200,
      standardDays:
          int.tryParse(
                '${json['standardDays'] ?? 30}',
              ) ??
              30,
      normalHoursPerDay:
          double.tryParse(
                '${json['normalHoursPerDay'] ?? 8}',
              ) ??
              8,
      otRate:
          double.tryParse(
                '${json['otRate'] ?? 67.5}',
              ) ??
              67.5,
      advance:
          double.tryParse(
                '${json['advance'] ?? 0}',
              ) ??
              0,
      deduction:
          double.tryParse(
                '${json['deduction'] ?? 0}',
              ) ??
              0,
    );
  }
}

class WorkerPayApp extends StatelessWidget {
  const WorkerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worker Pay',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
        ),
        inputDecorationTheme:
            const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),
      home: const WorkerPayHome(),
    );
  }
}

class WorkerPayHome extends StatefulWidget {
  const WorkerPayHome({super.key});

  @override
  State<WorkerPayHome> createState() =>
      _WorkerPayHomeState();
}

class _WorkerPayHomeState
    extends State<WorkerPayHome> {
  int selectedTab = 0;

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  final Map<String, AttendanceRecord> records = {};

  PaymentConfig paymentConfig =
      PaymentConfig();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final rawRecords =
          prefs.getString('worker_pay_records');

      final rawConfig =
          prefs.getString('worker_pay_config');

      if (rawRecords != null &&
          rawRecords.isNotEmpty) {
        final decoded =
            jsonDecode(rawRecords);

        if (decoded is Map) {
          records.clear();

          decoded.forEach((key, value) {
            if (value is Map) {
              records['$key'] =
                  AttendanceRecord.fromJson(
                Map<String, dynamic>.from(value),
              );
            }
          });
        }
      }

      if (rawConfig != null &&
          rawConfig.isNotEmpty) {
        final decoded =
            jsonDecode(rawConfig);

        if (decoded is Map) {
          paymentConfig =
              PaymentConfig.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (_) {
      // If old/corrupt local data exists,
      // app will simply use default data.
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final recordMap =
          <String, dynamic>{};

      records.forEach((key, value) {
        recordMap[key] = value.toJson();
      });

      await prefs.setString(
        'worker_pay_records',
        jsonEncode(recordMap),
      );

      await prefs.setString(
        'worker_pay_config',
        jsonEncode(
          paymentConfig.toJson(),
        ),
      );
    } catch (_) {
      // App remains usable even if storage
      // temporarily fails.
    }
  }

  Future<void> _openAttendance(
    DateTime date,
  ) async {
    final result =
        await showModalBottomSheet<
            AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AttendanceEntrySheet(
          date: date,
          existing:
              records[dateKey(date)],
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      records[dateKey(date)] = result;
    });

    await _saveData();
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        1,
      );
    });
  }

  void _currentMonth() {
    final now = DateTime.now();

    setState(() {
      selectedMonth = DateTime(
        now.year,
        now.month,
        1,
      );
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PaymentSettingsSheet(
          config: paymentConfig,
          onSave: (config) async {
            setState(() {
              paymentConfig = config;
            });

            await _saveData();
          },
        );
      },
    );
  }

  void _openMonthFromYear(
    DateTime month,
  ) {
    setState(() {
      selectedMonth = DateTime(
        month.year,
        month.month,
        1,
      );
      selectedTab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: appBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            MonthScreen(
              month: selectedMonth,
              records: records,
              config: paymentConfig,
              onDateTap: _openAttendance,
              onPrevious: _previousMonth,
              onNext: _nextMonth,
              onCurrent: _currentMonth,
              onSettings: _openSettings,
            ),
            YearScreen(
              year: selectedMonth.year,
              records: records,
              onMonthTap: _openMonthFromYear,
            ),
            SummaryScreen(
              month: selectedMonth,
              records: records,
              config: paymentConfig,
              onSettings: _openSettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          WorkerBottomNavigation(
        selectedIndex: selectedTab,
        onChanged: (index) {
          setState(() {
            selectedTab = index;
          });
        },
      ),
    );
  }
}

class MonthScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, AttendanceRecord> records;
  final PaymentConfig config;
  final Future<void> Function(DateTime) onDateTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;
  final VoidCallback onSettings;

  const MonthScreen({
    super.key,
    required this.month,
    required this.records,
    required this.config,
    required this.onDateTap,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onSettings,
  });

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

  String keyFor(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  double hours(String value) {
    String clean =
        value.toUpperCase().trim();

    clean = clean.replaceAll('H', '');

    return double.tryParse(clean) ?? 0;
  }

  bool isThisMonth(String key) {
    final parts = key.split('-');

    if (parts.length != 3) {
      return false;
    }

    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);

    return y == month.year &&
        m == month.month;
  }

  List<AttendanceRecord>
      get monthRecords {
    return records.entries
        .where(
          (e) => isThisMonth(e.key),
        )
        .map((e) => e.value)
        .toList();
  }

  double get totalHours {
    double total = 0;

    for (final record in monthRecords) {
      total += hours(record.normalHours);
    }

    return total;
  }

  double get totalOt {
    double total = 0;

    for (final record in monthRecords) {
      total += hours(record.otHours);
    }

    return total;
  }

  int get presentCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.present,
        )
        .length;
  }

  int get halfDayCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.halfDay,
        )
        .length;
  }

  int get absentCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.absent,
        )
        .length;
  }

  double get basicPayment {
    final daily =
        config.dailyWageForMonth(month);

    double result = 0;

    for (final record in monthRecords) {
      if (record.status ==
          AttendanceStatus.present) {
        result += daily;
      } else if (record.status ==
          AttendanceStatus.halfDay) {
        result += daily * 0.5;
      }
    }

    return result;
  }

  double get otPayment {
    return totalOt * config.otRate;
  }

  double get netPayment {
    return basicPayment +
        otPayment -
        config.advance -
        config.deduction;
  }

  String money(double value) {
    return '₹${value.round()}';
  }

  String hoursText(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}H';
    }

    return '${value.toStringAsFixed(1)}H';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        28,
        30,
        28,
        28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _topHeader(),
          const SizedBox(height: 34),
          _monthSelector(),
          const SizedBox(height: 28),
          _statistics(),
          const SizedBox(height: 32),
          _calendar(),
          const SizedBox(height: 20),
          _legend(),
          const SizedBox(height: 28),
          _monthlySummary(),
        ],
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Worker Pay',
            style: TextStyle(
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w400,
              color: textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(
            Icons.settings_outlined,
            size: 37,
            color: Color(0xFF4D565F),
          ),
        ),
      ],
    );
  }

  Widget _monthSelector() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: primary,
        borderRadius:
            BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(
              Icons.chevron_left,
              size: 42,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onCurrent,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    '${monthNames[month.month - 1]} ${month.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tap for current month',
                    style: TextStyle(
                      color: Color(0xFFB7D6E4),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(
              Icons.chevron_right,
              size: 42,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statistics() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.access_time_outlined,
            title: 'Hours',
            value: hoursText(totalHours),
            color: primary,
            iconBackground:
                const Color(0xFFE5F0F5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatCard(
            icon: Icons.timer_outlined,
            title: 'OT',
            value: hoursText(totalOt),
            color: halfDayColor,
            iconBackground:
                const Color(0xFFFFEEE8),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatCard(
            icon: Icons.currency_rupee,
            title: 'Payment',
            value: money(netPayment),
            color: presentColor,
            iconBackground:
                const Color(0xFFE7F4EC),
          ),
        ),
      ],
    );
  }

  Widget _calendar() {
    final firstDay =
        DateTime(
      month.year,
      month.month,
      1,
    );

    final days =
        DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    final offset =
        firstDay.weekday % 7;

    final totalCells =
        ((offset + days + 6) ~/ 7) * 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        26,
        15,
        22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(36),
        border: Border.all(
          color: border,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              WeekDay(text: 'SUN'),
              WeekDay(text: 'MON'),
              WeekDay(text: 'TUE'),
              WeekDay(text: 'WED'),
              WeekDay(text: 'THU'),
              WeekDay(text: 'FRI'),
              WeekDay(text: 'SAT'),
            ],
          ),
          const SizedBox(height: 13),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 78,
              mainAxisSpacing: 9,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final day =
                  index - offset + 1;

              if (day < 1 ||
                  day > days) {
                return const SizedBox();
              }

              final date = DateTime(
                month.year,
                month.month,
                day,
              );

              return CalendarDay(
                date: date,
                record:
                    records[keyFor(date)],
                isToday:
                    _isToday(date),
                onTap: () {
                  onDateTap(date);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _legend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 17,
      runSpacing: 9,
      children: const [
        LegendItem(
          color: presentColor,
          text: 'Present',
        ),
        LegendItem(
          color: halfDayColor,
          text: 'Half Day',
        ),
        LegendItem(
          color: absentColor,
          text: 'Absent',
        ),
        LegendItem(
          color: holidayColor,
          text: 'Holiday',
        ),
        LegendItem(
          color: otColor,
          text: 'OT',
        ),
      ],
    );
  }

  Widget _monthlySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        30,
        26,
        30,
        28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(32),
        border: Border.all(
          color: border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Working Hours: ${hoursText(totalHours)}',
            style: const TextStyle(
              fontSize: 17,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'OT Hours: ${hoursText(totalOt)}',
            style: const TextStyle(
              fontSize: 17,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color iconBackground;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color: border,
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekDay extends StatelessWidget {
  final String text;

  const WeekDay({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

class CalendarDay extends StatelessWidget {
  final DateTime date;
  final AttendanceRecord? record;
  final bool isToday;
  final VoidCallback onTap;

  const CalendarDay({
    super.key,
    required this.date,
    required this.record,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor =
        const Color(0xFFC7D2DE);

    Color background =
        const Color(0xFFF8FAFC);

    Color textColor = textDark;

    if (record != null) {
      switch (record!.status) {
        case AttendanceStatus.present:
          borderColor = presentColor;
          background =
              const Color(0xFFF0F8F3);
          textColor = presentColor;
          break;

        case AttendanceStatus.halfDay:
          borderColor = halfDayColor;
          background =
              const Color(0xFFFFF4EF);
          textColor = halfDayColor;
          break;

        case AttendanceStatus.absent:
          borderColor = absentColor;
          background =
              const Color(0xFFFFEFF0);
          textColor = absentColor;
          break;

        case AttendanceStatus.leave:
          borderColor = leaveColor;
          background =
              const Color(0xFFFFF9E6);
          textColor = leaveColor;
          break;

        case AttendanceStatus.holiday:
          borderColor = holidayColor;
          background =
              const Color(0xFFF5EFFF);
          textColor = holidayColor;
          break;
      }
    } else if (isToday) {
      borderColor = primary;
      background =
          const Color(0xFFEAF4F8);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          7,
          6,
          6,
          5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isToday ? 2.4 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (record == null)
              const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 23,
                    color:
                        Color(0xFFB5C4D3),
                  ),
                ),
              )
            else
              _recordText(textColor),
          ],
        ),
      ),
    );
  }

  Widget _recordText(Color color) {
    String first = '';
    String? second;

    switch (record!.status) {
      case AttendanceStatus.present:
        first = record!.normalHours;

        if (record!.otHours.trim() != '0H' &&
            record!.otHours.trim() != '0') {
          second =
              'OT ${record!.otHours}';
        }
        break;

      case AttendanceStatus.halfDay:
        first = 'Half';
        break;

      case AttendanceStatus.absent:
        first = 'Absent';
        break;

      case AttendanceStatus.leave:
        first = 'Leave';
        break;

      case AttendanceStatus.holiday:
        first = 'Holiday';
        break;
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          first,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (second != null)
          Text(
            second!,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: otColor,
            ),
          ),
      ],
    );
  }
}
class AttendanceEntrySheet
    extends StatefulWidget {
  final DateTime date;
  final AttendanceRecord? existing;

  const AttendanceEntrySheet({
    super.key,
    required this.date,
    this.existing,
  });

  @override
  State<AttendanceEntrySheet> createState() =>
      _AttendanceEntrySheetState();
}

class _AttendanceEntrySheetState
    extends State<AttendanceEntrySheet> {
  late AttendanceStatus status;

  late TextEditingController normalController;
  late TextEditingController otController;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    final old = widget.existing;

    status =
        old?.status ??
        AttendanceStatus.present;

    normalController =
        TextEditingController(
      text: old?.normalHours ?? '8H',
    );

    otController =
        TextEditingController(
      text: old?.otHours ?? '0H',
    );

    noteController =
        TextEditingController(
      text: old?.note ?? '',
    );
  }

  @override
  void dispose() {
    normalController.dispose();
    otController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String dateText() {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    const months = [
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

    return '${weekdays[widget.date.weekday - 1]}, '
        '${widget.date.day} '
        '${months[widget.date.month - 1]} '
        '${widget.date.year}';
  }

  void setNormal(String value) {
    setState(() {
      normalController.text = value;
      normalController.selection =
          TextSelection.collapsed(
        offset: normalController.text.length,
      );
    });
  }

  void setOt(String value) {
    setState(() {
      otController.text = value;
      otController.selection =
          TextSelection.collapsed(
        offset: otController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    final height =
        MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.94,
      padding: EdgeInsets.fromLTRB(
        28,
        12,
        28,
        18 + keyboard,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4FA),
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 6,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFB7C4D0),
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          _header(),
          const SizedBox(height: 25),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Status'),
                  const SizedBox(height: 12),
                  _statusRows(),
                  const SizedBox(height: 27),
                  _sectionTitle(
                    'Normal Working Hours',
                  ),
                  const SizedBox(height: 11),
                  _hourInput(
                    normalController,
                  ),
                  const SizedBox(height: 11),
                  _quickButtons(
                    values: const [
                      '4H',
                      '8H',
                      '10H',
                    ],
                    selected:
                        normalController.text,
                    onTap: setNormal,
                  ),
                  const SizedBox(height: 27),
                  _sectionTitle(
                    'Overtime (OT) Hours',
                  ),
                  const SizedBox(height: 11),
                  _hourInput(
                    otController,
                  ),
                  const SizedBox(height: 11),
                  _quickButtons(
                    values: const [
                      '0H',
                      '4H',
                      '16H',
                    ],
                    selected:
                        otController.text,
                    onTap: setOt,
                  ),
                  const SizedBox(height: 27),
                  _sectionTitle('Note'),
                  const SizedBox(height: 11),
                  _noteInput(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color:
                const Color(0xFFDCEEF5),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.edit_calendar_outlined,
            color: primary,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Entry',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateText(),
                style: const TextStyle(
                  fontSize: 16,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close,
            size: 34,
            color: Color(0xFF4A545D),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w400,
        color: textDark,
      ),
    );
  }

  Widget _statusRows() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statusButton(
                AttendanceStatus.present,
                'Present',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statusButton(
                AttendanceStatus.halfDay,
                'Half Day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statusButton(
                AttendanceStatus.absent,
                'Absent',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statusButton(
                AttendanceStatus.leave,
                'Leave',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statusButton(
                AttendanceStatus.holiday,
                'Holiday',
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(
    AttendanceStatus value,
  ) {
    switch (value) {
      case AttendanceStatus.present:
        return presentColor;
      case AttendanceStatus.halfDay:
        return halfDayColor;
      case AttendanceStatus.absent:
        return absentColor;
      case AttendanceStatus.leave:
        return leaveColor;
      case AttendanceStatus.holiday:
        return holidayColor;
    }
  }

  Widget _statusButton(
    AttendanceStatus value,
    String text,
  ) {
    final selected =
        status == value;

    final color =
        _statusColor(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          status = value;
        });
      },
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.07)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color:
                selected ? color : border,
            width:
                selected ? 2 : 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (selected)
              Padding(
                padding:
                    const EdgeInsets.only(
                  right: 7,
                ),
                child: Icon(
                  Icons.check,
                  size: 21,
                  color: color,
                ),
              ),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                  color: selected
                      ? color
                      : const Color(
                          0xFF4F5B67,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hourInput(
    TextEditingController controller,
  ) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF3FF),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFB7C8D8),
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        style: const TextStyle(
          fontSize: 29,
          color: primary,
        ),
        decoration:
            const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 29,
          ),
        ),
      ),
    );
  }

  Widget _quickButtons({
    required List<String> values,
    required String selected,
    required ValueChanged<String>
        onTap,
  }) {
    return Row(
      children: values.map((value) {
        final active =
            selected.trim().toUpperCase() ==
            value;

        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(
              right:
                  value == values.last
                      ? 0
                      : 12,
            ),
            child: GestureDetector(
              onTap: () {
                onTap(value);
              },
              child: Container(
                height: 62,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: active
                      ? const Color(
                          0xFFDCE6EF,
                        )
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                  border: Border.all(
                    color: active
                        ? primary
                        : border,
                    width:
                        active ? 2 : 1.3,
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w500,
                    color: active
                        ? primary
                        : const Color(
                            0xFF4F5B67,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _noteInput() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: border,
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: noteController,
        maxLines: 4,
        decoration:
            const InputDecoration(
          border: InputBorder.none,
          hintText: 'Optional note...',
          hintStyle: TextStyle(
            color: Color(0xFF8B949D),
            fontSize: 18,
          ),
          prefixIcon: Icon(
            Icons.notes_outlined,
            color: Color(0xFF56636D),
          ),
          contentPadding:
              EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(
            context,
            AttendanceRecord(
              status: status,
              normalHours:
                  normalController.text
                          .trim()
                          .isEmpty
                      ? '0H'
                      : normalController.text
                          .trim(),
              otHours:
                  otController.text
                          .trim()
                          .isEmpty
                      ? '0H'
                      : otController.text
                          .trim(),
              note:
                  noteController.text
                      .trim(),
            ),
          );
        },
        icon: const Icon(
          Icons.check,
          size: 27,
        ),
        label: const Text(
          'Save Attendance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(32),
          ),
        ),
      ),
    );
  }
}

class PaymentSettingsSheet
    extends StatefulWidget {
  final PaymentConfig config;
  final Future<void> Function(
    PaymentConfig,
  ) onSave;

  const PaymentSettingsSheet({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<PaymentSettingsSheet> createState() =>
      _PaymentSettingsSheetState();
}

class _PaymentSettingsSheetState
    extends State<PaymentSettingsSheet> {
  late String mode;

  late TextEditingController salary;
  late TextEditingController days;
  late TextEditingController hours;
  late TextEditingController otRate;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    mode = widget.config.calculationMode;

    salary = TextEditingController(
      text:
          widget.config.monthlySalary
              .toStringAsFixed(0),
    );

    days = TextEditingController(
      text:
          widget.config.standardDays
              .toString(),
    );

    hours = TextEditingController(
      text:
          widget.config.normalHoursPerDay
              .toString(),
    );

    otRate = TextEditingController(
      text:
          widget.config.otRate
              .toString(),
    );

    advance = TextEditingController(
      text:
          widget.config.advance
              .toStringAsFixed(0),
    );

    deduction = TextEditingController(
      text:
          widget.config.deduction
              .toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    salary.dispose();
    days.dispose();
    hours.dispose();
    otRate.dispose();
    advance.dispose();
    deduction.dispose();
    super.dispose();
  }

  double toDouble(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  int toInt(
    TextEditingController controller,
  ) {
    return int.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  double get dailyWage {
    final salaryValue =
        toDouble(salary);

    final dayValue =
        toInt(days);

    if (dayValue <= 0) {
      return 0;
    }

    return salaryValue / dayValue;
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              0.94,
      padding: EdgeInsets.fromLTRB(
        28,
        12,
        28,
        18 + keyboard,
      ),
      decoration: const BoxDecoration(
        color: appBackground,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 6,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFB7C4D0),
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Payment Configuration',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _label(
                    'Calculation Mode',
                  ),
                  const SizedBox(height: 10),
                  _modeSelector(),
                  const SizedBox(height: 22),
                  _label('Monthly Salary'),
                  _field(
                    salary,
                    prefixText: '₹',
                  ),
                  const SizedBox(height: 17),
                  _label(
                    'Standard Working Days per Month',
                  ),
                  _field(
                    days,
                    prefixIcon:
                        Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 17),
                  _label(
                    'Normal Working Hours per Day',
                  ),
                  _field(
                    hours,
                    prefixIcon:
                        Icons.access_time_outlined,
                    suffixText: 'H',
                  ),
                  const SizedBox(height: 17),
                  _label(
                    'Overtime OT Rate per Hour',
                  ),
                  _field(
                    otRate,
                    prefixIcon:
                        Icons.timer_outlined,
                    suffixText: '₹',
                  ),
                  const SizedBox(height: 17),
                  _label('Daily Wage'),
                  _readonlyField(
                    '₹${dailyWage.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 17),
                  _label('Optional Advance'),
                  _field(
                    advance,
                    prefixIcon:
                        Icons.arrow_downward,
                    suffixText: '₹',
                  ),
                  const SizedBox(height: 17),
                  _label('Optional Deduction'),
                  _field(
                    deduction,
                    prefixIcon:
                        Icons.remove_circle_outline,
                    suffixText: '₹',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () async {
                final newConfig =
                    PaymentConfig(
                  calculationMode: mode,
                  monthlySalary:
                      toDouble(salary),
                  standardDays:
                      toInt(days),
                  normalHoursPerDay:
                      toDouble(hours),
                  otRate:
                      toDouble(otRate),
                  advance:
                      toDouble(advance),
                  deduction:
                      toDouble(deduction),
                );

                await widget.onSave(
                  newConfig,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(
                Icons.save_outlined,
                size: 25,
              ),
              label: const Text(
                'Save Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          color: textDark,
        ),
      ),
    );
  }

  Widget _modeSelector() {
    const modes = [
      'Fixed Days',
      'Month Days',
      'Daily Wage',
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: modes.map((item) {
          final active =
              mode == item;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  mode = item;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? primary
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w500,
                    color: active
                        ? Colors.white
                        : const Color(
                            0xFF4F5B67,
                          ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    String? prefixText,
    String? suffixText,
    IconData? prefixIcon,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon:
              prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      color: primary,
                    ),
          prefixText:
              prefixText == null
                  ? null
                  : '$prefixText ',
          suffixText:
              suffixText == null
                  ? null
                  : ' $suffixText',
          prefixStyle:
              const TextStyle(
            fontSize: 27,
            color: primary,
          ),
          suffixStyle:
              const TextStyle(
            fontSize: 18,
            color: textMuted,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      height: 70,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF8A949C),
        ),
      ),
    );
  }
}

class WorkerBottomNavigation
    extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const WorkerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(
        28,
        7,
        28,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          _item(
            0,
            Icons.calendar_month_outlined,
            'Month',
          ),
          _item(
            1,
            Icons.grid_view_rounded,
            'Year',
          ),
          _item(
            2,
            Icons.insert_chart_outlined,
            'Summary',
          ),
        ],
      ),
    );
  }

  Widget _item(
    int index,
    IconData icon,
    String text,
  ) {
    final active =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onChanged(index);
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 47,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE0EDF4)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(27),
              ),
              child: Icon(
                icon,
                size: 29,
                color: const Color(
                  0xFF43505A,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF444B52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class YearScreen extends StatelessWidget {
  final int year;
  final Map<String, AttendanceRecord> records;
  final ValueChanged<DateTime> onMonthTap;

  const YearScreen({
    super.key,
    required this.year,
    required this.records,
    required this.onMonthTap,
  });

  static const List<String> months = [
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

  String keyFor(
    int year,
    int month,
    int day,
  ) {
    return '$year-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  List<AttendanceRecord> monthRecords(
    int month,
  ) {
    final result =
        <AttendanceRecord>[];

    records.forEach((key, value) {
      final parts = key.split('-');

      if (parts.length != 3) {
        return;
      }

      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);

      if (y == year && m == month) {
        result.add(value);
      }
    });

    return result;
  }

  double number(String value) {
    String clean =
        value.toUpperCase().trim();

    clean = clean.replaceAll('H', '');

    return double.tryParse(clean) ?? 0;
  }

  double otTotal(
    List<AttendanceRecord> list,
  ) {
    double total = 0;

    for (final item in list) {
      total += number(item.otHours);
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        28,
        30,
        28,
        28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Year Overview',
            style: TextStyle(
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w400,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$year  ·  Monthly Attendance',
            style: const TextStyle(
              fontSize: 18,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: 265,
            ),
            itemBuilder: (context, index) {
              final month =
                  index + 1;

              final list =
                  monthRecords(month);

              final present = list
                  .where(
                    (e) =>
                        e.status ==
                        AttendanceStatus.present,
                  )
                  .length;

              final absent = list
                  .where(
                    (e) =>
                        e.status ==
                        AttendanceStatus.absent,
                  )
                  .length;

              final half = list
                  .where(
                    (e) =>
                        e.status ==
                        AttendanceStatus.halfDay,
                  )
                  .length;

              final ot =
                  otTotal(list);

              return GestureDetector(
                onTap: () {
                  onMonthTap(
                    DateTime(year, month, 1),
                  );
                },
                child: _monthCard(
                  monthName: months[index],
                  present: present,
                  absent: absent,
                  halfDay: half,
                  ot: ot,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _monthCard({
    required String monthName,
    required int present,
    required int absent,
    required int halfDay,
    required double ot,
  }) {
    final otText =
        ot == ot.roundToDouble()
            ? '${ot.toInt()}H'
            : '${ot.toStringAsFixed(1)}H';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        27,
        27,
        22,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(32),
        border: Border.all(
          color: border,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 28,
                color: Color(0xFFB6C2CD),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            '2026',
            style: TextStyle(
              fontSize: 15,
              color: textMuted,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _miniStat(
                'P',
                present.toString(),
                presentColor,
              ),
              const SizedBox(width: 17),
              _miniStat(
                'A',
                absent.toString(),
                absentColor,
              ),
              const SizedBox(width: 17),
              _miniStat(
                'H',
                halfDay.toString(),
                halfDayColor,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 20,
                color: otColor,
              ),
              const SizedBox(width: 7),
              Text(
                'OT $otText',
                style: const TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: textDark,
          ),
        ),
      ],
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, AttendanceRecord> records;
  final PaymentConfig config;
  final VoidCallback onSettings;

  const SummaryScreen({
    super.key,
    required this.month,
    required this.records,
    required this.config,
    required this.onSettings,
  });

  String keyFor(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  double number(String value) {
    String clean =
        value.toUpperCase().trim();

    clean = clean.replaceAll('H', '');

    return double.tryParse(clean) ?? 0;
  }

  List<AttendanceRecord> get monthRecords {
    final list =
        <AttendanceRecord>[];

    records.forEach((key, value) {
      final parts = key.split('-');

      if (parts.length != 3) {
        return;
      }

      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);

      if (y == month.year &&
          m == month.month) {
        list.add(value);
      }
    });

    return list;
  }

  int get presentCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.present,
        )
        .length;
  }

  int get absentCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.absent,
        )
        .length;
  }

  int get halfDayCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.halfDay,
        )
        .length;
  }

  int get holidayCount {
    return monthRecords
        .where(
          (e) =>
              e.status ==
              AttendanceStatus.holiday,
        )
        .length;
  }

  double get totalHours {
    double total = 0;

    for (final item in monthRecords) {
      total += number(item.normalHours);
    }

    return total;
  }

  double get totalOt {
    double total = 0;

    for (final item in monthRecords) {
      total += number(item.otHours);
    }

    return total;
  }

  double get dailyWage {
    return config.dailyWageForMonth(
      month,
    );
  }

  double get basicPayment {
    double total = 0;

    for (final item in monthRecords) {
      if (item.status ==
          AttendanceStatus.present) {
        total += dailyWage;
      } else if (item.status ==
          AttendanceStatus.halfDay) {
        total += dailyWage * 0.5;
      }
    }

    return total;
  }

  double get otPayment {
    return totalOt * config.otRate;
  }

  double get netPayment {
    return basicPayment +
        otPayment -
        config.advance -
        config.deduction;
  }

  String money(double value) {
    return '₹${value.round()}';
  }

  String hoursText(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} H';
    }

    return '${value.toStringAsFixed(1)} H';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        28,
        30,
        28,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 12),
          Text(
            '${_monthName(month.month)} ${month.year}',
            style: const TextStyle(
              fontSize: 18,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 30),
          _paymentHero(),
          const SizedBox(height: 24),
          _attendanceCard(),
          const SizedBox(height: 24),
          _workingTimeCard(),
          const SizedBox(height: 24),
          _paymentCard(),
        ],
      ),
    );
  }

  String _monthName(int monthNumber) {
    const names = [
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

    return names[monthNumber - 1];
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w400,
              color: textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(
            Icons.settings_outlined,
            size: 37,
            color: Color(0xFF4D565F),
          ),
        ),
      ],
    );
  }

  Widget _paymentHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        38,
        35,
        38,
        30,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius:
            BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Net Payment',
            style: TextStyle(
              color: Color(0xFFC6DBE5),
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            money(netPayment),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _heroMini(
                  'Hours',
                  hoursText(totalHours),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _heroMini(
                  'OT',
                  hoursText(totalOt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini(
    String title,
    String value,
  ) {
    return Container(
      height: 56,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFF2C7898),
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD2E2EA),
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _cardTitle(
            Icons.edit_calendar_outlined,
            'Attendance',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AttendanceTile(
                  icon: Icons.check_circle_outline,
                  label: 'Present',
                  value:
                      presentCount.toString(),
                  color: presentColor,
                  background:
                      const Color(0xFFF0F8F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AttendanceTile(
                  icon: Icons.cancel_outlined,
                  label: 'Absent',
                  value:
                      absentCount.toString(),
                  color: absentColor,
                  background:
                      const Color(0xFFFFF0F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AttendanceTile(
                  icon:
                      Icons
                          .timelapse_outlined,
                  label: 'Half Day',
                  value:
                      halfDayCount.toString(),
                  color: halfDayColor,
                  background:
                      const Color(0xFFFFF5F0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AttendanceTile(
                  icon:
                      Icons
                          .celebration_outlined,
                  label: 'Holiday',
                  value:
                      holidayCount.toString(),
                  color: holidayColor,
                  background:
                      const Color(0xFFF5F0FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workingTimeCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _cardTitle(
            Icons.access_time_outlined,
            'Working Time',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TimeTile(
                  title: 'Working Hours',
                  value:
                      hoursText(totalHours),
                  color: primary,
                  background:
                      const Color(0xFFF0F7FA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TimeTile(
                  title: 'OT Hours',
                  value:
                      hoursText(totalOt),
                  color: halfDayColor,
                  background:
                      const Color(0xFFFFF5F0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _cardTitle(
            Icons.currency_rupee,
            'Payment',
          ),
          const SizedBox(height: 22),
          _paymentRow(
            'Monthly Salary',
            money(config.monthlySalary),
          ),
          _paymentRow(
            'Daily Wage',
            money(dailyWage),
          ),
          _paymentRow(
            'OT Rate',
            '₹${config.otRate.toStringAsFixed(2)}/H',
          ),
          const Divider(
            height: 28,
            color: Color(0xFFD0D6DC),
          ),
          _paymentRow(
            'Basic Payment',
            money(basicPayment),
            dark: true,
          ),
          _paymentRow(
            'OT Payment',
            money(otPayment),
            dark: true,
          ),
          _paymentRow(
            'Advance',
            '- ${money(config.advance)}',
            valueColor: absentColor,
          ),
          _paymentRow(
            'Deduction',
            '- ${money(config.deduction)}',
            valueColor: absentColor,
          ),
          const Divider(
            height: 28,
            color: Color(0xFFD0D6DC),
          ),
          Row(
            children: [
              const Text(
                'Net Payment',
                style: TextStyle(
                  fontSize: 22,
                  color: textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                money(netPayment),
                style: const TextStyle(
                  fontSize: 27,
                  color: presentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String title,
    String value, {
    bool dark = false,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: dark
                    ? textDark
                    : textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  dark
                      ? FontWeight.w500
                      : FontWeight.w400,
              color:
                  valueColor ??
                  (dark
                      ? textDark
                      : textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        30,
        27,
        30,
        28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(32),
        border: Border.all(
          color: border,
          width: 1.3,
        ),
      ),
      child: child,
    );
  }

  Widget _cardTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primary,
          size: 30,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
      ],
    );
  }
}

class AttendanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const AttendanceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 17,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TimeTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color background;

  const TimeTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        17,
        15,
        15,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              color: textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
