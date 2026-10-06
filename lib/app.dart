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
        scaffoldBackgroundColor: const Color(0xFFF1F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B78),
        ),
      ),
      home: const WorkerPayHome(),
    );
  }
}

// ============================================================
// ATTENDANCE MODEL
// ============================================================

enum AttendanceStatus {
  present,
  halfDay,
  absent,
  leave,
  holiday,
}

class AttendanceRecord {
  AttendanceStatus status;
  String workingHours;
  String otHours;
  String note;

  AttendanceRecord({
    required this.status,
    required this.workingHours,
    required this.otHours,
    required this.note,
  });
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
  int _selectedIndex = 0;

  final Map<String, AttendanceRecord> _attendance = {};

  final List<Widget> _screens = const [
    SizedBox(),
    YearScreen(),
    SummaryScreen(),
  ];

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> _openAttendance(DateTime date) async {
    final key = _dateKey(date);
    final existing = _attendance[key];

    final result = await showModalBottomSheet<AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AttendanceEntrySheet(
          date: date,
          existing: existing,
        );
      },
    );

    if (result != null) {
      setState(() {
        _attendance[key] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_selectedIndex == 0) {
      body = MonthScreen(
        attendance: _attendance,
        onDateTap: _openAttendance,
      );
    } else {
      body = _screens[_selectedIndex];
    }

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// ============================================================
// MONTH SCREEN
// ============================================================

class MonthScreen extends StatefulWidget {
  final Map<String, AttendanceRecord> attendance;
  final Future<void> Function(DateTime date) onDateTap;

  const MonthScreen({
    super.key,
    required this.attendance,
    required this.onDateTap,
  });

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  DateTime _month = DateTime.now();

  String get _monthTitle {
    const months = [
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

    return '${months[_month.month - 1]} ${_month.year}';
  }

  String _key(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month + 1,
        1,
      );
    });
  }

  void _currentMonth() {
    final now = DateTime.now();

    setState(() {
      _month = DateTime(now.year, now.month, 1);
    });
  }

  double _hoursTotal() {
    double total = 0;

    for (final entry in widget.attendance.entries) {
      final parts = entry.key.split('-');

      if (parts.length != 3) {
        continue;
      }

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      if (year != _month.year || month != _month.month) {
        continue;
      }

      total += _readHours(entry.value.workingHours);
    }

    return total;
  }

  double _otTotal() {
    double total = 0;

    for (final entry in widget.attendance.entries) {
      final parts = entry.key.split('-');

      if (parts.length != 3) {
        continue;
      }

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      if (year != _month.year || month != _month.month) {
        continue;
      }

      total += _readHours(entry.value.otHours);
    }

    return total;
  }

  double _readHours(String value) {
    final cleaned = value
        .toUpperCase()
        .replaceAll('H', '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 16),
          _monthHeader(),
          const SizedBox(height: 14),
          _stats(),
          const SizedBox(height: 16),
          _calendar(),
          const SizedBox(height: 14),
          _legend(),
          const SizedBox(height: 16),
          _summary(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Worker Pay',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF173B45),
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.settings_outlined,
                color: Color(0xFF28515B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _monthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF176B78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _arrow(
            Icons.chevron_left,
            _previousMonth,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _currentMonth,
              child: Column(
                children: [
                  Text(
                    _monthTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap for current month',
                    style: TextStyle(
                      color: Color(0xFFD5EDF0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _arrow(
            Icons.chevron_right,
            _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _arrow(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    );
  }

  Widget _stats() {
    final hours = _hoursTotal();
    final ot = _otTotal();

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Hours',
            '${_formatHours(hours)}H',
            Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'OT',
            '${_formatHours(ot)}H',
            Icons.more_time_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Payment',
            '₹0',
            Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  String _formatHours(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF176B78),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF71838A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183F49),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendar() {
    final firstDay = DateTime(
      _month.year,
      _month.month,
      1,
    );

    final days = DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final offset = firstDay.weekday % 7;
    final cells = ((offset + days) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        15,
        12,
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final day = index - offset + 1;

              if (day < 1 || day > days) {
                return const SizedBox();
              }

              final date = DateTime(
                _month.year,
                _month.month,
                day,
              );

              return _dayCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date) {
    final record = widget.attendance[_key(date)];

    Color border = const Color(0xFFE1EAED);
    Color background = const Color(0xFFF7FAFB);
    Color textColor = const Color(0xFF294A53);

    if (record != null) {
      switch (record.status) {
        case AttendanceStatus.present:
          border = const Color(0xFF35A66F);
          background = const Color(0xFFEAF8F0);
          textColor = const Color(0xFF258657);
          break;

        case AttendanceStatus.halfDay:
          border = const Color(0xFFF2A33A);
          background = const Color(0xFFFFF5E7);
          textColor = const Color(0xFFC47711);
          break;

        case AttendanceStatus.absent:
          border = const Color(0xFFE25353);
          background = const Color(0xFFFFEEEE);
          textColor = const Color(0xFFC63F3F);
          break;

        case AttendanceStatus.leave:
          border = const Color(0xFFE0B52C);
          background = const Color(0xFFFFF9DF);
          textColor = const Color(0xFFAD8A0D);
          break;

        case AttendanceStatus.holiday:
          border = const Color(0xFF8B62C7);
          background = const Color(0xFFF3EDFB);
          textColor = const Color(0xFF7048A8);
          break;
      }
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onDateTap(date),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              if (record == null)
                const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9AAAB0),
                  ),
                )
              else
                Text(
                  record.status == AttendanceStatus.present
                      ? record.workingHours
                      : _statusShort(record.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusShort(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.halfDay:
        return '½';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.leave:
        return 'L';
      case AttendanceStatus.holiday:
        return 'H';
    }
  }

  Widget _legend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(
          color: Color(0xFF35A66F),
          title: 'Present',
        ),
        _LegendItem(
          color: Color(0xFFF2A33A),
          title: 'Half Day',
        ),
        _LegendItem(
          color: Color(0xFFE25353),
          title: 'Absent',
        ),
        _LegendItem(
          color: Color(0xFF8B62C7),
          title: 'Holiday',
        ),
        _LegendItem(
          color: Color(0xFF3989C9),
          title: 'OT',
        ),
      ],
    );
  }

  Widget _summary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF193F49),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Working Hours: ${_formatHours(_hoursTotal())}H',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF61747B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'OT Hours: ${_formatHours(_otTotal())}H',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF61747B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ATTENDANCE ENTRY
// ============================================================

class AttendanceEntrySheet extends StatefulWidget {
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
  late AttendanceStatus _status;

  late TextEditingController _normalController;
  late TextEditingController _otController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();

    final old = widget.existing;

    _status = old?.status ?? AttendanceStatus.present;

    _normalController = TextEditingController(
      text: old?.workingHours ?? '8H',
    );

    _otController = TextEditingController(
      text: old?.otHours ?? '0H',
    );

    _noteController = TextEditingController(
      text: old?.note ?? '',
    );
  }

  @override
  void dispose() {
    _normalController.dispose();
    _otController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _dateText() {
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

    final d = widget.date;

    return '${weekdays[d.weekday - 1]}, '
        '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _setNormal(String value) {
    setState(() {
      _normalController.text = value;
      _normalController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _normalController.text.length,
        ),
      );
    });
  }

  void _setOt(String value) {
    setState(() {
      _otController.text = value;
      _otController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _otController.text.length,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F6F8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            _sheetHeader(),
            const SizedBox(height: 20),
            _sectionTitle('Status'),
            const SizedBox(height: 9),
            _statusGrid(),
            const SizedBox(height: 20),
            _sectionTitle('Normal Working Hours'),
            const SizedBox(height: 9),
            _hoursInput(
              controller: _normalController,
              hint: '8H',
            ),
            const SizedBox(height: 9),
            _quickButtons(
              values: const ['4H', '8H', '10H'],
              selected: _normalController.text,
              onSelected: _setNormal,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Overtime (OT) Hours'),
            const SizedBox(height: 9),
            _hoursInput(
              controller: _otController,
              hint: '0H',
            ),
            const SizedBox(height: 9),
            _quickButtons(
              values: const ['0H', '4H', '16H'],
              selected: _otController.text,
              onSelected: _setOt,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Note'),
            const SizedBox(height: 9),
            _noteInput(),
            const SizedBox(height: 20),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFB8C4C9),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _sheetHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFDDEFF2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.event_available_outlined,
            color: Color(0xFF176B78),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Entry',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF193F49),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dateText(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF71838A),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF294A53),
      ),
    );
  }

  Widget _statusGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statusButton(
                AttendanceStatus.present,
                'Present',
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statusButton(
                AttendanceStatus.halfDay,
                'Half Day',
                Icons.timelapse_outlined,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statusButton(
                AttendanceStatus.absent,
                'Absent',
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _statusButton(
                AttendanceStatus.leave,
                'Leave',
                Icons.beach_access_outlined,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statusButton(
                AttendanceStatus.holiday,
                'Holiday',
                Icons.celebration_outlined,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _statusButton(
    AttendanceStatus status,
    String title,
    IconData icon,
  ) {
    final selected = _status == status;

    final color = _statusColor(status);

    return GestureDetector(
      onTap: () {
        setState(() {
          _status = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? color
                : const Color(0xFFDDE6E9),
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? color
                  : const Color(0xFF75878D),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? color
                      : const Color(0xFF536970),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF35A66F);
      case AttendanceStatus.halfDay:
        return const Color(0xFFF2A33A);
      case AttendanceStatus.absent:
        return const Color(0xFFE25353);
      case AttendanceStatus.leave:
        return const Color(0xFFD0A719);
      case AttendanceStatus.holiday:
        return const Color(0xFF8B62C7);
    }
  }

  Widget _hoursInput({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFD8E3E7),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF176B78),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFAAB8BC),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15),
          suffixText: '',
        ),
      ),
    );
  }

  Widget _quickButtons({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: values.map((value) {
        final isSelected =
            selected.trim().toUpperCase() ==
            value.toUpperCase();

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: value == values.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 150),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF176B78)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF176B78)
                        : const Color(0xFFD8E3E7),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF526A72),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFD8E3E7),
        ),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        textCapitalization:
            TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Optional note...',
          hintStyle: TextStyle(
            color: Color(0xFFA0AFB4),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 4,
              top: 13,
            ),
            child: Icon(
              Icons.notes_outlined,
              color: Color(0xFF789097),
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(
            context,
            AttendanceRecord(
              status: _status,
              workingHours:
                  _normalController.text.trim().isEmpty
                      ? '0H'
                      : _normalController.text.trim(),
              otHours:
                  _otController.text.trim().isEmpty
                      ? '0H'
                      : _otController.text.trim(),
              note: _noteController.text.trim(),
            ),
          );
        },
        icon: const Icon(Icons.check),
        label: const Text(
          'Save Attendance',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF176B78),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// YEAR SCREEN - PART 3
// ============================================================

class YearScreen extends StatelessWidget {
  const YearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Year Overview',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF193F49),
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY SCREEN - PART 3
// ============================================================

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Monthly Summary',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF193F49),
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _item(
              0,
              Icons.calendar_month_outlined,
              'Month',
            ),
          ),
          Expanded(
            child: _item(
              1,
              Icons.calendar_view_month_outlined,
              'Year',
            ),
          ),
          Expanded(
            child: _item(
              2,
              Icons.account_balance_wallet_outlined,
              'Summary',
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    int index,
    IconData icon,
    String label,
  ) {
    final selected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE1F1F4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? const Color(0xFF176B78)
                  : const Color(0xFF829197),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: selected
                    ? const Color(0xFF176B78)
                    : const Color(0xFF829197),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMALL COMPONENTS
// ============================================================

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
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF71838A),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const _LegendItem({
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF61747B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
