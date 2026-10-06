import 'package:flutter/material.dart';
import 'storage_service.dart';

class WorkerPayApp extends StatelessWidget {
  const WorkerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worker Pay',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF08658A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FC),
      ),
      home: const WorkerPayHome(),
    );
  }
}

enum AttendanceStatus {
  present,
  halfDay,
  absent,
  leave,
  holiday,
}

class AttendanceData {
  AttendanceStatus status;
  int normalHours;
  int otHours;
  String note;

  AttendanceData({
    this.status = AttendanceStatus.present,
    this.normalHours = 8,
    this.otHours = 0,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'normalHours': normalHours,
      'otHours': otHours,
      'note': note,
    };
  }

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;

    final status = AttendanceStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => AttendanceStatus.present,
    );

    return AttendanceData(
      status: status,
      normalHours: (json['normalHours'] as num?)?.toInt() ?? 8,
      otHours: (json['otHours'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}

class WorkerPayHome extends StatefulWidget {
  const WorkerPayHome({super.key});

  @override
  State<WorkerPayHome> createState() => _WorkerPayHomeState();
}

class _WorkerPayHomeState extends State<WorkerPayHome> {
  int selectedTab = 0;
  DateTime selectedMonth = DateTime.now();

  final Map<String, AttendanceData> attendance = {};

  double monthlySalary = 16200;
  int standardDays = 30;
  int normalHours = 8;
  double otRate = 67.50;
  double advance = 0;
  double deduction = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  String dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> loadSavedData() async {
    final savedAttendance =
        await StorageService.instance.loadAttendance();

    final savedSettings =
        await StorageService.instance.loadSettings();

    if (!mounted) return;

    setState(() {
      attendance.clear();

      savedAttendance.forEach((key, value) {
        if (value is Map) {
          attendance[key] = AttendanceData.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });

      monthlySalary =
          (savedSettings['monthlySalary'] as num?)?.toDouble() ??
              monthlySalary;

      standardDays =
          (savedSettings['standardDays'] as num?)?.toInt() ??
              standardDays;

      normalHours =
          (savedSettings['normalHours'] as num?)?.toInt() ??
              normalHours;

      otRate =
          (savedSettings['otRate'] as num?)?.toDouble() ??
              otRate;

      advance =
          (savedSettings['advance'] as num?)?.toDouble() ??
              advance;

      deduction =
          (savedSettings['deduction'] as num?)?.toDouble() ??
              deduction;

      loading = false;
    });
  }

  Future<void> saveAttendanceData() async {
    final data = <String, dynamic>{};

    attendance.forEach((key, value) {
      data[key] = value.toJson();
    });

    await StorageService.instance.saveAttendance(data);
  }

  Future<void> savePaymentSettings() async {
    await StorageService.instance.saveSettings({
      'monthlySalary': monthlySalary,
      'standardDays': standardDays,
      'normalHours': normalHours,
      'otRate': otRate,
      'advance': advance,
      'deduction': deduction,
    });
  }

  int get presentCount => attendance.values
      .where((e) => e.status == AttendanceStatus.present)
      .length;

  int get halfDayCount => attendance.values
      .where((e) => e.status == AttendanceStatus.halfDay)
      .length;

  int get absentCount => attendance.values
      .where((e) => e.status == AttendanceStatus.absent)
      .length;

  int get leaveCount => attendance.values
      .where((e) => e.status == AttendanceStatus.leave)
      .length;

  int get holidayCount => attendance.values
      .where((e) => e.status == AttendanceStatus.holiday)
      .length;

  int get totalHours =>
      attendance.values.fold(0, (sum, e) => sum + e.normalHours);

  int get totalOt =>
      attendance.values.fold(0, (sum, e) => sum + e.otHours);

  double get dailyWage =>
      standardDays <= 0 ? 0 : monthlySalary / standardDays;

  double get basicPayment {
    double total = 0;

    for (final item in attendance.values) {
      if (item.status == AttendanceStatus.present) {
        total += dailyWage;
      } else if (item.status == AttendanceStatus.halfDay) {
        total += dailyWage / 2;
      }
    }

    return total;
  }

  double get otPayment => totalOt * otRate;

  double get netPayment =>
      basicPayment + otPayment - advance - deduction;

  Color statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF168447);
      case AttendanceStatus.halfDay:
        return const Color(0xFFD55A18);
      case AttendanceStatus.absent:
        return const Color(0xFFC62828);
      case AttendanceStatus.leave:
        return const Color(0xFFD9A400);
      case AttendanceStatus.holiday:
        return const Color(0xFF7136C5);
    }
  }

  String statusText(AttendanceStatus status) {
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

  void openAttendance(DateTime date) {
    final oldData = attendance[dateKey(date)];

    final data = oldData == null
        ? AttendanceData()
        : AttendanceData(
            status: oldData.status,
            normalHours: oldData.normalHours,
            otHours: oldData.otHours,
            note: oldData.note,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceSheet(
        date: date,
        data: data,
        onSave: (newData) async {
          setState(() {
            attendance[dateKey(date)] = newData;
          });

          await saveAttendanceData();
        },
      ),
    );
  }

  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSettingsSheet(
        monthlySalary: monthlySalary,
        standardDays: standardDays,
        normalHours: normalHours,
        otRate: otRate,
        advance: advance,
        deduction: deduction,
        onSave: (
          salary,
          days,
          hours,
          rate,
          adv,
          ded,
        ) async {
          setState(() {
            monthlySalary = salary;
            standardDays = days;
            normalHours = hours;
            otRate = rate;
            advance = adv;
            deduction = ded;
          });

          await savePaymentSettings();
        },
      ),
    );
  }

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
            monthScreen(),
            yearScreen(),
            summaryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Year',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
        ],
      ),
    );
  }

  Widget monthScreen() {
    final monthName = _monthName(selectedMonth.month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Worker Pay',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF08658A),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$monthName ${selectedMonth.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Tap a date to add attendance',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              statCard(
                'Hours',
                '$totalHours H',
                Icons.access_time,
              ),
              statCard(
                'OT',
                '$totalOt H',
                Icons.timer_outlined,
              ),
              statCard(
                'Payment',
                '₹${netPayment.toStringAsFixed(0)}',
                Icons.currency_rupee,
              ),
            ],
          ),
          const SizedBox(height: 18),
          calendarCard(),
          const SizedBox(height: 18),
          summaryPreview(),
        ],
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD2DEE8),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF08658A),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget calendarCard() {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final startOffset = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD2DEE8),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: const [
              Text('SUN'),
              Text('MON'),
              Text('TUE'),
              Text('WED'),
              Text('THU'),
              Text('FRI'),
              Text('SAT'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: .82,
            ),
            itemBuilder: (_, index) {
              if (index < startOffset) {
                return const SizedBox();
              }

              final day = index - startOffset + 1;

              final date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                day,
              );

              final data =
                  attendance[dateKey(date)];

              return GestureDetector(
                onTap: () => openAttendance(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: data == null
                        ? const Color(0xFFF8FAFC)
                        : statusColor(data.status)
                            .withOpacity(.10),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: data == null
                          ? const Color(0xFFD1DCE5)
                          : statusColor(data.status),
                      width: data == null ? 1 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (data == null)
                        const Icon(
                          Icons.add,
                          size: 17,
                          color: Colors.black26,
                        )
                      else ...[
                        Text(
                          '${data.normalHours}H',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                statusColor(data.status),
                          ),
                        ),
                        if (data.otHours > 0)
                          Text(
                            'OT ${data.otHours}H',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color:
                                  Color(0xFF1477B8),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              legend(
                'Present',
                const Color(0xFF168447),
              ),
              legend(
                'Half Day',
                const Color(0xFFD55A18),
              ),
              legend(
                'Absent',
                const Color(0xFFC62828),
              ),
              legend(
                'Leave',
                const Color(0xFFD9A400),
              ),
              legend(
                'Holiday',
                const Color(0xFF7136C5),
              ),
              legend(
                'OT',
                const Color(0xFF1477B8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget legend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 5,
          backgroundColor: color,
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }

  Widget summaryPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD2DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),
          const SizedBox(height: 14),
          Text('Present: $presentCount'),
          Text('Half Day: $halfDayCount'),
          Text('Absent: $absentCount'),
          Text('Leave: $leaveCount'),
          Text('Holiday: $holidayCount'),
          Text('OT Hours: $totalOt H'),
        ],
      ),
    );
  }

  Widget yearScreen() {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Year Calendar',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, index) {
              final month = index + 1;

              final stats =
                  monthStatistics(
                selectedMonth.year,
                month,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMonth = DateTime(
                      selectedMonth.year,
                      month,
                      1,
                    );
                    selectedTab = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD2DEE8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _monthName(month),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${selectedMonth.year}',
                      ),
                      const Spacer(),
                      Text(
                        'P ${stats.present}   A ${stats.absent}',
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'H ${stats.halfDay}   OT ${stats.ot}H',
                        style: const TextStyle(
                          color: Color(0xFF1477B8),
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
    );
  }

  _MonthStats monthStatistics(
    int year,
    int month,
  ) {
    int present = 0;
    int absent = 0;
    int halfDay = 0;
    int ot = 0;

    for (final entry in attendance.entries) {
      final parts = entry.key.split('-');

      if (parts.length != 3) continue;

      final entryYear = int.tryParse(parts[0]);
      final entryMonth = int.tryParse(parts[1]);

      if (entryYear == year && entryMonth == month) {
        final item = entry.value;

        if (item.status ==
            AttendanceStatus.present) {
          present++;
        }

        if (item.status ==
            AttendanceStatus.absent) {
          absent++;
        }

        if (item.status ==
            AttendanceStatus.halfDay) {
          halfDay++;
        }

        ot += item.otHours;
      }
    }

    return _MonthStats(
      present: present,
      absent: absent,
      halfDay: halfDay,
      ot: ot,
    );
  }

  Widget summaryScreen() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(20, 22, 20, 30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                ),
              ),
            ],
          ),
          Text(
            '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF08658A),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Net Payment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${netPayment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    summaryPill(
                      'Hours',
                      '$totalHours H',
                    ),
                    const SizedBox(width: 10),
                    summaryPill(
                      'OT',
                      '$totalOt H',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          sectionCard(
            'Attendance',
            [
              summaryRow(
                'Present',
                '$presentCount',
              ),
              summaryRow(
                'Absent',
                '$absentCount',
              ),
              summaryRow(
                'Half Day',
                '$halfDayCount',
              ),
              summaryRow(
                'Leave',
                '$leaveCount',
              ),
              summaryRow(
                'Holiday',
                '$holidayCount',
              ),
            ],
          ),
          const SizedBox(height: 18),
          sectionCard(
            'Working Time',
            [
              summaryRow(
                'Working Hours',
                '$totalHours H',
              ),
              summaryRow(
                'OT Hours',
                '$totalOt H',
              ),
            ],
          ),
          const SizedBox(height: 18),
          sectionCard(
            'Payment',
            [
              summaryRow(
                'Monthly Salary',
                '₹${monthlySalary.toStringAsFixed(0)}',
              ),
              summaryRow(
                'Daily Wage',
                '₹${dailyWage.toStringAsFixed(0)}',
              ),
              summaryRow(
                'OT Rate',
                '₹${otRate.toStringAsFixed(2)}/H',
              ),
              summaryRow(
                'Basic Payment',
                '₹${basicPayment.toStringAsFixed(0)}',
              ),
              summaryRow(
                'OT Payment',
                '₹${otPayment.toStringAsFixed(0)}',
              ),
              summaryRow(
                'Advance',
                '- ₹${advance.toStringAsFixed(0)}',
              ),
              summaryRow(
                'Deduction',
                '- ₹${deduction.toStringAsFixed(0)}',
              ),
              const Divider(height: 25),
              summaryRow(
                'Net Payment',
                '₹${netPayment.toStringAsFixed(0)}',
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget summaryPill(
    String title,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.13),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard(
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD2DEE8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget summaryRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.w600,
              color: bold
                  ? const Color(0xFF168447)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
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

    return months[month];
  }
}

class _MonthStats {
  final int present;
  final int absent;
  final int halfDay;
  final int ot;

  _MonthStats({
    required this.present,
    required this.absent,
    required this.halfDay,
    required this.ot,
  });
}

class AttendanceSheet extends StatefulWidget {
  final DateTime date;
  final AttendanceData data;
  final Function(AttendanceData) onSave;

  const AttendanceSheet({
    super.key,
    required this.date,
    required this.data,
    required this.onSave,
  });

  @override
  State<AttendanceSheet> createState() =>
      _AttendanceSheetState();
}

class _AttendanceSheetState
    extends State<AttendanceSheet> {
  late AttendanceStatus status;
  late int hours;
  late int otHours;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    status = widget.data.status;
    hours = widget.data.normalHours;
    otHours = widget.data.otHours;

    noteController =
        TextEditingController(
      text: widget.data.note,
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Color colorFor(AttendanceStatus value) {
    switch (value) {
      case AttendanceStatus.present:
        return const Color(0xFF168447);
      case AttendanceStatus.halfDay:
        return const Color(0xFFD55A18);
      case AttendanceStatus.absent:
        return const Color(0xFFC62828);
      case AttendanceStatus.leave:
        return const Color(0xFFD9A400);
      case AttendanceStatus.holiday:
        return const Color(0xFF7136C5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8FC),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Attendance Entry',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
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
              Text(
                '${widget.date.day} ${_month(widget.date.month)} ${widget.date.year}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    AttendanceStatus.values.map(
                  (value) {
                    return ChoiceChip(
                      label: Text(
                        _status(value),
                      ),
                      selected:
                          status == value,
                      selectedColor:
                          colorFor(value)
                              .withOpacity(.18),
                      onSelected: (_) {
                        setState(() {
                          status = value;

                          if (value ==
                              AttendanceStatus.halfDay) {
                            hours = 4;
                          } else if (value ==
                              AttendanceStatus.present) {
                            if (hours == 4) {
                              hours = 8;
                            }
                          }
                        });
                      },
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Normal Working Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [4, 8, 10].map(
                  (value) {
                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 8,
                        ),
                        child: ChoiceChip(
                          label: Text('${value}H'),
                          selected:
                              hours == value,
                          onSelected: (_) {
                            setState(() {
                              hours = value;

                              if (value == 4) {
                                status =
                                    AttendanceStatus.halfDay;
                              } else {
                                status =
                                    AttendanceStatus.present;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Overtime (OT) Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [0, 2, 4].map(
                  (value) {
                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 8,
                        ),
                        child: ChoiceChip(
                          label: Text('${value}H'),
                          selected:
                              otHours == value,
                          onSelected: (_) {
                            setState(() {
                              otHours = value;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Optional note...',
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onSave(
                      AttendanceData(
                        status: status,
                        normalHours: hours,
                        otHours: otHours,
                        note:
                            noteController.text,
                      ),
                    );

                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Save Attendance',
                    style:
                        TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _status(AttendanceStatus value) {
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

  String _month(int month) {
    const names = [
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

    return names[month];
  }
}

class PaymentSettingsSheet extends StatefulWidget {
  final double monthlySalary;
  final int standardDays;
  final int normalHours;
  final double otRate;
  final double advance;
  final double deduction;

  final Function(
    double,
    int,
    int,
    double,
    double,
    double,
  ) onSave;

  const PaymentSettingsSheet({
    super.key,
    required this.monthlySalary,
    required this.standardDays,
    required this.normalHours,
    required this.otRate,
    required this.advance,
    required this.deduction,
    required this.onSave,
  });

  @override
  State<PaymentSettingsSheet> createState() =>
      _PaymentSettingsSheetState();
}

class _PaymentSettingsSheetState
    extends State<PaymentSettingsSheet> {
  late TextEditingController salary;
  late TextEditingController days;
  late TextEditingController hours;
  late TextEditingController rate;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    salary = TextEditingController(
      text: widget.monthlySalary.toString(),
    );

    days = TextEditingController(
      text: widget.standardDays.toString(),
    );

    hours = TextEditingController(
      text: widget.normalHours.toString(),
    );

    rate = TextEditingController(
      text: widget.otRate.toString(),
    );

    advance = TextEditingController(
      text: widget.advance.toString(),
    );

    deduction = TextEditingController(
      text: widget.deduction.toString(),
    );
  }

  @override
  void dispose() {
    salary.dispose();
    days.dispose();
    hours.dispose();
    rate.dispose();
    advance.dispose();
    deduction.dispose();
    super.dispose();
  }

  double number(String value) =>
      double.tryParse(value.trim()) ?? 0;

  int integer(String value) =>
      int.tryParse(value.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8FC),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Configuration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              field(
                'Monthly Salary',
                salary,
                Icons.currency_rupee,
              ),
              field(
                'Standard Working Days per Month',
                days,
                Icons.calendar_month,
              ),
              field(
                'Normal Working Hours per Day',
                hours,
                Icons.access_time,
              ),
              field(
                'Overtime OT Rate per Hour',
                rate,
                Icons.timer_outlined,
              ),
              field(
                'Optional Advance',
                advance,
                Icons.account_balance_wallet_outlined,
              ),
              field(
                'Deduction',
                deduction,
                Icons.remove_circle_outline,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onSave(
                      number(salary.text),
                      integer(days.text),
                      integer(hours.text),
                      number(rate.text),
                      number(advance.text),
                      number(deduction.text),
                    );

                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Configuration',
                    style:
                        TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
