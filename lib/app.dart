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
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF3F7FD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF08658D),
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
  double normalHours;
  double otHours;
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
  int _selectedTab = 0;

  DateTime _month = DateTime.now();

  final Map<String, AttendanceData> _attendance = {};

  double monthlySalary = 00000;
  double standardWorkingDays = 30;
  double otRate = 00000;
  double advance = 0;
  double deduction = 0;

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  AttendanceData? _getAttendance(DateTime date) {
    return _attendance[_dateKey(date)];
  }

  void _saveAttendance(
    DateTime date,
    AttendanceData data,
  ) {
    setState(() {
      _attendance[_dateKey(date)] = data;
    });
  }

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month + amount,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _monthScreen(),
            _yearScreen(),
            _summaryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  Widget _bottomNavigation() {
    return NavigationBar(
      height: 78,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDCECF6),
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) {
        setState(() {
          _selectedTab = index;
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
    );
  }

  // ------------------------------------------------------------
  // MONTH
  // ------------------------------------------------------------

  Widget _monthScreen() {
    final stats = _monthStats(_month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Worker Pay',
            Icons.settings_outlined,
            () => _showSettings(),
          ),
          const SizedBox(height: 18),
          _monthSelector(),
          const SizedBox(height: 18),
          _topStats(stats),
          const SizedBox(height: 18),
          _calendarCard(),
          const SizedBox(height: 18),
          _monthlyMiniSummary(stats),
        ],
      ),
    );
  }

  Widget _pageHeader(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: Color(0xFF07162D),
            ),
          ),
        ),
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            size: 31,
            color: const Color(0xFF07162D),
          ),
        ),
      ],
    );
  }

  Widget _monthSelector() {
    final title =
        '${_monthName(_month.month)} ${_month.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF08678E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 34,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _month = DateTime.now();
                });
              },
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tap for current month',
                    style: TextStyle(
                      color: Color(0xFFBBD9E7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _smallStatCard(
            Icons.access_time,
            'Hours',
            '${stats['hours']}',
            const Color(0xFF17698D),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            Icons.timer_outlined,
            'OT',
            '${stats['ot']}',
            const Color(0xFFC04A1C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            Icons.currency_rupee,
            'Payment',
            '₹${_money(stats['payment'])}',
            const Color(0xFF19804B),
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard(
    IconData icon,
    String title,
    String value,
    Color valueColor,
  ) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFC7D3DF),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: valueColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF536170),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CALENDAR
  // ------------------------------------------------------------

  Widget _calendarCard() {
    final daysInMonth = DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final firstDay = DateTime(
      _month.year,
      _month.month,
      1,
    );

    final startOffset = firstDay.weekday % 7;

    final totalCells =
        ((startOffset + daysInMonth) / 7).ceil() * 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFC7D3DF),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              _WeekDay('SUN'),
              _WeekDay('MON'),
              _WeekDay('TUE'),
              _WeekDay('WED'),
              _WeekDay('THU'),
              _WeekDay('FRI'),
              _WeekDay('SAT'),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 5,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset ||
                  index >= startOffset + daysInMonth) {
                return const SizedBox();
              }

              final day = index - startOffset + 1;

              final date = DateTime(
                _month.year,
                _month.month,
                day,
              );

              return _calendarDay(date);
            },
          ),
          const SizedBox(height: 16),
          _legend(),
        ],
      ),
    );
  }

  Widget _calendarDay(DateTime date) {
    final data = _getAttendance(date);
    final isToday = _sameDay(date, DateTime.now());

    Color border = const Color(0xFFC7D3DF);
    Color background = const Color(0xFFF8FAFD);
    Color textColor = const Color(0xFF172236);

    String bottom = '+';

    if (data != null) {
      bottom = '${_formatHours(data.normalHours)}H';

      switch (data.status) {
        case AttendanceStatus.present:
          border = const Color(0xFF2C9660);
          background = const Color(0xFFF0F9F3);
          textColor = const Color(0xFF217A4B);
          break;

        case AttendanceStatus.halfDay:
          border = const Color(0xFFC94F1C);
          background = const Color(0xFFFFF5EF);
          textColor = const Color(0xFFC34B1A);
          break;

        case AttendanceStatus.absent:
          border = const Color(0xFFBC2732);
          background = const Color(0xFFFFF0F1);
          textColor = const Color(0xFFB3212B);
          break;

        case AttendanceStatus.leave:
          border = const Color(0xFFD29B00);
          background = const Color(0xFFFFFAE8);
          textColor = const Color(0xFFB27C00);
          break;

        case AttendanceStatus.holiday:
          border = const Color(0xFF7131C9);
          background = const Color(0xFFF6F0FF);
          textColor = const Color(0xFF6D2DBF);
          break;
      }
    }

    if (isToday) {
      border = const Color(0xFF08678E);
      background = const Color(0xFFEAF6FB);
    }

    return GestureDetector(
      onTap: () => _showAttendance(date),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: border,
            width: isToday ? 2.7 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              bottom,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: data == null
                    ? const Color(0xFFB5C0CC)
                    : textColor,
              ),
            ),
            if (data != null && data.otHours > 0)
              Text(
                'OT ${_formatHours(data.otHours)}H',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF17698D),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 13,
      runSpacing: 8,
      children: const [
        _LegendItem('Present', Color(0xFF17824A)),
        _LegendItem('Half Day', Color(0xFFC74B18)),
        _LegendItem('Absent', Color(0xFFB8242E)),
        _LegendItem('Holiday', Color(0xFF7130C8)),
        _LegendItem('OT', Color(0xFF17698D)),
      ],
    );
  }

  Widget _monthlyMiniSummary(Map<String, dynamic> stats) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${_monthName(_month.month)} ${_month.year}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF657181),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryChip(
                'Present',
                '${stats['present']}',
                const Color(0xFF19804B),
              ),
              _summaryChip(
                'Absent',
                '${stats['absent']}',
                const Color(0xFFB52830),
              ),
              _summaryChip(
                'Half Day',
                '${stats['half']}',
                const Color(0xFFC34B1A),
              ),
              _summaryChip(
                'Holiday',
                '${stats['holiday']}',
                const Color(0xFF7131C9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // YEAR
  // ------------------------------------------------------------

  Widget _yearScreen() {
    final year = _month.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Year Overview',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: Color(0xFF07162D),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$year  •  Monthly Attendance',
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF667384),
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              return _yearMonthCard(
                year,
                index + 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _yearMonthCard(
    int year,
    int month,
  ) {
    final stats = _monthStats(
      DateTime(year, month, 1),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _month = DateTime(year, month, 1);
          _selectedTab = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFC7D3DF),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthName(month),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFB4C1CD),
                ),
              ],
            ),
            Text(
              '$year',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF788493),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _yearStat(
                  'P',
                  '${stats['present']}',
                  const Color(0xFF19804B),
                ),
                _yearStat(
                  'A',
                  '${stats['absent']}',
                  const Color(0xFFB52830),
                ),
                _yearStat(
                  'H',
                  '${stats['half']}',
                  const Color(0xFFC34B1A),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 17,
                  color: Color(0xFFC04A1C),
                ),
                const SizedBox(width: 5),
                Text(
                  'OT ${stats['ot']}H',
                  style: const TextStyle(
                    color: Color(0xFFC04A1C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearStat(
    String label,
    String value,
    Color color,
  ) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1C2838),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  Widget _summaryScreen() {
    final stats = _monthStats(_month);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Monthly Summary',
            Icons.settings_outlined,
            () => _showSettings(),
          ),
          const SizedBox(height: 4),
          Text(
            '${_monthName(_month.month)} ${_month.year}',
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF687585),
            ),
          ),
          const SizedBox(height: 20),
          _paymentHero(stats),
          const SizedBox(height: 18),
          _attendanceSummaryCard(stats),
          const SizedBox(height: 18),
          _workingTimeCard(stats),
          const SizedBox(height: 18),
          _paymentCard(stats),
        ],
      ),
    );
  }

  Widget _paymentHero(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        30,
        30,
        30,
        28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF08678E),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Net Payment',
            style: TextStyle(
              color: Color(0xFFD6E7EF),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '₹${_money(stats['payment'])}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _heroSmall(
                  'Hours',
                  '${stats['hours']}H',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _heroSmall(
                  'OT',
                  '${stats['ot']}H',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSmall(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD4E5ED),
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceSummaryCard(
    Map<String, dynamic> stats,
  ) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.event_available,
            title: 'Attendance',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _attendanceTile(
                  'Present',
                  '${stats['present']}',
                  Icons.check_circle_outline,
                  const Color(0xFF19804B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attendanceTile(
                  'Absent',
                  '${stats['absent']}',
                  Icons.cancel_outlined,
                  const Color(0xFFB52830),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _attendanceTile(
                  'Half Day',
                  '${stats['half']}',
                  Icons.timelapse,
                  const Color(0xFFC34B1A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attendanceTile(
                  'Holiday',
                  '${stats['holiday']}',
                  Icons.beach_access_outlined,
                  const Color(0xFF7131C9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF536170),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workingTimeCard(
    Map<String, dynamic> stats,
  ) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.access_time,
            title: 'Working Time',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _timeBox(
                  'Working Hours',
                  '${stats['hours']} H',
                  const Color(0xFF17698D),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _timeBox(
                  'OT Hours',
                  '${stats['ot']} H',
                  const Color(0xFFC34B1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF536170),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(
    Map<String, dynamic> stats,
  ) {
    final dailyWage =
        standardWorkingDays == 0
            ? 0
            : monthlySalary / standardWorkingDays;

    final basic =
        stats['present'] * dailyWage +
        stats['half'] * dailyWage * .5;

    final otPayment =
        stats['ot'] * otRate;

    final net =
        basic + otPayment - advance - deduction;

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.currency_rupee,
            title: 'Payment',
          ),
          const SizedBox(height: 20),
          _paymentRow(
            'Monthly Salary',
            '₹${_money(monthlySalary)}',
          ),
          _paymentRow(
            'Daily Wage',
            '₹${_money(dailyWage)}',
          ),
          _paymentRow(
            'OT Rate',
            '₹${_money(otRate)}/H',
          ),
          const Divider(height: 30),
          _paymentRow(
            'Basic Payment',
            '₹${_money(basic)}',
            bold: true,
          ),
          _paymentRow(
            'OT Payment',
            '₹${_money(otPayment)}',
          ),
          _paymentRow(
            'Advance',
            '- ₹${_money(advance)}',
            color: const Color(0xFFB52830),
          ),
          _paymentRow(
            'Deduction',
            '- ₹${_money(deduction)}',
            color: const Color(0xFFB52830),
          ),
          const Divider(height: 30),
          _paymentRow(
            'Net Payment',
            '₹${_money(net)}',
            bold: true,
            valueColor: const Color(0xFF19804B),
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String title,
    String value, {
    bool bold = false,
    Color? color,
    Color? valueColor,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: large ? 19 : 16,
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.w400,
                color: color ?? const Color(0xFF344152),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 24 : 16,
              fontWeight:
                  bold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ??
                  color ??
                  const Color(0xFF182334),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFC7D3DF),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // ATTENDANCE ENTRY
  // ------------------------------------------------------------

  void _showAttendance(DateTime date) {
    final existing =
        _getAttendance(date) ??
        AttendanceData();

    final normalController = TextEditingController(
      text: '${_formatHours(existing.normalHours)}H',
    );

    final otController = TextEditingController(
      text: '${_formatHours(existing.otHours)}H',
    );

    final noteController = TextEditingController(
      text: existing.note,
    );

    AttendanceStatus selectedStatus =
        existing.status;

    double selectedNormal =
        existing.normalHours;

    double selectedOt =
        existing.otHours;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * .94,
                padding: EdgeInsets.only(
                  left: 28,
                  right: 28,
                  top: 10,
                  bottom: MediaQuery.of(context)
                      .viewInsets
                      .bottom,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7C1CD),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFDDEBF5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.event_available,
                                    color:
                                        Color(0xFF08678E),
                                    size: 35,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Attendance Entry',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                    sheetContext,
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)} ${date.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                color:
                                    Color(0xFF647181),
                              ),
                            ),
                            const SizedBox(height: 30),

                            const _FormTitle('Status'),
                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _statusButton(
                                  'Present',
                                  AttendanceStatus.present,
                                  selectedStatus,
                                  (value) {
                                    setSheetState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  },
                                ),
                                _statusButton(
                                  'Half Day',
                                  AttendanceStatus.halfDay,
                                  selectedStatus,
                                  (value) {
                                    setSheetState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  },
                                ),
                                _statusButton(
                                  'Absent',
                                  AttendanceStatus.absent,
                                  selectedStatus,
                                  (value) {
                                    setSheetState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  },
                                ),
                                _statusButton(
                                  'Leave',
                                  AttendanceStatus.leave,
                                  selectedStatus,
                                  (value) {
                                    setSheetState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  },
                                ),
                                _statusButton(
                                  'Holiday',
                                  AttendanceStatus.holiday,
                                  selectedStatus,
                                  (value) {
                                    setSheetState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            const _FormTitle(
                              'Normal Working Hours',
                            ),
                            const SizedBox(height: 12),

                            _hoursTextField(
                              controller:
                                  normalController,
                              onChanged: (_) {},
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _hourQuickButton(
                                    '4H',
                                    selectedNormal == 4,
                                    () {
                                      setSheetState(() {
                                        selectedNormal =
                                            4;
                                        normalController
                                            .text = '4H';
                                        normalController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                normalController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _hourQuickButton(
                                    '8H',
                                    selectedNormal == 8,
                                    () {
                                      setSheetState(() {
                                        selectedNormal =
                                            8;
                                        normalController
                                            .text = '8H';
                                        normalController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                normalController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _hourQuickButton(
                                    '10H',
                                    selectedNormal == 10,
                                    () {
                                      setSheetState(() {
                                        selectedNormal =
                                            10;
                                        normalController
                                            .text = '10H';
                                        normalController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                normalController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            const _FormTitle(
                              'Overtime (OT) Hours',
                            ),
                            const SizedBox(height: 12),

                            _hoursTextField(
                              controller: otController,
                              onChanged: (_) {},
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _hourQuickButton(
                                    '0H',
                                    selectedOt == 0,
                                    () {
                                      setSheetState(() {
                                        selectedOt =
                                            0;
                                        otController
                                            .text = '0H';
                                        otController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                otController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _hourQuickButton(
                                    '4H',
                                    selectedOt == 4,
                                    () {
                                      setSheetState(() {
                                        selectedOt =
                                            4;
                                        otController
                                            .text = '4H';
                                        otController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                otController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _hourQuickButton(
                                    '16H',
                                    selectedOt == 16,
                                    () {
                                      setSheetState(() {
                                        selectedOt =
                                            16;
                                        otController
                                            .text = '16H';
                                        otController
                                                .selection =
                                            TextSelection
                                                .fromPosition(
                                          TextPosition(
                                            offset:
                                                otController
                                                    .text
                                                    .length,
                                          ),
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            const _FormTitle('Note'),
                            const SizedBox(height: 10),

                            TextField(
                              controller: noteController,
                              minLines: 3,
                              maxLines: 5,
                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Optional note...',
                                prefixIcon:
                                    const Padding(
                                  padding:
                                      EdgeInsets.only(
                                    left: 16,
                                    right: 8,
                                    top: 15,
                                  ),
                                  child: Icon(
                                    Icons
                                        .notes_outlined,
                                  ),
                                ),
                                filled: true,
                                fillColor:
                                    Colors.white,
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(24),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Color(0xFFC5D2DF),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(24),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Color(0xFFC5D2DF),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(24),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Color(0xFF08678E),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            SizedBox(
                              width: double.infinity,
                              height: 62,
                              child: FilledButton.icon(
                                onPressed: () {
                                  final normal =
                                      _parseHours(
                                    normalController.text,
                                    selectedNormal,
                                  );

                                  final ot =
                                      _parseHours(
                                    otController.text,
                                    selectedOt,
                                  );

                                  _saveAttendance(
                                    date,
                                    AttendanceData(
                                      status:
                                          selectedStatus,
                                      normalHours:
                                          normal,
                                      otHours: ot,
                                      note:
                                          noteController
                                              .text
                                              .trim(),
                                    ),
                                  );

                                  Navigator.pop(
                                    sheetContext,
                                  );
                                },
                                icon: const Icon(
                                  Icons.check,
                                  size: 28,
                                ),
                                label: const Text(
                                  'Save Attendance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF08678E,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(32),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusButton(
    String title,
    AttendanceStatus value,
    AttendanceStatus selected,
    ValueChanged<AttendanceStatus> onTap,
  ) {
    final active = value == selected;

    Color activeColor;

    switch (value) {
      case AttendanceStatus.present:
        activeColor = const Color(0xFF19804B);
        break;
      case AttendanceStatus.halfDay:
        activeColor = const Color(0xFFC34B1A);
        break;
      case AttendanceStatus.absent:
        activeColor = const Color(0xFFB52830);
        break;
      case AttendanceStatus.leave:
        activeColor = const Color(0xFFD09600);
        break;
      case AttendanceStatus.holiday:
        activeColor = const Color(0xFF7131C9);
        break;
    }

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? activeColor
                : const Color(0xFFC1CEDB),
            width: active ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Icon(
                Icons.check,
                color: activeColor,
                size: 21,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: active
                    ? activeColor
                    : const Color(0xFF4E5A6A),
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hoursTextField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 34,
        color: Color(0xFF17698D),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEDF6FC),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: Color(0xFFC3D1DE),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: Color(0xFFC3D1DE),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: Color(0xFF08678E),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _hourQuickButton(
    String text,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFDCEAF3)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xFF08678E)
                : const Color(0xFFC3D1DE),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? const Color(0xFF08678E)
                : const Color(0xFF4E5A6A),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SETTINGS
  // ------------------------------------------------------------

  void _showSettings() {
    final salaryController =
        TextEditingController(
      text: monthlySalary.toStringAsFixed(0),
    );

    final daysController =
        TextEditingController(
      text: standardWorkingDays.toStringAsFixed(0),
    );

    final otController =
        TextEditingController(
      text: otRate.toStringAsFixed(2),
    );

    final advanceController =
        TextEditingController(
      text: advance.toStringAsFixed(0),
    );

    final deductionController =
        TextEditingController(
      text: deduction.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FC),
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
                          'Payment Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _settingField(
                    'Monthly Salary',
                    salaryController,
                  ),
                  _settingField(
                    'Standard Working Days',
                    daysController,
                  ),
                  _settingField(
                    'OT Rate / Hour',
                    otController,
                  ),
                  _settingField(
                    'Advance',
                    advanceController,
                  ),
                  _settingField(
                    'Deduction',
                    deductionController,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          monthlySalary =
                              double.tryParse(
                                    salaryController
                                        .text,
                                  ) ??
                                  monthlySalary;

                          standardWorkingDays =
                              double.tryParse(
                                    daysController.text,
                                  ) ??
                                  standardWorkingDays;

                          otRate =
                              double.tryParse(
                                    otController.text,
                                  ) ??
                                  otRate;

                          advance =
                              double.tryParse(
                                    advanceController
                                        .text,
                                  ) ??
                                  advance;

                          deduction =
                              double.tryParse(
                                    deductionController
                                        .text,
                                  ) ??
                                  deduction;
                        });

                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF08678E),
                      ),
                      child: const Text(
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
      },
    );
  }

  Widget _settingField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CALCULATIONS
  // ------------------------------------------------------------

  Map<String, dynamic> _monthStats(
    DateTime month,
  ) {
    int present = 0;
    int absent = 0;
    int half = 0;
    int leave = 0;
    int holiday = 0;

    double hours = 0;
    double ot = 0;

    final daysInMonth = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final data = _attendance[
        _dateKey(
          DateTime(
            month.year,
            month.month,
            day,
          ),
        )
      ];

      if (data == null) continue;

      hours += data.normalHours;
      ot += data.otHours;

      switch (data.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.halfDay:
          half++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.holiday:
          holiday++;
          break;
      }
    }

    final dailyWage =
        standardWorkingDays == 0
            ? 0.0
            : monthlySalary / standardWorkingDays;

    final basic =
        present * dailyWage +
        half * dailyWage * .5;

    final otPayment = ot * otRate;

    final payment =
        basic + otPayment - advance - deduction;

    return {
      'present': present,
      'absent': absent,
      'half': half,
      'leave': leave,
      'holiday': holiday,
      'hours': _formatHours(hours),
      'ot': _formatHours(ot),
      'payment': payment,
    };
  }

  double _parseHours(
    String text,
    double fallback,
  ) {
    final cleaned = text
        .toUpperCase()
        .replaceAll('H', '')
        .trim();

    return double.tryParse(cleaned) ?? fallback;
  }

  String _formatHours(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _monthName(int month) {
    const names = [
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

    return names[month];
  }

  String _weekdayName(int weekday) {
    const names = [
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return names[weekday];
  }
}

// ------------------------------------------------------------
// SMALL UI COMPONENTS
// ------------------------------------------------------------

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF354152),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final Color color;

  const _LegendItem(
    this.title,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF3E4856),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF17698D),
          size: 29,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FormTitle extends StatelessWidget {
  final String text;

  const _FormTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Color(0xFF0C1729),
      ),
    );
  }
}
