import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkerPayApp());
}

class C {
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

enum Status { present, half, absent, leave, holiday }
enum CalcMode { fixedDays, monthDays, dailyWage }

String statusLabel(Status s) {
  switch (s) {
    case Status.present:
      return 'Present';
    case Status.half:
      return 'Half Day';
    case Status.absent:
      return 'Absent';
    case Status.leave:
      return 'Leave';
    case Status.holiday:
      return 'Holiday';
  }
}

Color statusColor(Status s) {
  switch (s) {
    case Status.present:
      return C.green;
    case Status.half:
      return C.orange;
    case Status.absent:
      return C.red;
    case Status.leave:
      return C.yellow;
    case Status.holiday:
      return C.purple;
  }
}

String monthName(int m) => const [
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
      'December'
    ][m - 1];

String weekdayName(DateTime d) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][d.weekday - 1];

String dateTitle(DateTime d) =>
    '${weekdayName(d)}, ${d.day} ${monthName(d.month)} ${d.year}';

String keyFor(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String hoursText(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}H' : '${v.toStringAsFixed(1)}H';

String money(double v) => '₹${v.toStringAsFixed(0)}';

class Record {
  final String key;
  final Status status;
  final double normal;
  final double ot;
  final String note;

  const Record({
    required this.key,
    required this.status,
    required this.normal,
    required this.ot,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'status': status.name,
        'normal': normal,
        'ot': ot,
        'note': note,
      };

  factory Record.fromJson(Map<String, dynamic> j) {
    Status s = Status.present;

    for (final x in Status.values) {
      if (x.name == j['status']?.toString()) {
        s = x;
        break;
      }
    }

    return Record(
      key: j['key']?.toString() ?? '',
      status: s,
      normal: (j['normal'] as num?)?.toDouble() ?? 0,
      ot: (j['ot'] as num?)?.toDouble() ?? 0,
      note: j['note']?.toString() ?? '',
    );
  }
}

class Settings {
  final CalcMode mode;
  final double salary;
  final int days;
  final double normalHours;
  final double otRate;
  final double dailyWage;
  final double advance;
  final double deduction;

  const Settings({
    required this.mode,
    required this.salary,
    required this.days,
    required this.normalHours,
    required this.otRate,
    required this.dailyWage,
    required this.advance,
    required this.deduction,
  });

  factory Settings.defaults() => const Settings(
        mode: CalcMode.fixedDays,
        salary: 15000,
        days: 26,
        normalHours: 8,
        otRate: 100,
        dailyWage: 0,
        advance: 0,
        deduction: 0,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'salary': salary,
        'days': days,
        'normalHours': normalHours,
        'otRate': otRate,
        'dailyWage': dailyWage,
        'advance': advance,
        'deduction': deduction,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    CalcMode m = CalcMode.fixedDays;

    for (final x in CalcMode.values) {
      if (x.name == j['mode']?.toString()) {
        m = x;
        break;
      }
    }

    return Settings(
      mode: m,
      salary: (j['salary'] as num?)?.toDouble() ?? 15000,
      days: (j['days'] as num?)?.toInt() ?? 26,
      normalHours: (j['normalHours'] as num?)?.toDouble() ?? 8,
      otRate: (j['otRate'] as num?)?.toDouble() ?? 100,
      dailyWage: (j['dailyWage'] as num?)?.toDouble() ?? 0,
      advance: (j['advance'] as num?)?.toDouble() ?? 0,
      deduction: (j['deduction'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Store {
  static const recordsKey = 'wp_records_v3';
  static const settingsKey = 'wp_settings_v3';

  static Future<Map<String, Record>> loadRecords() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(recordsKey);

    if (raw == null) return {};

    try {
      final data = jsonDecode(raw);

      if (data is! Map) return {};

      final out = <String, Record>{};

      data.forEach((k, v) {
        if (v is Map) {
          out[k.toString()] =
              Record.fromJson(Map<String, dynamic>.from(v));
        }
      });

      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveRecords(
    Map<String, Record> records,
  ) async {
    final p = await SharedPreferences.getInstance();

    final data = <String, dynamic>{};

    records.forEach((k, v) {
      data[k] = v.toJson();
    });

    await p.setString(
      recordsKey,
      jsonEncode(data),
    );
  }

  static Future<Settings> loadSettings() async {
    final p = await SharedPreferences.getInstance();

    final raw = p.getString(settingsKey);

    if (raw == null) {
      return Settings.defaults();
    }

    try {
      final data = jsonDecode(raw);

      if (data is Map) {
        return Settings.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {}

    return Settings.defaults();
  }

  static Future<void> saveSettings(Settings s) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      settingsKey,
      jsonEncode(s.toJson()),
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
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.primary,
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;

  DateTime month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Map<String, Record> records = {};

  Settings settings = Settings.defaults();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Store.loadRecords();
    final s = await Store.loadSettings();

    if (!mounted) return;

    setState(() {
      records = r;
      settings = s;
      loading = false;
    });
  }

  List<Record> monthRecords([DateTime? m]) {
    final x = m ?? month;

    return records.values.where((r) {
      final p = r.key.split('-');

      return p.length == 3 &&
          int.tryParse(p[0]) == x.year &&
          int.tryParse(p[1]) == x.month;
    }).toList();
  }

  Record? record(DateTime d) {
    return records[keyFor(d)];
  }

  double normalTotal([DateTime? m]) {
    return monthRecords(m).fold(
      0.0,
      (a, r) => a + r.normal,
    );
  }

  double otTotal([DateTime? m]) {
    return monthRecords(m).fold(
      0.0,
      (a, r) => a + r.ot,
    );
  }

  int count(
    Status s, [
    DateTime? m,
  ]) {
    return monthRecords(m)
        .where((r) => r.status == s)
        .length;
  }

  double dailyWage() {
    if (settings.dailyWage > 0) {
      return settings.dailyWage;
    }

    final d = settings.days <= 0
        ? 26
        : settings.days;

    return settings.salary / d.toDouble();
  }

  double basicPayment([DateTime? m]) {
    final list = monthRecords(m);

    switch (settings.mode) {
      case CalcMode.dailyWage:
        return list
            .where(
              (r) => r.status == Status.present,
            )
            .fold(
              0.0,
              (a, r) => a + dailyWage(),
            );

      case CalcMode.monthDays:
        final p = list
            .where(
              (r) => r.status == Status.present,
            )
            .length;

        final target = m ?? month;

        final days = DateUtils.getDaysInMonth(
          target.year,
          target.month,
        );

        return days == 0
            ? 0
            : settings.salary *
                p /
                days;

      case CalcMode.fixedDays:
        final p = list
            .where(
              (r) => r.status == Status.present,
            )
            .length;

        final h = list
            .where(
              (r) => r.status == Status.half,
            )
            .length;

        return p * dailyWage() +
            h * dailyWage() * 0.5;
    }
  }

  double otPayment([DateTime? m]) {
    return otTotal(m) * settings.otRate;
  }

  double netPayment([DateTime? m]) {
    return basicPayment(m) +
        otPayment(m) -
        settings.advance -
        settings.deduction;
  }

  void prevMonth() {
    setState(() {
      month = DateTime(
        month.year,
        month.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      month = DateTime(
        month.year,
        month.month + 1,
      );
    });
  }

  void currentMonth() {
    setState(() {
      month = DateTime(
        DateTime.now().year,
        DateTime.now().month,
      );
    });
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
          index: tab,
          children: [
            monthPage(),
            yearPage(),
            summaryPage(),
          ],
        ),
      ),
      bottomNavigationBar: bottomNav(),
    );
  }

  Widget header(
    String title,
    String subtitle, {
    bool settingsButton = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: C.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: C.sub,
                ),
              ),
            ],
          ),
        ),
        if (settingsButton)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            onPressed: openSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: C.primary,
            ),
          ),
      ],
    );
  }

  Widget monthPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          header(
            'Worker Pay',
            'Attendance & Payment',
            settingsButton: true,
          ),
          const SizedBox(height: 16),
          monthSelector(),
          const SizedBox(height: 12),
          stats(),
          const SizedBox(height: 12),
          calendar(),
          const SizedBox(height: 10),
          legend(),
          const SizedBox(height: 12),
          monthlySummary(),
        ],
      ),
    );
  }

  Widget monthSelector() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: C.border,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: prevMonth,
            icon: const Icon(
              Icons.chevron_left,
              color: C.primary,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${monthName(month.month)} ${month.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: C.text,
                  ),
                ),
                GestureDetector(
                  onTap: currentMonth,
                  child: const Text(
                    'Tap for current month',
                    style: TextStyle(
                      fontSize: 11,
                      color: C.primary,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: nextMonth,
            icon: const Icon(
              Icons.chevron_right,
              color: C.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget stats() {
    return Row(
      children: [
        Expanded(
          child: statBox(
            'Hours',
            hoursText(normalTotal()),
            Icons.access_time,
            C.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: statBox(
            'OT',
            hoursText(otTotal()),
            Icons.more_time,
            C.ot,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: statBox(
            'Payment',
            money(netPayment()),
            Icons.payments_outlined,
            C.green,
          ),
        ),
      ],
    );
  }

  Widget statBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: C.border,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: C.sub,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: C.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget calendar() {
    final first = DateTime(
      month.year,
      month.month,
      1,
    );

    final days = DateUtils.getDaysInMonth(
      month.year,
      month.month,
    );

    final offset = first.weekday % 7;

    final cells =
        ((offset + days + 6) ~/ 7) * 7;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        12,
        9,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: C.border,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    const [
                      'SUN',
                      'MON',
                      'TUE',
                      'WED',
                      'THU',
                      'FRI',
                      'SAT'
                    ][i],
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      color: C.sub,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              mainAxisExtent: 72,
            ),
            itemBuilder: (context, i) {
              if (i < offset ||
                  i >= offset + days) {
                return const SizedBox();
              }

              final d = DateTime(
                month.year,
                month.month,
                i - offset + 1,
              );

              return dayCell(d);
            },
          ),
        ],
      ),
    );
  }

  Widget dayCell(DateTime d) {
    final r = record(d);

    final now = DateTime.now();

    final today =
        d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;

    Color bg = Colors.white;
    Color border =
        today ? C.primary : C.border;
    Color number = C.text;

    if (r != null) {
      switch (r.status) {
        case Status.present:
          bg = C.greenBg;
          border = C.green;
          number = C.green;
          break;

        case Status.half:
          bg = C.orangeBg;
          border = C.orange;
          number = C.orange;
          break;

        case Status.absent:
          bg = C.redBg;
          border = C.red;
          number = C.red;
          break;

        case Status.leave:
          bg = C.yellowBg;
          border = C.yellow;
          number = C.yellow;
          break;

        case Status.holiday:
          bg = C.purpleBg;
          border = C.purple;
          number = C.purple;
          break;
      }
    }

    return InkWell(
      borderRadius:
          BorderRadius.circular(11),
      onTap: () => openAttendance(d),
      child: Container(
        padding:
            const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: border,
            width: today ? 1.5 : 1,
          ),
          borderRadius:
              BorderRadius.circular(11),
        ),
        child: r == null
            ? Column(
                children: [
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w900,
                      color: number,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 17,
                      color: C.border,
                    ),
                  ),
                  const Spacer(),
                ],
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w900,
                      color: number,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.status ==
                            Status.present
                        ? hoursText(r.normal)
                        : statusLabel(
                            r.status,
                          ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          statusColor(
                        r.status,
                      ),
                    ),
                  ),
                  if (r.ot > 0)
                    Text(
                      'OT ${hoursText(r.ot)}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                        color: C.ot,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget legend() {
    return Wrap(
      spacing: 10,
      runSpacing: 7,
      children: const [
        Dot(C.green, 'Present'),
        Dot(C.orange, 'Half Day'),
        Dot(C.red, 'Absent'),
        Dot(C.yellow, 'Leave'),
        Dot(C.purple, 'Holiday'),
        Dot(C.ot, 'OT'),
      ],
    );
  }

  Widget monthlySummary() {
    return card(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          section('Monthly Summary'),
          const SizedBox(height: 14),
          Row(
            children: [
              mini(
                'Present',
                '${count(Status.present)}',
                C.green,
              ),
              mini(
                'Half Day',
                '${count(Status.half)}',
                C.orange,
              ),
              mini(
                'Absent',
                '${count(Status.absent)}',
                C.red,
              ),
              mini(
                'OT',
                hoursText(otTotal()),
                C.ot,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget mini(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: C.sub,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // YEAR
  // ==========================================================

  Widget yearPage() {
    final y = month.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          header(
            'Year Overview',
            '$y · Monthly Attendance',
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, i) {
              final m = DateTime(
                y,
                i + 1,
              );

              final selected =
                  m.month == month.month;

              return InkWell(
                borderRadius:
                    BorderRadius.circular(17),
                onTap: () => setState(() {
                  month = m;
                  tab = 0;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: selected
                        ? C.light
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(17),
                    border: Border.all(
                      color: selected
                          ? C.primary
                          : C.border,
                      width:
                          selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName(
                          m.month,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w900,
                          color: C.text,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: yr(
                              'P',
                              count(
                                Status.present,
                                m,
                              ),
                              C.green,
                            ),
                          ),
                          Expanded(
                            child: yr(
                              'A',
                              count(
                                Status.absent,
                                m,
                              ),
                              C.red,
                            ),
                          ),
                          Expanded(
                            child: yr(
                              'H',
                              count(
                                Status.half,
                                m,
                              ),
                              C.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'OT ${hoursText(otTotal(m))}',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          color: C.ot,
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

  Widget yr(
    String label,
    int value,
    Color color,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
            color: C.text,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget summaryPage() {
    final title =
        '${monthName(month.month)} ${month.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          header(
            'Monthly Summary',
            title,
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  C.dark,
                  C.primary,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Net Payment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  money(netPayment()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: heroMini(
                        'Hours',
                        hoursText(
                          normalTotal(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: heroMini(
                        'OT',
                        hoursText(
                          otTotal(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          card(
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                section('Attendance'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: countTile(
                        'Present',
                        count(
                          Status.present,
                        ),
                        C.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: countTile(
                        'Absent',
                        count(
                          Status.absent,
                        ),
                        C.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: countTile(
                        'Half Day',
                        count(
                          Status.half,
                        ),
                        C.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: countTile(
                        'Holiday',
                        count(
                          Status.holiday,
                        ),
                        C.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          card(
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                section('Working Time'),
                const SizedBox(height: 10),
                info(
                  'Normal Hours',
                  hoursText(
                    normalTotal(),
                  ),
                ),
                info(
                  'Overtime',
                  hoursText(
                    otTotal(),
                  ),
                ),
                info(
                  'Normal Hours / Day',
                  hoursText(
                    settings.normalHours,
                  ),
                ),
                info(
                  'OT Rate',
                  '${money(settings.otRate)}/hour',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          card(
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                section(
                  'Payment Breakdown',
                ),
                const SizedBox(height: 8),
                rowMoney(
                  'Monthly Salary',
                  money(settings.salary),
                ),
                rowMoney(
                  'Daily Wage',
                  money(dailyWage()),
                ),
                rowMoney(
                  'OT Rate',
                  '${money(settings.otRate)}/hour',
                ),
                const Divider(
                  height: 18,
                ),
                rowMoney(
                  'Basic Payment',
                  money(
                    basicPayment(),
                  ),
                  bold: true,
                ),
                rowMoney(
                  'OT Payment',
                  money(
                    otPayment(),
                  ),
                  bold: true,
                ),
                rowMoney(
                  'Advance',
                  '-${money(settings.advance)}',
                ),
                rowMoney(
                  'Deduction',
                  '-${money(settings.deduction)}',
                ),
                const Divider(
                  height: 18,
                ),
                rowMoney(
                  'Net Payment',
                  money(netPayment()),
                  bold: true,
                  big: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget heroMini(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget countTile(
    String title,
    int value,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: C.sub,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget info(
    String a,
    String b,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a,
              style: const TextStyle(
                fontSize: 12,
                color: C.sub,
              ),
            ),
          ),
          Text(
            b,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color: C.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget rowMoney(
    String a,
    String b, {
    bool bold = false,
    bool big = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a,
              style: TextStyle(
                fontSize: big ? 15 : 12,
                color: C.sub,
                fontWeight: bold
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
          Text(
            b,
            style: TextStyle(
              fontSize: big ? 18 : 12,
              color: big
                  ? C.primary
                  : C.text,
              fontWeight: bold
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget section(String s) {
    return Text(
      s,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: C.text,
      ),
    );
  }

  Widget card(Widget child) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: C.border,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  // ==========================================================
  // BOTTOM NAV
  // ==========================================================

  Widget bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: C.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.all(8),
          child: Row(
            children: [
              navItem(
                0,
                Icons.calendar_month_outlined,
                'Month',
              ),
              navItem(
                1,
                Icons.date_range_outlined,
                'Year',
              ),
              navItem(
                2,
                Icons.payments_outlined,
                'Summary',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(
    int index,
    IconData icon,
    String label,
  ) {
    final active = tab == index;

    return Expanded(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () =>
            setState(() => tab = index),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: active
                ? C.light
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: active
                    ? C.primary
                    : C.sub,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active
                      ? FontWeight.w900
                      : FontWeight.w500,
                  color: active
                      ? C.primary
                      : C.sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ATTENDANCE
  // ==========================================================

  Future<void> openAttendance(
    DateTime d,
  ) async {
    final result =
        await showModalBottomSheet<Record>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) => AttendanceSheet(
        date: d,
        existing: record(d),
        defaultHours:
            settings.normalHours,
      ),
    );

    if (result == null) return;

    setState(() {
      records[result.key] = result;
    });

    await Store.saveRecords(records);
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  Future<void> openSettings() async {
    final result =
        await showModalBottomSheet<Settings>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) => SettingsSheet(
        settings: settings,
      ),
    );

    if (result == null) return;

    setState(() {
      settings = result;
    });

    await Store.saveSettings(
      settings,
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;
  final String text;

  const Dot(
    this.color,
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            color: C.sub,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ATTENDANCE SHEET
// ============================================================

class AttendanceSheet
    extends StatefulWidget {
  final DateTime date;
  final Record? existing;
  final double defaultHours;

  const AttendanceSheet({
    super.key,
    required this.date,
    required this.existing,
    required this.defaultHours,
  });

  @override
  State<AttendanceSheet> createState() =>
      _AttendanceSheetState();
}

class _AttendanceSheetState
    extends State<AttendanceSheet> {
  late Status status;
  late TextEditingController normal;
  late TextEditingController ot;
  late TextEditingController note;

  @override
  void initState() {
    super.initState();

    status =
        widget.existing?.status ??
            Status.present;

    normal =
        TextEditingController(
      text: hoursText(
        widget.existing?.normal ??
            widget.defaultHours,
      ),
    );

    ot =
        TextEditingController(
      text: hoursText(
        widget.existing?.ot ?? 0,
      ),
    );

    note =
        TextEditingController(
      text: widget.existing?.note ?? '',
    );
  }

  @override
  void dispose() {
    normal.dispose();
    ot.dispose();
    note.dispose();
    super.dispose();
  }

  double parseHours(
    String value,
  ) {
    return double.tryParse(
          value
              .toUpperCase()
              .replaceAll(
                'H',
                '',
              )
              .trim(),
        ) ??
        0;
  }

  void setController(
    TextEditingController c,
    String value,
  ) {
    setState(() {
      c.text = value;

      c.selection =
          TextSelection.collapsed(
        offset: c.text.length,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final keyboard =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              .94,
      padding:
          EdgeInsets.only(
        bottom: keyboard,
      ),
      decoration:
          const BoxDecoration(
        color: C.bg,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Container(
              width: 42,
              height: 4,
              decoration:
                  BoxDecoration(
                color: C.border,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                15,
                10,
                10,
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
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w900,
                            color: C.text,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          dateTitle(
                            widget.date,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: C.sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    icon:
                        const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    label('Status'),
                    const SizedBox(
                      height: 8,
                    ),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children:
                          Status.values
                              .map(
                                statusButton,
                              )
                              .toList(),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    label(
                      'Normal Working Hours',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    input(
                      normal,
                      'Example: 8H',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Wrap(
                      spacing: 7,
                      children: [
                        quick(
                          '4H',
                          normal,
                        ),
                        quick(
                          '8H',
                          normal,
                        ),
                        quick(
                          '10H',
                          normal,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    label('Overtime'),
                    const SizedBox(
                      height: 7,
                    ),
                    input(
                      ot,
                      'Example: 4H, 8H, 12H',
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Wrap(
                      spacing: 7,
                      children: [
                        quick(
                          '0H',
                          ot,
                        ),
                        quick(
                          '4H',
                          ot,
                        ),
                        quick(
                          '8H',
                          ot,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    label('Note'),
                    const SizedBox(
                      height: 7,
                    ),
                    TextField(
                      controller: note,
                      maxLines: 3,
                      decoration:
                          decoration(
                        'Optional note',
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        onPressed: save,
                        icon:
                            const Icon(
                          Icons
                              .save_outlined,
                        ),
                        label:
                            const Text(
                          'Save Attendance',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              C.primary,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
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

  Widget label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight:
            FontWeight.w900,
        color: C.text,
      ),
    );
  }

  InputDecoration decoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: C.border,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: C.border,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: C.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget input(
    TextEditingController c,
    String hint,
  ) {
    return TextField(
      controller: c,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration:
          decoration(hint).copyWith(
        suffixText: 'H',
      ),
    );
  }

  Widget quick(
    String text,
    TextEditingController c,
  ) {
    final selected =
        c.text.toUpperCase() ==
            text;

    return InkWell(
      borderRadius:
          BorderRadius.circular(10),
      onTap: () =>
          setController(
        c,
        text,
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? C.primary
              : Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? C.primary
                : C.border,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w900,
            color: selected
                ? Colors.white
                : C.text,
          ),
        ),
      ),
    );
  }

  Widget statusButton(
    Status s,
  ) {
    final selected =
        status == s;

    final color =
        statusColor(s);

    return InkWell(
      borderRadius:
          BorderRadius.circular(11),
      onTap: () =>
          setState(
        () => status = s,
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? color
              : Colors.white,
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? color
                : C.border,
          ),
        ),
        child: Text(
          statusLabel(s),
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w900,
            color: selected
                ? Colors.white
                : color,
          ),
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(
      context,
      Record(
        key: keyFor(
          widget.date,
        ),
        status: status,
        normal:
            parseHours(
          normal.text,
        ),
        ot: parseHours(
          ot.text,
        ),
        note:
            note.text.trim(),
      ),
    );
  }
}

// ============================================================
// SETTINGS SHEET
// ============================================================

class SettingsSheet
    extends StatefulWidget {
  final Settings settings;

  const SettingsSheet({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsSheet> createState() =>
      _SettingsSheetState();
}

class _SettingsSheetState
    extends State<SettingsSheet> {
  late CalcMode mode;
  late TextEditingController salary;
  late TextEditingController days;
  late TextEditingController normalHours;
  late TextEditingController otRate;
  late TextEditingController daily;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    final s =
        widget.settings;

    mode = s.mode;

    salary =
        TextEditingController(
      text: numText(
        s.salary,
      ),
    );

    days =
        TextEditingController(
      text: '${s.days}',
    );

    normalHours =
        TextEditingController(
      text: numText(
        s.normalHours,
      ),
    );

    otRate =
        TextEditingController(
      text: numText(
        s.otRate,
      ),
    );

    daily =
        TextEditingController(
      text: numText(
        s.dailyWage,
      ),
    );

    advance =
        TextEditingController(
      text: numText(
        s.advance,
      ),
    );

    deduction =
        TextEditingController(
      text: numText(
        s.deduction,
      ),
    );
  }

  @override
  void dispose() {
    salary.dispose();
    days.dispose();
    normalHours.dispose();
    otRate.dispose();
    daily.dispose();
    advance.dispose();
    deduction.dispose();

    super.dispose();
  }

  String numText(
    double v,
  ) {
    return v ==
            v.roundToDouble()
        ? '${v.toInt()}'
        : v.toString();
  }

  double d(
    TextEditingController c,
  ) {
    return double.tryParse(
          c.text.trim(),
        ) ??
        0;
  }

  int i(
    TextEditingController c,
  ) {
    return int.tryParse(
          c.text.trim(),
        ) ??
        0;
  }

  String modeName(
    CalcMode m,
  ) {
    switch (m) {
      case CalcMode.fixedDays:
        return 'Fixed Days';

      case CalcMode.monthDays:
        return 'Month Days';

      case CalcMode.dailyWage:
        return 'Daily Wage';
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final keyboard =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              .94,
      padding:
          EdgeInsets.only(
        bottom: keyboard,
      ),
      decoration:
          const BoxDecoration(
        color: C.bg,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Container(
              width: 42,
              height: 4,
              decoration:
                  BoxDecoration(
                color: C.border,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                15,
                10,
                10,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Settings',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w900,
                        color: C.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    icon:
                        const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculation Mode',
                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                        color: C.text,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ...CalcMode.values
                        .map(
                          modeCard,
                        ),
                    const SizedBox(
                      height: 15,
                    ),
                    field(
                      'Monthly Salary',
                      salary,
                      prefix: '₹',
                    ),
                    field(
                      'Standard Working Days',
                      days,
                    ),
                    field(
                      'Normal Working Hours / Day',
                      normalHours,
                      suffix: 'H',
                    ),
                    field(
                      'OT Rate / Hour',
                      otRate,
                      prefix: '₹',
                    ),
                    field(
                      'Daily Wage',
                      daily,
                      prefix: '₹',
                    ),
                    field(
                      'Advance',
                      advance,
                      prefix: '₹',
                    ),
                    field(
                      'Deduction',
                      deduction,
                      prefix: '₹',
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        onPressed: save,
                        icon:
                            const Icon(
                          Icons
                              .save_outlined,
                        ),
                        label:
                            const Text(
                          'Save Configuration',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              C.primary,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
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

  Widget modeCard(
    CalcMode m,
  ) {
    final selected =
        mode == m;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(13),
        onTap: () =>
            setState(
          () => mode = m,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(12),
          decoration:
              BoxDecoration(
            color: selected
                ? C.light
                : Colors.white,
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: selected
                  ? C.primary
                  : C.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons
                        .radio_button_checked
                    : Icons
                        .radio_button_off,
                color: selected
                    ? C.primary
                    : C.sub,
              ),
              const SizedBox(
                width: 9,
              ),
              Text(
                modeName(m),
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                  color: C.text,
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
    TextEditingController controller, {
    String? prefix,
    String? suffix,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
              color: C.text,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          TextField(
            controller:
                controller,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            decoration:
                InputDecoration(
              prefixText:
                  prefix,
              suffixText:
                  suffix,
              filled: true,
              fillColor:
                  Colors.white,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: C.border,
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: C.border,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: C.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void save() {
    Navigator.pop(
      context,
      Settings(
        mode: mode,
        salary: d(salary),
        days: i(days),
        normalHours:
            d(normalHours),
        otRate: d(otRate),
        dailyWage: d(daily),
        advance: d(advance),
        deduction:
            d(deduction),
      ),
    );
  }
}
