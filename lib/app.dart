import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkerPayApp());
}

// ============================================================
// COLORS
// ============================================================

class AppColors {
  static const background = Color(0xFFF0F7FF);
  static const primary = Color(0xFF086B8A);
  static const primaryDark = Color(0xFF075B76);
  static const primaryLight = Color(0xFFDDF2F8);

  static const card = Colors.white;
  static const border = Color(0xFFB9C9D8);

  static const text = Color(0xFF102033);
  static const secondaryText = Color(0xFF66727D);
  static const muted = Color(0xFFAEBECD);

  static const present = Color(0xFF159447);
  static const presentBg = Color(0xFFEAF7EF);

  static const halfDay = Color(0xFFC95A16);
  static const halfDayBg = Color(0xFFFFF1E9);

  static const absent = Color(0xFFC52632);
  static const absentBg = Color(0xFFFFEEEE);

  static const leave = Color(0xFFD19A00);
  static const leaveBg = Color(0xFFFFF8DD);

  static const holiday = Color(0xFF7136C7);
  static const holidayBg = Color(0xFFF4EEFF);

  static const ot = Color(0xFFD77A00);
  static const otBg = Color(0xFFFFF4E3);
}

// ============================================================
// ENUMS
// ============================================================

enum AttendanceStatus {
  present,
  halfDay,
  absent,
  leave,
  holiday,
}

enum CalculationMode {
  fixedDays,
  monthDays,
  dailyWage,
}

// ============================================================
// ATTENDANCE MODEL
// ============================================================

class AttendanceRecord {
  final String dateKey;
  final AttendanceStatus status;
  final double normalHours;
  final double otHours;
  final String note;

  const AttendanceRecord({
    required this.dateKey,
    required this.status,
    required this.normalHours,
    required this.otHours,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'status': status.name,
      'normalHours': normalHours,
      'otHours': otHours,
      'note': note,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString() ?? 'present';

    AttendanceStatus status = AttendanceStatus.present;

    for (final value in AttendanceStatus.values) {
      if (value.name == statusName) {
        status = value;
        break;
      }
    }

    return AttendanceRecord(
      dateKey: json['dateKey']?.toString() ?? '',
      status: status,
      normalHours: (json['normalHours'] as num?)?.toDouble() ?? 0,
      otHours: (json['otHours'] as num?)?.toDouble() ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}

// ============================================================
// PAYMENT CONFIG
// ============================================================

class PaymentConfig {
  final CalculationMode mode;
  final double monthlySalary;
  final int standardWorkingDays;
  final double normalWorkingHours;
  final double otRate;
  final double dailyWage;
  final double advance;
  final double deduction;

  const PaymentConfig({
    required this.mode,
    required this.monthlySalary,
    required this.standardWorkingDays,
    required this.normalWorkingHours,
    required this.otRate,
    required this.dailyWage,
    required this.advance,
    required this.deduction,
  });

  factory PaymentConfig.defaults() {
    return const PaymentConfig(
      mode: CalculationMode.fixedDays,
      monthlySalary: 15000,
      standardWorkingDays: 26,
      normalWorkingHours: 8,
      otRate: 100,
      dailyWage: 0,
      advance: 0,
      deduction: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'monthlySalary': monthlySalary,
      'standardWorkingDays': standardWorkingDays,
      'normalWorkingHours': normalWorkingHours,
      'otRate': otRate,
      'dailyWage': dailyWage,
      'advance': advance,
      'deduction': deduction,
    };
  }

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    CalculationMode selectedMode = CalculationMode.fixedDays;

    final modeName = json['mode']?.toString() ?? '';

    for (final value in CalculationMode.values) {
      if (value.name == modeName) {
        selectedMode = value;
        break;
      }
    }

    return PaymentConfig(
      mode: selectedMode,
      monthlySalary:
          (json['monthlySalary'] as num?)?.toDouble() ?? 15000,
      standardWorkingDays:
          (json['standardWorkingDays'] as num?)?.toInt() ?? 26,
      normalWorkingHours:
          (json['normalWorkingHours'] as num?)?.toDouble() ?? 8,
      otRate: (json['otRate'] as num?)?.toDouble() ?? 100,
      dailyWage: (json['dailyWage'] as num?)?.toDouble() ?? 0,
      advance: (json['advance'] as num?)?.toDouble() ?? 0,
      deduction: (json['deduction'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// STORAGE
// ============================================================

class WorkerPayStorage {
  static const String attendanceKey = 'worker_pay_attendance';
  static const String configKey = 'worker_pay_config';

  static Future<Map<String, AttendanceRecord>> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(attendanceKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return {};
      }

      final Map<String, AttendanceRecord> result = {};

      decoded.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] =
              AttendanceRecord.fromJson(Map<String, dynamic>.from(value));
        }
      });

      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAttendance(
    Map<String, AttendanceRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {};

    records.forEach((key, value) {
      data[key] = value.toJson();
    });

    await prefs.setString(attendanceKey, jsonEncode(data));
  }

  static Future<PaymentConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(configKey);

    if (raw == null || raw.isEmpty) {
      return PaymentConfig.defaults();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        return PaymentConfig.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}

    return PaymentConfig.defaults();
  }

  static Future<void> saveConfig(PaymentConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      configKey,
      jsonEncode(config.toJson()),
    );
  }
}

// ============================================================
// APP
// ============================================================

class WorkerPayApp extends StatelessWidget {
  const WorkerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worker Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'sans',
      ),
      home: const WorkerPayHome(),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class WorkerPayHome extends StatefulWidget {
  const WorkerPayHome({super.key});

  @override
  State<WorkerPayHome> createState() => _WorkerPayHomeState();
}

class _WorkerPayHomeState extends State<WorkerPayHome> {
  int selectedTab = 0;

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  Map<String, AttendanceRecord> attendance = {};

  PaymentConfig config = PaymentConfig.defaults();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================================
  // STORAGE
  // ==========================================================

  Future<void> _loadData() async {
    final loadedAttendance =
        await WorkerPayStorage.loadAttendance();

    final loadedConfig =
        await WorkerPayStorage.loadConfig();

    if (!mounted) return;

    setState(() {
      attendance = loadedAttendance;
      config = loadedConfig;
      loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    await WorkerPayStorage.saveAttendance(attendance);
  }

  Future<void> _saveConfig() async {
    await WorkerPayStorage.saveConfig(config);
  }

  // ==========================================================
  // DATE HELPERS
  // ==========================================================

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  AttendanceRecord? _recordFor(DateTime date) {
    return attendance[_dateKey(date)];
  }

  List<AttendanceRecord> _monthRecords(DateTime month) {
    return attendance.values.where((record) {
      final parts = record.dateKey.split('-');

      if (parts.length != 3) return false;

      final year = int.tryParse(parts[0]);
      final monthValue = int.tryParse(parts[1]);

      return year == month.year && monthValue == month.month;
    }).toList();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // ==========================================================
  // MONTH NAVIGATION
  // ==========================================================

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
    setState(() {
      selectedMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );
    });
  }

  // ==========================================================
  // CALCULATIONS
  // ==========================================================

  double _totalNormalHours([DateTime? month]) {
    final records = _monthRecords(month ?? selectedMonth);

    return records.fold(
      0,
      (sum, record) => sum + record.normalHours,
    );
  }

  double _totalOtHours([DateTime? month]) {
    final records = _monthRecords(month ?? selectedMonth);

    return records.fold(
      0,
      (sum, record) => sum + record.otHours,
    );
  }

  int _countStatus(
    AttendanceStatus status, [
    DateTime? month,
  ]) {
    final records = _monthRecords(month ?? selectedMonth);

    return records.where((r) => r.status == status).length;
  }

  double _dailyWage() {
    if (config.dailyWage > 0) {
      return config.dailyWage;
    }

    final days = config.standardWorkingDays <= 0
        ? 26
        : config.standardWorkingDays;

    return config.monthlySalary / days.toDouble();
  }

  double _basicPayment([DateTime? month]) {
    final targetMonth = month ?? selectedMonth;
    final records = _monthRecords(targetMonth);

    switch (config.mode) {
      case CalculationMode.dailyWage:
        return records
            .where((r) => r.status == AttendanceStatus.present)
            .fold(
              0,
              (sum, record) => sum + _dailyWage(),
            );

      case CalculationMode.monthDays:
        final present = records.where(
          (r) => r.status == AttendanceStatus.present,
        ).length;

        final daysInMonth = DateUtils.getDaysInMonth(
          targetMonth.year,
          targetMonth.month,
        );

        if (daysInMonth <= 0) return 0;

        return config.monthlySalary *
            present.toDouble() /
            daysInMonth.toDouble();

      case CalculationMode.fixedDays:
        final present = records.where(
          (r) => r.status == AttendanceStatus.present,
        ).length;

        final half = records.where(
          (r) => r.status == AttendanceStatus.halfDay,
        ).length;

        final wage = _dailyWage();

        return present * wage + half * wage * 0.5;
    }
  }

  double _otPayment([DateTime? month]) {
    return _totalOtHours(month) * config.otRate;
  }

  double _netPayment([DateTime? month]) {
    return _basicPayment(month) +
        _otPayment(month) -
        config.advance -
        config.deduction;
  }

  // ==========================================================
  // FORMATTING
  // ==========================================================

  String _formatHours(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}H';
    }

    return '${value.toStringAsFixed(1)}H';
  }

  String _money(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  String _monthName(int month) {
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

    return names[month - 1];
  }

  String _shortMonth(int month) {
    const names = [
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

    return names[month - 1];
  }

  String _weekdayShort(int weekday) {
    const names = [
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ];

    return names[weekday];
  }

  String _fullWeekday(DateTime date) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[date.weekday - 1];
  }

  String _dateTitle(DateTime date) {
    return '${_fullWeekday(date)}, '
        '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            _buildMonthScreen(),
            _buildYearScreen(),
            _buildSummaryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // COMMON HEADER
  // ==========================================================

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    bool showSettings = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (showSettings)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _openSettings,
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // MONTH SCREEN
  // ==========================================================

  Widget _buildMonthScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Worker Pay',
            subtitle: 'Attendance & Payment',
            showSettings: true,
          ),

          const SizedBox(height: 18),

          _buildMonthSelector(),

          const SizedBox(height: 14),

          _buildTopStats(),

          const SizedBox(height: 14),

          _buildCalendarCard(),

          const SizedBox(height: 12),

          _buildCalendarLegend(),

          const SizedBox(height: 14),

          _buildMonthlySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _roundIconButton(
                icon: Icons.chevron_left,
                onTap: _previousMonth,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _currentMonth,
                      child: const Text(
                        'Tap for current month',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _roundIconButton(
                icon: Icons.chevron_right,
                onTap: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOP STATS
  // ==========================================================

  Widget _buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: _smallStatCard(
            title: 'Hours',
            value: _formatHours(_totalNormalHours()),
            icon: Icons.access_time_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            title: 'OT',
            value: _formatHours(_totalOtHours()),
            icon: Icons.more_time_rounded,
            color: AppColors.ot,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            title: 'Payment',
            value: _money(_netPayment()),
            icon: Icons.payments_outlined,
            color: AppColors.present,
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CALENDAR
  // ==========================================================

  Widget _buildCalendarCard() {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    // Sunday = 0
    final startingOffset = firstDay.weekday % 7;

    final totalNeeded = startingOffset + daysInMonth;

    final rows = (totalNeeded / 7).ceil();

    final totalCells = rows * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              7,
              (index) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekdayShort(index),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 76,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemBuilder: (context, index) {
              if (index < startingOffset ||
                  index >= startingOffset + daysInMonth) {
                return const SizedBox();
              }

              final day = index - startingOffset + 1;

              final date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                day,
              );

              return _calendarDateCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _calendarDateCell(DateTime date) {
    final record = _recordFor(date);

    final today = _sameDate(
      date,
      DateTime.now(),
    );

    Color borderColor = AppColors.border;
    Color background = Colors.white;
    Color numberColor = AppColors.text;

    if (record != null) {
      switch (record.status) {
        case AttendanceStatus.present:
          background = AppColors.presentBg;
          borderColor = AppColors.present;
          numberColor = AppColors.present;
          break;

        case AttendanceStatus.halfDay:
          background = AppColors.halfDayBg;
          borderColor = AppColors.halfDay;
          numberColor = AppColors.halfDay;
          break;

        case AttendanceStatus.absent:
          background = AppColors.absentBg;
          borderColor = AppColors.absent;
          numberColor = AppColors.absent;
          break;

        case AttendanceStatus.leave:
          background = AppColors.leaveBg;
          borderColor = AppColors.leave;
          numberColor = AppColors.leave;
          break;

        case AttendanceStatus.holiday:
          background = AppColors.holidayBg;
          borderColor = AppColors.holiday;
          numberColor = AppColors.holiday;
          break;
      }
    }

    if (today && record == null) {
      borderColor = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openAttendanceEntry(date),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: today ? 1.6 : 1,
            ),
          ),
          child: record == null
              ? Column(
                  children: [
                    Text(
                      '${
                        date.day
                      }',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: numberColor,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                  ],
                )
              : _calendarRecordInfo(
                  date,
                  record,
                  numberColor,
                ),
        ),
      ),
    );
  }

  Widget _calendarRecordInfo(
    DateTime date,
    AttendanceRecord record,
    Color numberColor,
  ) {
    String firstLine = '';
    Color firstColor = numberColor;

    switch (record.status) {
      case AttendanceStatus.present:
        firstLine = _formatHours(record.normalHours);
        firstColor = AppColors.present;
        break;

      case AttendanceStatus.halfDay:
        firstLine = 'Half';
        firstColor = AppColors.halfDay;
        break;

      case AttendanceStatus.absent:
        firstLine = 'Absent';
        firstColor = AppColors.absent;
        break;

      case AttendanceStatus.leave:
        firstLine = 'Leave';
        firstColor = AppColors.leave;
        break;

      case AttendanceStatus.holiday:
        firstLine = 'Holiday';
        firstColor = AppColors.holiday;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: numberColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          firstLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: firstColor,
          ),
        ),

        // IMPORTANT:
        // Normal hours + OT are BOTH displayed.
        if (record.otHours > 0) ...[
          const SizedBox(height: 1),
          Text(
            'OT ${_formatHours(record.otHours)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.ot,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // LEGEND
  // ==========================================================

  Widget _buildCalendarLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendDot(
          color: AppColors.present,
          text: 'Present',
        ),
        _LegendDot(
          color: AppColors.halfDay,
          text: 'Half Day',
        ),
        _LegendDot(
          color: AppColors.absent,
          text: 'Absent',
        ),
        _LegendDot(
          color: AppColors.leave,
          text: 'Leave',
        ),
        _LegendDot(
          color: AppColors.holiday,
          text: 'Holiday',
        ),
        _LegendDot(
          color: AppColors.ot,
          text: 'OT',
        ),
      ],
    );
  }

  // ==========================================================
  // MONTHLY SUMMARY
  // ==========================================================

  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _summaryMini(
                  'Present',
                  '${_countStatus(AttendanceStatus.present)}',
                  AppColors.present,
                ),
              ),
              Expanded(
                child: _summaryMini(
                  'Half Day',
                  '${_countStatus(AttendanceStatus.halfDay)}',
                  AppColors.halfDay,
                ),
              ),
              Expanded(
                child: _summaryMini(
                  'Absent',
                  '${_countStatus(AttendanceStatus.absent)}',
                  AppColors.absent,
                ),
              ),
              Expanded(
                child: _summaryMini(
                  'OT',
                  _formatHours(_totalOtHours()),
                  AppColors.ot,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMini(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ATTENDANCE ENTRY
  // ==========================================================

  Future<void> _openAttendanceEntry(DateTime date) async {
    final existing = _recordFor(date);

    final result = await showModalBottomSheet<AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AttendanceEntrySheet(
          date: date,
          existing: existing,
          defaultNormalHours: config.normalWorkingHours,
        );
      },
    );

    if (result == null) return;

    setState(() {
      attendance[result.dateKey] = result;
    });

    await _saveAttendance();
  }

  // ==========================================================
  // YEAR SCREEN
  // ==========================================================

  Widget _buildYearScreen() {
    final year = selectedMonth.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Year Overview',
            subtitle: '$year · Monthly Attendance',
          ),

          const SizedBox(height: 18),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final month = DateTime(year, index + 1, 1);

              return _yearMonthCard(month);
            },
          ),
        ],
      ),
    );
  }

  Widget _yearMonthCard(DateTime month) {
    final present = _countStatus(
      AttendanceStatus.present,
      month,
    );

    final absent = _countStatus(
      AttendanceStatus.absent,
      month,
    );

    final half = _countStatus(
      AttendanceStatus.halfDay,
      month,
    );

    final ot = _totalOtHours(month);

    final selected = month.year == selectedMonth.year &&
        month.month == selectedMonth.month;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            selectedMonth = month;
            selectedTab = 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _monthName(month.month),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  _yearSmall(
                    'P',
                    '$present',
                    AppColors.present,
                  ),
                  _yearSmall(
                    'A',
                    '$absent',
                    AppColors.absent,
                  ),
                  _yearSmall(
                    'H',
                    '$half',
                    AppColors.halfDay,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'OT ${_formatHours(ot)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yearSmall(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUMMARY SCREEN
  // ==========================================================

  Widget _buildSummaryScreen() {
    final monthTitle =
        '${_monthName(selectedMonth.month)} ${selectedMonth.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Monthly Summary',
            subtitle: monthTitle,
          ),

          const SizedBox(height: 18),

          _buildPaymentHero(),

          const SizedBox(height: 14),

          _buildSummaryAttendance(),

          const SizedBox(height: 14),

          _buildWorkingTime(),

          const SizedBox(height: 14),

          _buildPaymentBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPaymentHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Net Payment',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(_netPayment()),
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroMini(
                  'Hours',
                  _formatHours(_totalNormalHours()),
                ),
              ),
              Expanded(
                child: _heroMini(
                  'OT',
                  _formatHours(_totalOtHours()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAttendance() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Attendance'),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _attendanceCountTile(
                  'Present',
                  _countStatus(
                    AttendanceStatus.present,
                  ),
                  AppColors.present,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _attendanceCountTile(
                  'Absent',
                  _countStatus(
                    AttendanceStatus.absent,
                  ),
                  AppColors.absent,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _attendanceCountTile(
                  'Half Day',
                  _countStatus(
                    AttendanceStatus.halfDay,
                  ),
                  AppColors.halfDay,
                  Icons.timelapse,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _attendanceCountTile(
                  'Holiday',
                  _countStatus(
                    AttendanceStatus.holiday,
                  ),
                  AppColors.holiday,
                  Icons.event_available_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceCountTile(
    String title,
    int value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingTime() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Working Time'),

          const SizedBox(height: 14),

          _infoRow(
            'Normal Hours',
            _formatHours(_totalNormalHours()),
          ),

          _infoRow(
            'Overtime',
            _formatHours(_totalOtHours()),
          ),

          _infoRow(
            'Normal Rate',
            _formatHours(config.normalWorkingHours),
          ),

          _infoRow(
            'OT Rate',
            '${_money(config.otRate)}/hour',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Breakdown'),

          const SizedBox(height: 12),

          _paymentRow(
            'Monthly Salary',
            _money(config.monthlySalary),
          ),

          _paymentRow(
            'Daily Wage',
            _money(_dailyWage()),
          ),

          _paymentRow(
            'OT Rate',
            '${_money(config.otRate)}/hour',
          ),

          const Divider(height: 20),

          _paymentRow(
            'Basic Payment',
            _money(_basicPayment()),
            bold: true,
          ),

          _paymentRow(
            'OT Payment',
            _money(_otPayment()),
            bold: true,
          ),

          _paymentRow(
            'Advance',
            '-${_money(config.advance)}',
          ),

          _paymentRow(
            'Deduction',
            '-${_money(config.deduction)}',
          ),

          const Divider(height: 20),

          _paymentRow(
            'Net Payment',
            _money(_netPayment()),
            bold: true,
            large: true,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String title,
    String value, {
    bool bold = false,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: large ? 15 : 13,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 18 : 13,
              fontWeight:
                  bold ? FontWeight.w900 : FontWeight.w700,
              color: large
                  ? AppColors.primary
                  : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _navItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Month',
                index: 0,
              ),
              _navItem(
                icon: Icons.date_range_outlined,
                activeIcon: Icons.date_range,
                label: 'Year',
                index: 1,
              ),
              _navItem(
                icon: Icons.payments_outlined,
                activeIcon: Icons.payments,
                label: 'Summary',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final active = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                color: active
                    ? AppColors.primary
                    : AppColors.secondaryText,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: active
                      ? AppColors.primary
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  Future<void> _openSettings() async {
    final result = await showModalBottomSheet<PaymentConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PaymentSettingsSheet(
          config: config,
        );
      },
    );

    if (result == null) return;

    setState(() {
      config = result;
    });

    await _saveConfig();
  }
}

// ============================================================
// LEGEND DOT
// ============================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ATTENDANCE ENTRY SHEET
// ============================================================

class AttendanceEntrySheet extends StatefulWidget {
  final DateTime date;
  final AttendanceRecord? existing;
  final double defaultNormalHours;

  const AttendanceEntrySheet({
    super.key,
    required this.date,
    required this.existing,
    required this.defaultNormalHours,
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

    status = widget.existing?.status ??
        AttendanceStatus.present;

    final normal =
        widget.existing?.normalHours ??
        widget.defaultNormalHours;

    final ot = widget.existing?.otHours ?? 0;

    normalController = TextEditingController(
      text: _formatInputHours(normal),
    );

    otController = TextEditingController(
      text: _formatInputHours(ot),
    );

    noteController = TextEditingController(
      text: widget.existing?.note ?? '',
    );
  }

  @override
  void dispose() {
    normalController.dispose();
    otController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String _formatInputHours(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}H';
    }

    return '${value.toStringAsFixed(1)}H';
  }

  double _parseHours(String text) {
    final clean = text
        .trim()
        .toUpperCase()
        .replaceAll('H', '')
        .trim();

    return double.tryParse(clean) ?? 0;
  }

  void _setNormal(String value) {
    setState(() {
      normalController.text = value;
      normalController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: normalController.text.length,
        ),
      );
    });
  }

  void _setOt(String value) {
    setState(() {
      otController.text = value;
      otController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: otController.text.length,
        ),
      );
    });
  }

  String _statusText(AttendanceStatus value) {
    switch (value) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  Color _statusColor(AttendanceStatus value) {
    switch (value) {
      case AttendanceStatus.present:
        return AppColors.present;
      case AttendanceStatus.halfDay:
        return AppColors.halfDay;
      case AttendanceStatus.absent:
        return AppColors.absent;
      case AttendanceStatus.leave:
        return AppColors.leave;
      case AttendanceStatus.holiday:
        return AppColors.holiday;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      padding: EdgeInsets.only(
        bottom: bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Entry',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateTitle(widget.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _label('Status'),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AttendanceStatus.values
                          .map(
                            (value) => _statusButton(value),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 20),

                    _label('Normal Working Hours'),

                    const SizedBox(height: 8),

                    _hoursField(
                      controller: normalController,
                      hint: 'Example: 8H',
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: [
                        _quickHour(
                          '4H',
                          () => _setNormal('4H'),
                          normalController.text
                              .toUpperCase() ==
                              '4H',
                        ),
                        _quickHour(
                          '8H',
                          () => _setNormal('8H'),
                          normalController.text
                              .toUpperCase() ==
                              '8H',
                        ),
                        _quickHour(
                          '10H',
                          () => _setNormal('10H'),
                          normalController.text
                              .toUpperCase() ==
                              '10H',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _label('Overtime'),

                    const SizedBox(height: 8),

                    _hoursField(
                      controller: otController,
                      hint: 'Example: 4H, 8H, 12H',
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: [
                        _quickHour(
                          '0H',
                          () => _setOt('0H'),
                          otController.text
                              .toUpperCase() ==
                              '0H',
                        ),
                        _quickHour(
                          '4H',
                          () => _setOt('4H'),
                          otController.text
                              .toUpperCase() ==
                              '4H',
                        ),
                        _quickHour(
                          '8H',
                          () => _setOt('8H'),
                          otController.text
                              .toUpperCase() ==
                              '8H',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _label('Note'),

                    const SizedBox(height: 8),

                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Optional note',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: const Text(
                          'Save Attendance',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor: Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }

  Widget _hoursField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: 'H',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _quickHour(
    String text,
    VoidCallback onTap,
    bool selected,
  ) {
    return Material(
      color: selected
          ? AppColors.primary
          : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected
                  ? Colors.white
                  : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusButton(AttendanceStatus value) {
    final selected = status == value;
    final color = _statusColor(value);

    return Material(
      color: selected
          ? color
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            status = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : AppColors.border,
            ),
          ),
          child: Text(
            _statusText(value),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? Colors.white
                  : color,
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final normal = _parseHours(
      normalController.text,
    );

    final ot = _parseHours(
      otController.text,
    );

    final record = AttendanceRecord(
      dateKey:
          '${widget.date.year.toString().padLeft(4, '0')}-'
          '${widget.date.month.toString().padLeft(2, '0')}-'
          '${widget.date.day.toString().padLeft(2, '0')}',
      status: status,
      normalHours: normal,
      otHours: ot,
      note: noteController.text.trim(),
    );

    Navigator.pop(
      context,
      record,
    );
  }
}

// ============================================================
// PAYMENT SETTINGS
// ============================================================

class PaymentSettingsSheet extends StatefulWidget {
  final PaymentConfig config;

  const PaymentSettingsSheet({
    super.key,
    required this.config,
  });

  @override
  State<PaymentSettingsSheet> createState() =>
      _PaymentSettingsSheetState();
}

class _PaymentSettingsSheetState
    extends State<PaymentSettingsSheet> {
  late CalculationMode mode;

  late TextEditingController monthlySalaryController;
  late TextEditingController workingDaysController;
  late TextEditingController normalHoursController;
  late TextEditingController otRateController;
  late TextEditingController dailyWageController;
  late TextEditingController advanceController;
  late TextEditingController deductionController;

  @override
  void initState() {
    super.initState();

    mode = widget.config.mode;

    monthlySalaryController =
        TextEditingController(
      text: _number(widget.config.monthlySalary),
    );

    workingDaysController =
        TextEditingController(
      text: '${widget.config.standardWorkingDays}',
    );

    normalHoursController =
        TextEditingController(
      text: _number(widget.config.normalWorkingHours),
    );

    otRateController =
        TextEditingController(
      text: _number(widget.config.otRate),
    );

    dailyWageController =
        TextEditingController(
      text: _number(widget.config.dailyWage),
    );

    advanceController =
        TextEditingController(
      text: _number(widget.config.advance),
    );

    deductionController =
        TextEditingController(
      text: _number(widget.config.deduction),
    );
  }

  @override
  void dispose() {
    monthlySalaryController.dispose();
    workingDaysController.dispose();
    normalHoursController.dispose();
    otRateController.dispose();
    dailyWageController.dispose();
    advanceController.dispose();
    deductionController.dispose();

    super.dispose();
  }

  String _number(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}';
    }

    return value.toString();
  }

  double _double(TextEditingController controller) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  int _int(TextEditingController controller) {
    return int.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  String _modeTitle(CalculationMode value) {
    switch (value) {
      case CalculationMode.fixedDays:
        return 'Fixed Days';
      case CalculationMode.monthDays:
        return 'Month Days';
      case CalculationMode.dailyWage:
        return 'Daily Wage';
    }
  }

  String _modeDescription(CalculationMode value) {
    switch (value) {
      case CalculationMode.fixedDays:
        return 'Monthly salary based on standard working days';
      case CalculationMode.monthDays:
        return 'Monthly salary divided by actual month days';
      case CalculationMode.dailyWage:
        return 'Payment based on daily wage';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      padding: EdgeInsets.only(
        bottom: bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                12,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _label('Calculation Mode'),

                    const SizedBox(height: 8),

                    ...CalculationMode.values.map(
                      (value) => _modeCard(value),
                    ),

                    const SizedBox(height: 18),

                    _field(
                      'Monthly Salary',
                      monthlySalaryController,
                      prefix: '₹',
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'Standard Working Days',
                      workingDaysController,
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'Normal Working Hours / Day',
                      normalHoursController,
                      suffix: 'H',
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'OT Rate / Hour',
                      otRateController,
                      prefix: '₹',
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'Daily Wage',
                      dailyWageController,
                      prefix: '₹',
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'Advance',
                      advanceController,
                      prefix: '₹',
                    ),

                    const SizedBox(height: 12),

                    _field(
                      'Deduction',
                      deductionController,
                      prefix: '₹',
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: const Text(
                          'Save Configuration',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor: Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }

  Widget _modeCard(CalculationMode value) {
    final selected = mode == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primaryLight
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              mode = value;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? AppColors.primary
                      : AppColors.secondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeTitle(value),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _modeDescription(value),
                        style: const TextStyle(
                          fontSize: 10,
                          color:
                              AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    final result = PaymentConfig(
      mode: mode,
      monthlySalary:
          _double(monthlySalaryController),
      standardWorkingDays:
          _int(workingDaysController),
      normalWorkingHours:
          _double(normalHoursController),
      otRate:
          _double(otRateController),
      dailyWage:
          _double(dailyWageController),
      advance:
          _double(advanceController),
      deduction:
          _double(deductionController),
    );

    Navigator.pop(
      context,
      result,
    );
  }
}
