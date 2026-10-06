import 'package:flutter/material.dart';

class WorkerPayApp extends StatelessWidget {
  const WorkerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worker Pay',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF08658A),
        ),
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

  String dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  AttendanceData dataFor(DateTime date) {
    return attendance.putIfAbsent(
      dateKey(date),
      () => AttendanceData(),
    );
  }

  List<MapEntry<String, AttendanceData>> get currentMonthEntries {
    return attendance.entries.where((entry) {
      final parts = entry.key.split('-');

      if (parts.length != 3) {
        return false;
      }

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      return year == selectedMonth.year &&
          month == selectedMonth.month;
    }).toList();
  }

  int get presentCount {
    return currentMonthEntries
        .where(
          (e) => e.value.status == AttendanceStatus.present,
        )
        .length;
  }

  int get halfDayCount {
    return currentMonthEntries
        .where(
          (e) => e.value.status == AttendanceStatus.halfDay,
        )
        .length;
  }

  int get absentCount {
    return currentMonthEntries
        .where(
          (e) => e.value.status == AttendanceStatus.absent,
        )
        .length;
  }

  int get leaveCount {
    return currentMonthEntries
        .where(
          (e) => e.value.status == AttendanceStatus.leave,
        )
        .length;
  }

  int get holidayCount {
    return currentMonthEntries
        .where(
          (e) => e.value.status == AttendanceStatus.holiday,
        )
        .length;
  }

  int get totalHours {
    return currentMonthEntries.fold(
      0,
      (sum, entry) => sum + entry.value.normalHours,
    );
  }

  int get totalOt {
    return currentMonthEntries.fold(
      0,
      (sum, entry) => sum + entry.value.otHours,
    );
  }

  double get dailyWage {
    if (standardDays <= 0) {
      return 0;
    }

    return monthlySalary / standardDays;
  }

  double get basicPayment {
    double total = 0;

    for (final entry in currentMonthEntries) {
      final item = entry.value;

      if (item.status == AttendanceStatus.present) {
        total += dailyWage;
      } else if (item.status == AttendanceStatus.halfDay) {
        total += dailyWage / 2;
      }
    }

    return total;
  }

  double get otPayment {
    return totalOt * otRate;
  }

  double get netPayment {
    return basicPayment + otPayment - advance - deduction;
  }

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
        1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        1,
      );
    });
  }

  void openAttendance(DateTime date) {
    final oldData = dataFor(date);

    final copiedData = AttendanceData(
      status: oldData.status,
      normalHours: oldData.normalHours,
      otHours: oldData.otHours,
      note: oldData.note,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AttendanceSheet(
          date: date,
          data: copiedData,
          onSave: (newData) {
            setState(() {
              attendance[dateKey(date)] = newData;
            });
          },
        );
      },
    );
  }

  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return PaymentSettingsSheet(
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
          ) {
            setState(() {
              monthlySalary = salary;
              standardDays = days;
              normalHours = hours;
              otRate = rate;
              advance = adv;
              deduction = ded;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        height: 76,
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

  // ------------------------------------------------------------
  // MONTH SCREEN
  // ------------------------------------------------------------

  Widget monthScreen() {
    final monthName = _monthName(selectedMonth.month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Worker Pay',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 27,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF08658A),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: previousMonth,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 30,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$monthName ${selectedMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Tap a date to add attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: nextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 30,
                  ),
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
              const SizedBox(width: 8),
              statCard(
                'OT',
                '$totalOt H',
                Icons.timer_outlined,
              ),
              const SizedBox(width: 8),
              statCard(
                'Payment',
                '₹${netPayment.toStringAsFixed(0)}',
                Icons.currency_rupee,
              ),
            ],
          ),

          const SizedBox(height: 18),

          calendarCard(),
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
        constraints: const BoxConstraints(
          minHeight: 105,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD3DEE7),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF08658A),
              size: 23,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CALENDAR
  // ------------------------------------------------------------

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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        18,
        12,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD3DEE7),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Center(child: Text('SUN')),
              ),
              Expanded(
                child: Center(child: Text('MON')),
              ),
              Expanded(
                child: Center(child: Text('TUE')),
              ),
              Expanded(
                child: Center(child: Text('WED')),
              ),
              Expanded(
                child: Center(child: Text('THU')),
              ),
              Expanded(
                child: Center(child: Text('FRI')),
              ),
              Expanded(
                child: Center(child: Text('SAT')),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.78,
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

              final data = attendance[dateKey(date)];

              return GestureDetector(
                onTap: () => openAttendance(date),
                child: _calendarDay(
                  day,
                  data,
                ),
              );
            },
          ),

          const SizedBox(height: 17),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            runSpacing: 10,
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

  Widget _calendarDay(
    int day,
    AttendanceData? data,
  ) {
    final color = data == null
        ? const Color(0xFFD1DCE5)
        : statusColor(data.status);

    return Container(
      decoration: BoxDecoration(
        color: data == null
            ? const Color(0xFFF8FAFC)
            : color.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: data == null ? 1 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (data == null)
            const Icon(
              Icons.add,
              size: 18,
              color: Colors.black38,
            )
          else ...[
            Text(
              '${data.normalHours}H',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (data.otHours > 0)
              Text(
                'OT ${data.otHours}H',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1477B8),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget legend(
    String text,
    Color color,
  ) {
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
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // YEAR SCREEN
  // ------------------------------------------------------------

  Widget yearScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            16,
            8,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Year Calendar',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 28,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              20,
            ),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, index) {
              final month = index + 1;

              final stats = monthStats(
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD3DEE7),
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

                      const SizedBox(height: 3),

                      Text(
                        '${selectedMonth.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'P ${stats['present']}',
                              style: const TextStyle(
                                color: Color(0xFF168447),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'A ${stats['absent']}',
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'H ${stats['halfDay']}',
                              style: const TextStyle(
                                color: Color(0xFFD55A18),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'OT ${stats['ot']}H',
                              style: const TextStyle(
                                color: Color(0xFF1477B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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

  Map<String, int> monthStats(
    int year,
    int month,
  ) {
    int present = 0;
    int absent = 0;
    int halfDay = 0;
    int ot = 0;

    for (final entry in attendance.entries) {
      final parts = entry.key.split('-');

      if (parts.length != 3) {
        continue;
      }

      final entryYear = int.tryParse(parts[0]);
      final entryMonth = int.tryParse(parts[1]);

      if (entryYear != year || entryMonth != month) {
        continue;
      }

      final data = entry.value;

      if (data.status == AttendanceStatus.present) {
        present++;
      }

      if (data.status == AttendanceStatus.absent) {
        absent++;
      }

      if (data.status == AttendanceStatus.halfDay) {
        halfDay++;
      }

      ot += data.otHours;
    }

    return {
      'present': present,
      'absent': absent,
      'halfDay': halfDay,
      'ot': ot,
    };
  }

  // ------------------------------------------------------------
  // SUMMARY SCREEN
  // ------------------------------------------------------------

  Widget summaryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 27,
                ),
              ),
            ],
          ),

          Text(
            '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 18),

          estimatedPaymentCard(),

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
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Divider(),
              ),
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

  Widget estimatedPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        25,
        24,
        22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF08658A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Net Payment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${netPayment.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

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
    );
  }

  Widget summaryPill(
    String title,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.14),
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
                fontSize: 15,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
      padding: const EdgeInsets.fromLTRB(
        22,
        22,
        22,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD3DEE7),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
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
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: bold
                  ? const Color(0xFF168447)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ATTENDANCE ENTRY
  // ------------------------------------------------------------

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

    noteController = TextEditingController(
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
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * .92,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FB),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                    ),
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
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AttendanceStatus.values
                    .map(
                      (value) {
                        final selected =
                            status == value;

                        return ChoiceChip(
                          label: Text(
                            _status(value),
                            style: TextStyle(
                              fontSize: 15,
                              color: selected
                                  ? colorFor(value)
                                  : Colors.black87,
                            ),
                          ),
                          selected: selected,
                          selectedColor:
                              colorFor(value)
                                  .withOpacity(.16),
                          backgroundColor:
                              Colors.white,
                          side: BorderSide(
                            color: selected
                                ? colorFor(value)
                                : const Color(
                                    0xFFC8D1D9,
                                  ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              status = value;

                              if (value ==
                                  AttendanceStatus.halfDay) {
                                hours = 4;
                              } else if (value ==
                                  AttendanceStatus.present) {
                                hours = 8;
                              }
                            });
                          },
                        );
                      },
                    )
                    .toList(),
              ),

              const SizedBox(height: 22),

              const Text(
                'Normal Working Hours',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              _optionRow(
                values: const [4, 8, 10],
                selected: hours,
                suffix: 'H',
                onSelected: (value) {
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

              const SizedBox(height: 22),

              const Text(
                'Overtime (OT) Hours',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              _optionRow(
                values: const [0, 2, 4],
                selected: otHours,
                suffix: 'H',
                selectedColor:
                    const Color(0xFF1477B8),
                onSelected: (value) {
                  setState(() {
                    otHours = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Optional note...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.all(18),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFC8D1D9),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFC8D1D9),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onSave(
                      AttendanceData(
                        status: status,
                        normalHours: hours,
                        otHours: otHours,
                        note: noteController.text,
                      ),
                    );

                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Save Attendance',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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

  Widget _optionRow({
    required List<int> values,
    required int selected,
    required String suffix,
    required Function(int) onSelected,
    Color selectedColor =
        const Color(0xFF08658A),
  }) {
    return Row(
      children: values.map((value) {
        final isSelected = selected == value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: value == values.last ? 0 : 8,
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(16),
              onTap: () {
                onSelected(value);
              },
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor
                          .withOpacity(.13)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? selectedColor
                        : const Color(
                            0xFFC8D1D9,
                          ),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 19,
                        color: selectedColor,
                      ),
                    if (isSelected)
                      const SizedBox(width: 6),
                    Text(
                      '$value$suffix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? selectedColor
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

// ------------------------------------------------------------
// PAYMENT SETTINGS
// ------------------------------------------------------------

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

  double number(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  int integer(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * .90,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FB),
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

              const SizedBox(height: 8),

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
                    style: TextStyle(
                      fontSize: 17,
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

  Widget field(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFC8D1D9),
            ),
          ),
        ),
      ),
    );
  }
}
