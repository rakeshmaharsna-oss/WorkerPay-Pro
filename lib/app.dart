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
  static const bg = Color(0xFFF0F7FF);
  static const primary = Color(0xFF086B8A);
  static const dark = Color(0xFF075B76);
  static const light = Color(0xFFDDF2F8);

  static const text = Color(0xFF102033);
  static const sub = Color(0xFF66727D);
  static const border = Color(0xFFB9C9D8);

  static const green = Color(0xFF159447);
  static const greenBg = Color(0xFFEAF7EF);

  static const orange = Color(0xFFC95A16);
  static const orangeBg = Color(0xFFFFF1E9);

  static const red = Color(0xFFC52632);
  static const redBg = Color(0xFFFFEEEE);

  static const yellow = Color(0xFFD19A00);
  static const yellowBg = Color(0xFFFFF8DD);

  static const purple = Color(0xFF7136C7);
  static const purpleBg = Color(0xFFF4EEFF);

  static const ot = Color(0xFFD77A00);
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
// HELPERS
// ============================================================

String monthName(int month) {
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

String weekdayName(DateTime date) {
  const names = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  return names[date.weekday - 1];
}

String dateTitle(DateTime date) {
  return '${weekdayName(date)}, '
      '${date.day} '
      '${monthName(date.month)} '
      '${date.year}';
}

String hoursText(double value) {
  if (value == value.roundToDouble()) {
    return '${value.toInt()}H';
  }

  return '${value.toStringAsFixed(1)}H';
}

String money(double value) {
  return '₹${value.round()}';
}

int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

String dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

AttendanceStatus statusFromIndex(int index) {
  if (index < 0 || index >= AttendanceStatus.values.length) {
    return AttendanceStatus.present;
  }

  return AttendanceStatus.values[index];
}

CalculationMode calculationModeFromIndex(int index) {
  if (index < 0 || index >= CalculationMode.values.length) {
    return CalculationMode.fixedDays;
  }

  return CalculationMode.values[index];
}

Color statusColor(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return AppColors.green;

    case AttendanceStatus.halfDay:
      return AppColors.orange;

    case AttendanceStatus.absent:
      return AppColors.red;

    case AttendanceStatus.leave:
      return AppColors.yellow;

    case AttendanceStatus.holiday:
      return AppColors.purple;
  }
}

Color statusBackground(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return AppColors.greenBg;

    case AttendanceStatus.halfDay:
      return AppColors.orangeBg;

    case AttendanceStatus.absent:
      return AppColors.redBg;

    case AttendanceStatus.leave:
      return AppColors.yellowBg;

    case AttendanceStatus.holiday:
      return AppColors.purpleBg;
  }
}

String statusName(AttendanceStatus status) {
  switch (status) {
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

// ============================================================
// ATTENDANCE RECORD
// ============================================================

class AttendanceRecord {
  final String key;

  AttendanceStatus status;
  double normalHours;
  double overtime;
  String note;

  AttendanceRecord({
    required this.key,
    required this.status,
    required this.normalHours,
    required this.overtime,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'status': status.index,
      'normalHours': normalHours,
      'overtime': overtime,
      'note': note,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final statusIndex =
        (json['status'] as num?)?.toInt() ?? 0;

    return AttendanceRecord(
      key: json['key']?.toString() ?? '',
      status: statusFromIndex(statusIndex),
      normalHours:
          (json['normalHours'] as num?)?.toDouble() ?? 0,
      overtime:
          (json['overtime'] as num?)?.toDouble() ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}

// ============================================================
// PAYMENT SETTINGS
// ============================================================

class PaymentSettings {
  CalculationMode mode;

  double monthlySalary;
  int standardDays;
  double normalHoursPerDay;
  double overtimeRate;
  double dailyWage;

  double advance;
  double deduction;

  PaymentSettings({
    this.mode = CalculationMode.fixedDays,
    this.monthlySalary = 15000,
    this.standardDays = 26,
    this.normalHoursPerDay = 8,
    this.overtimeRate = 100,
    this.dailyWage = 577,
    this.advance = 0,
    this.deduction = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.index,
      'monthlySalary': monthlySalary,
      'standardDays': standardDays,
      'normalHoursPerDay': normalHoursPerDay,
      'overtimeRate': overtimeRate,
      'dailyWage': dailyWage,
      'advance': advance,
      'deduction': deduction,
    };
  }

  factory PaymentSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentSettings(
      mode: calculationModeFromIndex(
        (json['mode'] as num?)?.toInt() ?? 0,
      ),
      monthlySalary:
          (json['monthlySalary'] as num?)?.toDouble() ?? 15000,
      standardDays:
          (json['standardDays'] as num?)?.toInt() ?? 26,
      normalHoursPerDay:
          (json['normalHoursPerDay'] as num?)?.toDouble() ?? 8,
      overtimeRate:
          (json['overtimeRate'] as num?)?.toDouble() ?? 100,
      dailyWage:
          (json['dailyWage'] as num?)?.toDouble() ?? 577,
      advance:
          (json['advance'] as num?)?.toDouble() ?? 0,
      deduction:
          (json['deduction'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ============================================================
// LOCAL STORAGE
// ============================================================

class LocalStore {
  static const recordsKey = 'worker_pay_records_v5';
  static const settingsKey = 'worker_pay_settings_v5';

  final SharedPreferences prefs;

  LocalStore(this.prefs);

  Map<String, AttendanceRecord> loadRecords() {
    final raw = prefs.getString(recordsKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return {};
      }

      final result = <String, AttendanceRecord>{};

      for (final item in decoded) {
        if (item is Map) {
          final record = AttendanceRecord.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (record.key.isNotEmpty) {
            result[record.key] = record;
          }
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  PaymentSettings loadSettings() {
    final raw = prefs.getString(settingsKey);

    if (raw == null || raw.isEmpty) {
      return PaymentSettings();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return PaymentSettings();
      }

      return PaymentSettings.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return PaymentSettings();
    }
  }

  Future<void> saveRecords(
    Map<String, AttendanceRecord> records,
  ) async {
    final list = records.values
        .map((record) => record.toJson())
        .toList();

    await prefs.setString(
      recordsKey,
      jsonEncode(list),
    );
  }

  Future<void> saveSettings(
    PaymentSettings settings,
  ) async {
    await prefs.setString(
      settingsKey,
      jsonEncode(settings.toJson()),
    );
  }
}

// ============================================================
// APP
// ============================================================

class WorkerPayApp extends StatefulWidget {
  const WorkerPayApp({super.key});

  @override
  State<WorkerPayApp> createState() => _WorkerPayAppState();
}

class _WorkerPayAppState extends State<WorkerPayApp> {
  late Future<LocalStore> storeFuture;

  @override
  void initState() {
    super.initState();
    storeFuture = loadStore();
  }

  Future<LocalStore> loadStore() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worker Pay',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      home: FutureBuilder<LocalStore>(
        future: storeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return const WorkerPaySplash();
          }

          return WorkerPayHome(
            store: snapshot.data!,
          );
        },
      ),
    );
  }
}

// ============================================================
// SPLASH
// ============================================================

class WorkerPaySplash extends StatelessWidget {
  const WorkerPaySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_outlined,
              color: AppColors.primary,
              size: 62,
            ),
            SizedBox(height: 12),
            Text(
              'Worker Pay',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 29,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Attendance & Payment',
              style: TextStyle(
                color: AppColors.sub,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class WorkerPayHome extends StatefulWidget {
  final LocalStore store;

  const WorkerPayHome({
    super.key,
    required this.store,
  });

  @override
  State<WorkerPayHome> createState() => _WorkerPayHomeState();
}

class _WorkerPayHomeState extends State<WorkerPayHome> {
  late Map<String, AttendanceRecord> records;
  late PaymentSettings settings;

  int selectedTab = 0;

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();

    records = widget.store.loadRecords();
    settings = widget.store.loadSettings();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  AttendanceRecord? recordFor(DateTime date) {
    return records[dateKey(date)];
  }

  List<AttendanceRecord> currentMonthRecords() {
    final prefix =
        '${selectedMonth.year.toString().padLeft(4, '0')}-'
        '${selectedMonth.month.toString().padLeft(2, '0')}-';

    return records.values
        .where((record) => record.key.startsWith(prefix))
        .toList();
  }

  int statusCount(AttendanceStatus status) {
    return currentMonthRecords()
        .where((record) => record.status == status)
        .length;
  }

  double totalNormalHours() {
    return currentMonthRecords().fold(
      0,
      (sum, record) => sum + record.normalHours,
    );
  }

  double totalOvertime() {
    return currentMonthRecords().fold(
      0,
      (sum, record) => sum + record.overtime,
    );
  }

  double calculatedDailyWage() {
    if (settings.mode == CalculationMode.dailyWage) {
      return settings.dailyWage;
    }

    if (settings.mode == CalculationMode.monthDays) {
      return settings.monthlySalary /
          daysInMonth(
            selectedMonth.year,
            selectedMonth.month,
          );
    }

    return settings.monthlySalary /
        settings.standardDays;
  }

  double basicPayment() {
    double total = 0;

    for (final record in currentMonthRecords()) {
      if (record.status == AttendanceStatus.present) {
        total += calculatedDailyWage();
      }

      if (record.status == AttendanceStatus.halfDay) {
        total += calculatedDailyWage() / 2;
      }
    }

    return total;
  }

  double overtimePayment() {
    return totalOvertime() * settings.overtimeRate;
  }

  double netPayment() {
    return basicPayment() +
        overtimePayment() -
        settings.advance -
        settings.deduction;
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> saveAttendance(
    AttendanceRecord record,
  ) async {
    setState(() {
      records[record.key] = record;
    });

    await widget.store.saveRecords(records);
  }

  Future<void> savePaymentSettings(
    PaymentSettings value,
  ) async {
    setState(() {
      settings = value;
    });

    await widget.store.saveSettings(settings);
  }

  // ==========================================================
  // MONTH
  // ==========================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  void goCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      selectedMonth = DateTime(
        now.year,
        now.month,
      );
    });
  }

  // ==========================================================
  // ATTENDANCE SHEET
  // ==========================================================

  Future<void> openAttendance(DateTime date) async {
    final key = dateKey(date);

    final existing = records[key];

    final initial = existing ??
        AttendanceRecord(
          key: key,
          status: AttendanceStatus.present,
          normalHours: settings.normalHoursPerDay,
          overtime: 0,
        );

    final result = await showModalBottomSheet<AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AttendanceEntrySheet(
          date: date,
          initial: initial,
        );
      },
    );

    if (result != null) {
      await saveAttendance(result);
    }
  }

  // ==========================================================
  // PAYMENT EDIT
  // ==========================================================

  Future<void> openPaymentEditor() async {
    final result = await showModalBottomSheet<PaymentSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return PaymentEditSheet(
          initial: settings,
        );
      },
    );

    if (result != null) {
      await savePaymentSettings(result);
    }
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            buildMonthPage(),
            buildYearPage(),
            buildSummaryPage(),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigation(),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            buildNavItem(
              0,
              Icons.calendar_month_outlined,
              'Month',
            ),
            buildNavItem(
              1,
              Icons.calendar_today_outlined,
              'Year',
            ),
            buildNavItem(
              2,
              Icons.payments_outlined,
              'Summary',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(
    int index,
    IconData icon,
    String label,
  ) {
    final active = selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: active
                ? AppColors.light
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 29,
                color: active
                    ? AppColors.primary
                    : AppColors.sub,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? AppColors.primary
                      : AppColors.sub,
                  fontSize: 15,
                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MONTH PAGE
  // ==========================================================

  Widget buildMonthPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildMonthHeader(),
          const SizedBox(height: 14),
          buildMonthSelector(),
          const SizedBox(height: 13),
          buildTopStats(),
          const SizedBox(height: 15),
          buildCalendar(),
          const SizedBox(height: 11),
          buildLegend(),
          const SizedBox(height: 14),
          buildMonthSummary(),
        ],
      ),
    );
  }

  Widget buildMonthHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worker Pay',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 38,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Attendance & Payment',
          style: TextStyle(
            color: AppColors.sub,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget buildMonthSelector() {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: previousMonth,
            icon: const Icon(
              Icons.chevron_left,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: goCurrentMonth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${monthName(selectedMonth.month)} '
                    '${selectedMonth.year}',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap for current month',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: nextMonth,
            icon: const Icon(
              Icons.chevron_right,
              size: 38,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOP STATS
  // ==========================================================

  Widget buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: buildTopStat(
            Icons.access_time,
            'Hours',
            hoursText(totalNormalHours()),
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: buildTopStat(
            Icons.more_time,
            'OT',
            hoursText(totalOvertime()),
            AppColors.ot,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: buildTopStat(
            Icons.payments_outlined,
            'Payment',
            money(netPayment()),
            AppColors.green,
          ),
        ),
      ],
    );
  }

  Widget buildTopStat(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        9,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: AppColors.border,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 29,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.sub,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
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

  Widget buildCalendar() {
    final totalDays = daysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final leadingDays = firstDay.weekday % 7;

    final totalCells =
        ((leadingDays + totalDays + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        15,
        10,
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: AppColors.border,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              'SUN',
              'MON',
              'TUE',
              'WED',
              'THU',
              'FRI',
              'SAT',
            ].map(
              (day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.sub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              mainAxisExtent: 68,
            ),
            itemBuilder: (context, index) {
              final day =
                  index - leadingDays + 1;

              if (day < 1 || day > totalDays) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                day,
              );

              return buildCalendarCell(
                date,
                recordFor(date),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildCalendarCell(
    DateTime date,
    AttendanceRecord? record,
  ) {
    final today =
        DateUtils.isSameDay(date, DateTime.now());

    final borderColor = record == null
        ? AppColors.border
        : statusColor(record.status);

    final backgroundColor = record == null
        ? Colors.white
        : statusBackground(record.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => openAttendance(date),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          7,
          6,
          5,
          4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: today
                ? AppColors.primary
                : borderColor,
            width: today ? 2 : 1.4,
          ),
        ),
        child: record == null
            ? Column(
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '+',
                    style: TextStyle(
                      color: AppColors.border,
                      fontSize: 25,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    hoursText(record.normalHours),
                    maxLines: 1,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (record.overtime > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'OT ${hoursText(record.overtime)}',
                        style: const TextStyle(
                          color: AppColors.ot,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ==========================================================
  // LEGEND
  // ==========================================================

  Widget buildLegend() {
    final items = [
      [AppColors.green, 'Present'],
      [AppColors.orange, 'Half Day'],
      [AppColors.red, 'Absent'],
      [AppColors.yellow, 'Leave'],
      [AppColors.purple, 'Holiday'],
      [AppColors.ot, 'OT'],
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 7,
      children: items.map(
        (item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: item[0] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item[1] as String,
                style: const TextStyle(
                  color: AppColors.sub,
                  fontSize: 13,
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }

  // ==========================================================
  // MONTHLY MINI SUMMARY
  // ==========================================================

  Widget buildMonthSummary() {
    return buildWhiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              buildMiniSummary(
                'Present',
                statusCount(
                  AttendanceStatus.present,
                ).toDouble(),
                AppColors.green,
              ),
              buildMiniSummary(
                'Half Day',
                statusCount(
                  AttendanceStatus.halfDay,
                ).toDouble(),
                AppColors.orange,
              ),
              buildMiniSummary(
                'Absent',
                statusCount(
                  AttendanceStatus.absent,
                ).toDouble(),
                AppColors.red,
              ),
              buildMiniSummary(
                'OT',
                totalOvertime(),
                AppColors.ot,
                hours: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMiniSummary(
    String label,
    double value,
    Color color, {
    bool hours = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            hours
                ? hoursText(value)
                : value.toInt().toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.sub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // YEAR PAGE
  // ==========================================================

  Widget buildYearPage() {
    final year = selectedMonth.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Year Overview',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$year · Monthly Attendance',
            style: const TextStyle(
              color: AppColors.sub,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 17),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 145,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;

              final list = records.values.where(
                (record) {
                  return record.key.startsWith(
                    '${year.toString().padLeft(4, '0')}-'
                    '${month.toString().padLeft(2, '0')}-',
                  );
                },
              ).toList();

              final overtime = list.fold(
                0.0,
                (sum, record) =>
                    sum + record.overtime,
              );

              final present = list.where(
                (record) =>
                    record.status ==
                    AttendanceStatus.present,
              ).length;

              final absent = list.where(
                (record) =>
                    record.status ==
                    AttendanceStatus.absent,
              ).length;

              final halfDay = list.where(
                (record) =>
                    record.status ==
                    AttendanceStatus.halfDay,
              ).length;

              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  setState(() {
                    selectedMonth =
                        DateTime(year, month);
                    selectedTab = 0;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName(month),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'P $present',
                            style:
                                const TextStyle(
                              color:
                                  AppColors.green,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            'A $absent',
                            style:
                                const TextStyle(
                              color:
                                  AppColors.red,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            'H $halfDay',
                            style:
                                const TextStyle(
                              color:
                                  AppColors.orange,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'OT ${hoursText(overtime)}',
                        style:
                            const TextStyle(
                          color: AppColors.ot,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUMMARY PAGE
  // ==========================================================

  Widget buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${monthName(selectedMonth.month)} '
            '${selectedMonth.year}',
            style: const TextStyle(
              color: AppColors.sub,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),

          // ESTIMATED PAYMENT
          buildEstimatedPayment(),

          const SizedBox(height: 15),

          // ATTENDANCE
          buildAttendanceSummary(),

          const SizedBox(height: 15),

          // PAYMENT
          buildPaymentBreakdown(),
        ],
      ),
    );
  }

  // ==========================================================
  // ESTIMATED PAYMENT
  // ==========================================================

  Widget buildEstimatedPayment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        23,
        21,
        18,
        21,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Net Payment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    money(netPayment()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 1,
            height: 108,
            color: Colors.white24,
          ),

          const SizedBox(width: 18),

          // HOURS + OT RIGHT SIDE
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hours',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  hoursText(
                    totalNormalHours(),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'OT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  hoursText(
                    totalOvertime(),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ATTENDANCE SUMMARY
  // ==========================================================

  Widget buildAttendanceSummary() {
    return buildWhiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildAttendanceBox(
                  'Present',
                  statusCount(
                    AttendanceStatus.present,
                  ),
                  AppColors.green,
                  AppColors.greenBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildAttendanceBox(
                  'Absent',
                  statusCount(
                    AttendanceStatus.absent,
                  ),
                  AppColors.red,
                  AppColors.redBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildAttendanceBox(
                  'Half Day',
                  statusCount(
                    AttendanceStatus.halfDay,
                  ),
                  AppColors.orange,
                  AppColors.orangeBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildAttendanceBox(
                  'Holiday',
                  statusCount(
                    AttendanceStatus.holiday,
                  ),
                  AppColors.purple,
                  AppColors.purpleBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAttendanceBox(
    String label,
    int count,
    Color color,
    Color background,
  ) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.sub,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAYMENT BREAKDOWN
  // ==========================================================

  Widget buildPaymentBreakdown() {
    return buildWhiteCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Breakdown',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // PENCIL
              IconButton(
                tooltip: 'Edit Payment',
                onPressed: openPaymentEditor,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          buildMoneyRow(
            'Monthly Salary',
            settings.monthlySalary,
          ),

          buildMoneyRow(
            'Daily Wage',
            calculatedDailyWage(),
          ),

          buildMoneyRow(
            'OT Rate',
            settings.overtimeRate,
            suffix: '/hour',
          ),

          const Divider(
            height: 26,
            color: AppColors.border,
          ),

          buildMoneyRow(
            'Basic Payment',
            basicPayment(),
            bold: true,
          ),

          buildMoneyRow(
            'OT Payment',
            overtimePayment(),
            bold: true,
          ),

          buildMoneyRow(
            'Advance',
            -settings.advance,
          ),

          buildMoneyRow(
            'Deduction',
            -settings.deduction,
          ),

          const Divider(
            height: 26,
            color: AppColors.border,
          ),

          buildMoneyRow(
            'Net Payment',
            netPayment(),
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget buildMoneyRow(
    String label,
    double value, {
    bool bold = false,
    bool large = false,
    String suffix = '',
  }) {
    final sign = value < 0 ? '−' : '';
    final valueText =
        '$sign₹${value.abs().round()}$suffix';

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: large
                    ? AppColors.text
                    : AppColors.sub,
                fontSize: large ? 22 : 17,
                fontWeight: bold
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              color: large
                  ? AppColors.primary
                  : AppColors.text,
              fontSize: large ? 28 : 17,
              fontWeight: bold
                  ? FontWeight.w700
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WHITE CARD
  // ==========================================================

  Widget buildWhiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border,
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}

// ============================================================
// ATTENDANCE ENTRY SHEET
// ============================================================

class AttendanceEntrySheet extends StatefulWidget {
  final DateTime date;
  final AttendanceRecord initial;

  const AttendanceEntrySheet({
    super.key,
    required this.date,
    required this.initial,
  });

  @override
  State<AttendanceEntrySheet> createState() =>
      _AttendanceEntrySheetState();
}

class _AttendanceEntrySheetState
    extends State<AttendanceEntrySheet> {
  late AttendanceStatus status;

  late TextEditingController normalController;
  late TextEditingController overtimeController;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    status = widget.initial.status;

    normalController =
        TextEditingController(
      text: hoursText(
        widget.initial.normalHours,
      ),
    );

    overtimeController =
        TextEditingController(
      text: hoursText(
        widget.initial.overtime,
      ),
    );

    noteController =
        TextEditingController(
      text: widget.initial.note,
    );
  }

  @override
  void dispose() {
    normalController.dispose();
    overtimeController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double parseHours(
    String value,
  ) {
    return double.tryParse(
          value
              .toUpperCase()
              .replaceAll('H', '')
              .trim(),
        ) ??
        0;
  }

  void setNormalHours(double value) {
    normalController.text = hoursText(value);

    normalController.selection =
        TextSelection.collapsed(
      offset: normalController.text.length,
    );

    setState(() {});
  }

  void setOvertime(double value) {
    overtimeController.text = hoursText(value);

    overtimeController.selection =
        TextSelection.collapsed(
      offset: overtimeController.text.length,
    );

    setState(() {});
  }

  void selectStatus(
    AttendanceStatus newStatus,
  ) {
    setState(() {
      status = newStatus;

      if (newStatus ==
          AttendanceStatus.halfDay) {
        normalController.text = '4H';
      }

      if (newStatus ==
              AttendanceStatus.absent ||
          newStatus ==
              AttendanceStatus.leave ||
          newStatus ==
              AttendanceStatus.holiday) {
        normalController.text = '0H';
      }

      if (newStatus ==
          AttendanceStatus.present) {
        if (parseHours(
              normalController.text,
            ) ==
            0) {
          normalController.text = '8H';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(
          top: 30,
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + keyboard,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(34),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 19),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Attendance Entry',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 34,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),

              Text(
                dateTitle(widget.date),
                style: const TextStyle(
                  color: AppColors.sub,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Status',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 11),

              Wrap(
                spacing: 9,
                runSpacing: 9,
                children:
                    AttendanceStatus.values
                        .map(
                          buildStatusButton,
                        )
                        .toList(),
              ),

              const SizedBox(height: 27),

              const Text(
                'Normal Working Hours',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 9),

              buildHoursField(
                normalController,
              ),

              const SizedBox(height: 9),

              Wrap(
                spacing: 9,
                children: [
                  buildHourButton(
                    '4H',
                    4,
                    true,
                  ),
                  buildHourButton(
                    '8H',
                    8,
                    true,
                  ),
                  buildHourButton(
                    '10H',
                    10,
                    true,
                  ),
                ],
              ),

              const SizedBox(height: 27),

              const Text(
                'Overtime',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 9),

              buildHoursField(
                overtimeController,
              ),

              const SizedBox(height: 9),

              Wrap(
                spacing: 9,
                children: [
                  buildHourButton(
                    '0H',
                    0,
                    false,
                  ),
                  buildHourButton(
                    '4H',
                    4,
                    false,
                  ),
                  buildHourButton(
                    '8H',
                    8,
                    false,
                  ),
                ],
              ),

              const SizedBox(height: 27),

              const Text(
                'Note',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 9),

              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Optional note',
                  hintStyle:
                      const TextStyle(
                    color:
                        AppColors.sub,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  contentPadding:
                      const EdgeInsets.all(
                    20,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.border,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.border,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton.icon(
                  onPressed: save,
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 27,
                  ),
                  label: const Text(
                    'Save Attendance',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHoursField(
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        suffixText: 'H',
        suffixStyle:
            const TextStyle(
          color: AppColors.sub,
          fontSize: 19,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 19,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(24),
          borderSide:
              const BorderSide(
            color:
                AppColors.border,
            width: 1.4,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(24),
          borderSide:
              const BorderSide(
            color:
                AppColors.border,
            width: 1.4,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(24),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 2,
          ),
        ),
      ),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 22,
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget buildStatusButton(
    AttendanceStatus value,
  ) {
    final selected = status == value;
    final color = statusColor(value);

    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () =>
          selectStatus(value),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 21,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color
              : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          statusName(value),
          style: TextStyle(
            color: selected
                ? Colors.white
                : color,
            fontSize: 17,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildHourButton(
    String label,
    double value,
    bool normal,
  ) {
    final controller =
        normal
            ? normalController
            : overtimeController;

    final selected =
        parseHours(
              controller.text,
            ) ==
            value;

    // IMPORTANT:
    // selected button follows the selected attendance status.
    final color =
        statusColor(status);

    return InkWell(
      borderRadius:
          BorderRadius.circular(17),
      onTap: () {
        if (normal) {
          setNormalHours(value);
        } else {
          setOvertime(value);
        }
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 27,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color
              : Colors.white,
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? color
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppColors.text,
            fontSize: 16,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(
      context,
      AttendanceRecord(
        key: dateKey(widget.date),
        status: status,
        normalHours:
            parseHours(
          normalController.text,
        ),
        overtime:
            parseHours(
          overtimeController.text,
        ),
        note:
            noteController.text.trim(),
      ),
    );
  }
}

// ============================================================
// PAYMENT EDIT SHEET
// ============================================================

class PaymentEditSheet extends StatefulWidget {
  final PaymentSettings initial;

  const PaymentEditSheet({
    super.key,
    required this.initial,
  });

  @override
  State<PaymentEditSheet> createState() =>
      _PaymentEditSheetState();
}

class _PaymentEditSheetState
    extends State<PaymentEditSheet> {
  late CalculationMode mode;

  late TextEditingController salary;
  late TextEditingController standardDays;
  late TextEditingController normalHours;
  late TextEditingController overtimeRate;
  late TextEditingController dailyWage;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    mode = widget.initial.mode;

    salary = numberController(
      widget.initial.monthlySalary,
    );

    standardDays =
        TextEditingController(
      text:
          widget.initial.standardDays
              .toString(),
    );

    normalHours = numberController(
      widget.initial.normalHoursPerDay,
    );

    overtimeRate = numberController(
      widget.initial.overtimeRate,
    );

    dailyWage = numberController(
      widget.initial.dailyWage,
    );

    advance = numberController(
      widget.initial.advance,
    );

    deduction = numberController(
      widget.initial.deduction,
    );
  }

  TextEditingController numberController(
    double value,
  ) {
    final text =
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();

    return TextEditingController(
      text: text,
    );
  }

  @override
  void dispose() {
    salary.dispose();
    standardDays.dispose();
    normalHours.dispose();
    overtimeRate.dispose();
    dailyWage.dispose();
    advance.dispose();
    deduction.dispose();

    super.dispose();
  }

  double number(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(
          top: 30,
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + keyboard,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(34),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        color:
                            AppColors.text,
                        fontSize: 29,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    icon: const Icon(
                      Icons.close,
                      size: 33,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'Calculation Mode',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 9),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildModeButton(
                    CalculationMode.fixedDays,
                    'Fixed Days',
                  ),
                  buildModeButton(
                    CalculationMode.monthDays,
                    'Month Days',
                  ),
                  buildModeButton(
                    CalculationMode.dailyWage,
                    'Daily Wage',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              buildField(
                'Monthly Salary',
                salary,
              ),

              buildField(
                'Standard Working Days',
                standardDays,
              ),

              buildField(
                'Normal Working Hours / Day',
                normalHours,
              ),

              buildField(
                'OT Rate / Hour',
                overtimeRate,
              ),

              buildField(
                'Daily Wage',
                dailyWage,
              ),

              buildField(
                'Advance',
                advance,
              ),

              buildField(
                'Deduction',
                deduction,
              ),

              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: save,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        21,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Save Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildModeButton(
    CalculationMode value,
    String label,
  ) {
    final selected = mode == value;

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        setState(() {
          mode = value;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppColors.text,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration:
            InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(19),
            borderSide:
                const BorderSide(
              color:
                  AppColors.border,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(19),
            borderSide:
                const BorderSide(
              color:
                  AppColors.border,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(19),
            borderSide:
                const BorderSide(
              color:
                  AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  void save() {
    final parsedDays =
        number(
      standardDays,
    ).round();

    Navigator.pop(
      context,
      PaymentSettings(
        mode: mode,
        monthlySalary:
            number(salary),
        standardDays:
            parsedDays < 1
                ? 1
                : parsedDays > 31
                    ? 31
                    : parsedDays,
        normalHoursPerDay:
            number(normalHours),
        overtimeRate:
            number(overtimeRate),
        dailyWage:
            number(dailyWage),
        advance:
            number(advance),
        deduction:
            number(deduction),
      ),
    );
  }
}
