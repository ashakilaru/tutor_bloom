import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

const ink = Color(0xFF183C32);
const paper = Color(0xFFF7F8F2);
const lime = Color(0xFFD8F58B);
String money(num n) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
).format(n);
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BloomApp());
}

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Tutor Bloom',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        surface: paper,
      ),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: const Home(),
  );
}

class Student {
  String id, name, subject, phone;
  int fee, due;
  DateTime joiningMonth;
  Map<String, int> payments;
  Student(
    this.id,
    this.name,
    this.subject,
    this.phone,
    this.fee,
    this.due,
    this.payments, {
    DateTime? joiningMonth,
  }) : joiningMonth = DateTime(
         (joiningMonth ?? DateTime.now()).year,
         (joiningMonth ?? DateTime.now()).month,
       );
  bool activeIn(DateTime month) =>
      !DateTime(month.year, month.month).isBefore(joiningMonth);
  int feeFor(DateTime month) => activeIn(month) ? fee : 0;
  int paidFor(DateTime month) =>
      payments[DateFormat('yyyy-MM').format(month)] ?? 0;
  int balanceFor(DateTime month) =>
      (feeFor(month) - paidFor(month)).clamp(0, fee);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'phone': phone,
    'fee': fee,
    'due': due,
    'payments': payments,
    'joiningMonth': DateFormat('yyyy-MM').format(joiningMonth),
  };
  factory Student.fromJson(Map<String, dynamic> j) {
    DateTime joined;
    if (j['joiningMonth'] != null) {
      joined = DateFormat('yyyy-MM').parseStrict(j['joiningMonth']);
    } else {
      // Older records have no enrollment field. Use creation time where available,
      // and retain any earlier month with a recorded payment.
      final stamp = int.tryParse(j['id']);
      joined = stamp != null && stamp > 1000000000000000
          ? DateTime.fromMicrosecondsSinceEpoch(stamp)
          : DateTime.now();
      for (final key in (j['payments'] as Map).keys) {
        final date = DateFormat('yyyy-MM').parseStrict(key);
        if (date.isBefore(joined)) joined = date;
      }
    }
    return Student(
      j['id'],
      j['name'],
      j['subject'],
      j['phone'],
      j['fee'],
      j['due'],
      Map<String, int>.from(j['payments']),
      joiningMonth: joined,
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Student> students = [];
  bool loaded = false, demo = false;
  int tab = 0;
  String query = '', filter = 'All';
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String get keyMonth => DateFormat('yyyy-MM').format(month);
  Iterable<Student> get activeStudents =>
      students.where((s) => s.activeIn(month));
  int paid(Student s) => s.paidFor(month);
  int balance(Student s) => s.balanceFor(month);
  bool overdue(Student s) =>
      balance(s) > 0 &&
      DateTime.now().isAfter(DateTime(month.year, month.month, s.due, 23, 59));
  int get total => students.fold(0, (a, s) => a + s.feeFor(month));
  int get collected => students.fold(0, (a, s) => a + paid(s));
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('bloom_v1');
      if (raw != null) {
        final j = jsonDecode(raw);
        students = (j['students'] as List)
            .map((e) => Student.fromJson(e))
            .toList();
        demo = j['demo'] ?? false;
      }
    } catch (_) {
      if (mounted) {
        message(
          'Could not load saved data. Please restart before adding students.',
        );
      }
    }
    if (mounted) setState(() => loaded = true);
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!await p.setString(
        'bloom_v1',
        jsonEncode({
          'students': students.map((s) => s.toJson()).toList(),
          'demo': demo,
        }),
      )) {
        throw Exception();
      }
    } catch (_) {
      message('Unable to save changes. Keep the app open and try again.');
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void seed() {
    setState(() {
      demo = true;
      students = [
        Student('1', 'Ananya Sharma', 'Mathematics · Grade 10', '', 1800, 5, {
          keyMonth: 1800,
        }),
        Student('2', 'Rohan Mehta', 'Science · Grade 9', '', 1500, 5, {}),
        Student('3', 'Sara Khan', 'Mathematics · Grade 10', '', 1800, 10, {
          keyMonth: 900,
        }),
        Student('4', 'Arjun Patel', 'Physics · Grade 12', '', 2400, 15, {
          keyMonth: 2400,
        }),
        Student('5', 'Diya Rao', 'Science · Grade 9', '', 1500, 5, {
          keyMonth: 1500,
        }),
      ];
    });
    save();
  }

  Future<void> addStudent() async {
    final name = TextEditingController(),
        subject = TextEditingController(),
        phone = TextEditingController(),
        fee = TextEditingController(),
        due = TextEditingController(text: '5');
    DateTime joined = DateTime(DateTime.now().year, DateTime.now().month);
    final joining = TextEditingController(
      text: DateFormat('MMMM yyyy').format(joined),
    );
    final form = GlobalKey<FormState>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(c).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new face. A new possibility.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Student name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject / class',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp number with country code',
                    hintText: '+91 98765 43210',
                  ),
                  validator: (v) =>
                      v!.isNotEmpty && !RegExp(r'^\+?[0-9 ]{8,18}$').hasMatch(v)
                      ? 'Enter a valid number with country code'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: joining,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Joining month',
                    helperText: 'Fees begin in this month. No earlier dues.',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: joined,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (date != null) {
                      joined = DateTime(date.year, date.month);
                      joining.text = DateFormat('MMMM yyyy').format(joined);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: fee,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly fee (₹)',
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter a positive amount'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: due,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Due day (1–28)',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '') ?? 0;
                          return n < 1 || n > 28 ? 'Choose 1–28' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      setState(
                        () => students.add(
                          Student(
                            DateTime.now().microsecondsSinceEpoch.toString(),
                            name.text.trim(),
                            subject.text.trim(),
                            phone.text.trim(),
                            int.parse(fee.text),
                            int.parse(due.text),
                            {},
                            joiningMonth: joined,
                          ),
                        ),
                      );
                      save();
                      Navigator.pop(c);
                    },
                    child: const Text('Add student'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> payment(Student s) async {
    if (!s.activeIn(month) || balance(s) <= 0) return;
    final amount = TextEditingController(text: balance(s).toString());
    final form = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Payment for ${s.name.split(' ').first}'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('MMMM yyyy').format(month)} · ${money(balance(s))} remaining',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount received (₹)',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '') ?? 0;
                  return n <= 0 || n > balance(s)
                      ? 'Enter ₹1 to ${balance(s)}'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Records money you have already received.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              setState(
                () => s.payments[keyMonth] = paid(s) + int.parse(amount.text),
              );
              save();
              Navigator.pop(c);
              message('Payment recorded');
            },
            child: const Text('Record payment'),
          ),
        ],
      ),
    );
  }

  Future<void> remind(Student s) async {
    if (!s.activeIn(month) || balance(s) <= 0) return;
    final text =
        'Hi! A friendly reminder that ${money(balance(s))} is pending for ${s.name}’s ${DateFormat('MMMM yyyy').format(month)} tuition fees. Thank you!';
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('A friendly nudge'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (c.mounted) Navigator.pop(c);
              message('Reminder copied');
            },
            child: const Text('Copy text'),
          ),
          FilledButton(
            onPressed: s.phone.isEmpty
                ? null
                : () async {
                    final uri = Uri.https(
                      'wa.me',
                      '/${s.phone.replaceAll(RegExp(r'\D'), '')}',
                      {'text': text},
                    );
                    try {
                      if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        message(
                          'Could not open WhatsApp. Copy the reminder instead.',
                        );
                      }
                    } catch (_) {
                      message(
                        'Could not open WhatsApp. Copy the reminder instead.',
                      );
                    }
                  },
            child: const Text('Open WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> details(Student s) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            Text(s.subject),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(c);
                final date = await showDatePicker(
                  context: context,
                  initialDate: s.joiningMonth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100, 12, 31),
                );
                if (date == null || !mounted) return;
                final next = DateTime(date.year, date.month);
                if (s.payments.entries.any(
                  (e) =>
                      e.value > 0 &&
                      DateFormat('yyyy-MM').parseStrict(e.key).isBefore(next),
                )) {
                  message(
                    'A payment exists before that month. Correct it first, or choose an earlier joining month.',
                  );
                  return;
                }
                setState(() => s.joiningMonth = next);
                save();
              },
              icon: const Icon(Icons.edit_calendar, size: 18),
              label: Text(
                'Joined ${DateFormat('MMM yyyy').format(s.joiningMonth)} · Edit',
              ),
            ),
            if (!s.activeIn(month))
              const Text(
                'Not enrolled in this month · No fees due',
                style: TextStyle(color: ink),
              ),
            const SizedBox(height: 24),
            Text('${money(s.fee)} / month · Due on day ${s.due}'),
            const SizedBox(height: 8),
            Text(
              '${money(paid(s))} received in ${DateFormat('MMMM').format(month)}',
            ),
            const SizedBox(height: 24),
            if (balance(s) > 0)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(c);
                        payment(s);
                      },
                      child: const Text('Record payment'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.pop(c);
                      remind(s);
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                ],
              ),
            if (paid(s) > 0)
              TextButton(
                onPressed: () async {
                  Navigator.pop(c);
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('Reset this month’s payments?'),
                      content: Text(
                        'Remove the ${money(paid(s))} recorded for ${s.name} in ${DateFormat('MMMM yyyy').format(month)}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    setState(() => s.payments.remove(keyMonth));
                    save();
                  }
                },
                child: const Text('Correct / reset this month'),
              ),
          ],
        ),
      ),
    );
  }

  Widget label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: ink,
    ),
  );
  Widget studentRow(Student s) {
    final settled = balance(s) == 0;
    final color = settled
        ? ink
        : overdue(s)
        ? const Color(0xFFAA512E)
        : const Color(0xFF796A29);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        onTap: () => details(s),
        leading: CircleAvatar(
          backgroundColor: [
            const Color(0xFFE8EDD8),
            const Color(0xFFF7E6D7),
            const Color(0xFFEAE3F5),
          ][s.name.length % 3],
          child: Text(
            s.name
                .split(' ')
                .where((e) => e.isNotEmpty)
                .take(2)
                .map((e) => e[0])
                .join(),
            style: const TextStyle(color: ink, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          s.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          s.subject.isEmpty ? 'Private tuition' : s.subject,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              money(settled ? paid(s) : balance(s)),
              style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
            const SizedBox(height: 4),
            Text(
              !s.activeIn(month)
                  ? 'Not joined yet'
                  : settled
                  ? '✓ Paid'
                  : overdue(s)
                  ? 'Overdue'
                  : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget monthPicker() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Previous month',
        onPressed: () =>
            setState(() => month = DateTime(month.year, month.month - 1)),
        icon: const Icon(Icons.chevron_left, size: 20),
      ),
      Text(
        DateFormat('MMM yyyy').format(month),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      IconButton(
        tooltip: 'Next month',
        onPressed: () =>
            setState(() => month = DateTime(month.year, month.month + 1)),
        icon: const Icon(Icons.chevron_right, size: 20),
      ),
    ],
  );
  Widget dashboard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: label('YOUR TEACHING, IN BLOOM')),
          const Icon(Icons.auto_awesome, color: ink, size: 20),
        ],
      ),
      const SizedBox(height: 14),
      const Text(
        'Less chasing.\nMore teaching.',
        style: TextStyle(
          fontSize: 38,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.8,
          color: ink,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'A little clarity for your growing classroom.',
        style: TextStyle(color: Colors.black54, fontSize: 14),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'COLLECTED THIS MONTH',
                    style: TextStyle(
                      color: Color(0xFFCAE0CA),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.north_east, color: lime),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              money(collected),
              style: const TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'of ${money(total)} expected',
              style: const TextStyle(color: Color(0xFFCAE0CA)),
            ),
            const SizedBox(height: 25),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (collected / total).clamp(0, 1),
                minHeight: 8,
                color: lime,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  '${total == 0 ? 0 : (collected / total * 100).round()}% collected',
                  style: const TextStyle(
                    color: lime,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${activeStudents.where((s) => balance(s) == 0).length} of ${activeStudents.length} paid',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: stat(
              'Still to collect',
              money(total - collected),
              Icons.account_balance_wallet_outlined,
              const Color(0xFFECEFDE),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: stat(
              'Enrolled this month',
              '${activeStudents.length}',
              Icons.people_outline,
              const Color(0xFFECE7F3),
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Needs a little nudge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => tab = 2),
            child: const Text('View all'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (students.every((s) => balance(s) == 0))
        empty('All caught up ✨', 'Your classroom has a clean slate.'),
      ...students.where((s) => balance(s) > 0).take(3).map(studentRow),
    ],
  );
  Widget stat(String title, String value, IconData icon, Color bg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ink, size: 23),
        const SizedBox(height: 18),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: ink)),
      ],
    ),
  );
  Widget empty(String title, String sub) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, size: 48, color: ink),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
  Widget listing() {
    final list = students
        .where(
          (s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) &&
              (tab != 2 || balance(s) > 0) &&
              (filter != 'Paid' || (s.activeIn(month) && balance(s) == 0)) &&
              (filter != 'Pending' || balance(s) > 0) &&
              (filter != 'Overdue' || overdue(s)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tab == 1 ? 'Your classroom.' : 'A gentle follow-up.',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tab == 1
              ? 'Small details. Stronger connections.'
              : 'Tap a student to record a payment or draft a reminder.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 22),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search students',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                (tab == 1
                        ? ['All', 'Paid', 'Pending', 'Overdue']
                        : ['All', 'Overdue'])
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: filter == f,
                          onSelected: (_) => setState(() => filter = f),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (list.isEmpty)
          empty('Nothing here yet', 'Add a student or try a different filter.'),
        ...list.map(studentRow),
      ],
    );
  }

  Widget settings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Room to grow.',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 20),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private by design',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 12),
              Text(
                'Your records are saved on this device. There is no account or cloud sync yet. Uninstalling the app or clearing browser storage can erase them.',
              ),
              SizedBox(height: 12),
              Text(
                'Monthly fees start in the joining month (a full month’s fee). Earlier months have no dues. You can edit the joining month from a student’s details.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () async {
          final data = jsonEncode({
            'students': students.map((s) => s.toJson()).toList(),
            'demo': demo,
          });
          await Clipboard.setData(ClipboardData(text: data));
          message('Backup copied. Save it somewhere private.');
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy data backup'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          final controller = TextEditingController();
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Restore a backup'),
              content: TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Paste your Tutor Bloom backup. This replaces current records.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      final j = jsonDecode(controller.text);
                      final restored = (j['students'] as List)
                          .map((e) => Student.fromJson(e))
                          .toList();
                      if (restored.any(
                        (s) =>
                            s.name.trim().isEmpty ||
                            s.fee <= 0 ||
                            s.due < 1 ||
                            s.due > 28 ||
                            s.payments.values.any((p) => p < 0 || p > s.fee),
                      )) {
                        throw Exception();
                      }
                      setState(() {
                        students = restored;
                        demo = j['demo'] == true;
                      });
                      save();
                      Navigator.pop(c);
                      message('Backup restored');
                    } catch (_) {
                      message('This backup is not valid. Nothing was changed.');
                    }
                  },
                  child: const Text('Replace and restore'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.restore),
        label: const Text('Restore data backup'),
      ),
      if (demo)
        TextButton(
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Start a fresh classroom?'),
                content: const Text(
                  'This clears all records in the demo, including any you added.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Clear demo'),
                  ),
                ],
              ),
            );
            if (yes == true) {
              setState(() {
                students = [];
                demo = false;
              });
              save();
            }
          },
          child: const Text('Clear demo and start fresh'),
        ),
      const SizedBox(height: 28),
      label('TUTOR BLOOM · EARLY PREVIEW'),
      const SizedBox(height: 10),
      const Text(
        'Made for independent teachers.\nOne less thing on your mind.',
        style: TextStyle(color: Colors.black54, height: 1.6),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, size: 26),
            SizedBox(width: 8),
            Text(
              'bloom',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
      actions: [if (tab != 3) monthPicker()],
    ),
    body: !loaded
        ? const Center(child: CircularProgressIndicator())
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                key: ValueKey(tab),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
                children: [
                  if (demo)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lime,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DEMO CLASSROOM · Sample records',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (students.isEmpty && tab == 0) ...[
                    FilledButton.icon(
                      onPressed: addStudent,
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first student'),
                    ),
                    TextButton(
                      onPressed: seed,
                      child: const Text('Explore a sample classroom'),
                    ),
                    const SizedBox(height: 20),
                    dashboard(),
                  ] else if (tab == 0)
                    dashboard()
                  else if (tab == 3)
                    settings()
                  else
                    listing(),
                ],
              ),
            ),
          ),
    floatingActionButton: tab < 2 && students.isNotEmpty
        ? FloatingActionButton.extended(
            backgroundColor: lime,
            foregroundColor: ink,
            onPressed: addStudent,
            icon: const Icon(Icons.add),
            label: const Text('Add student'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: lime,
      selectedIndex: tab,
      onDestinationSelected: (v) => setState(() {
        tab = v;
        filter = 'All';
        query = '';
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Students',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Reminders',
        ),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
      ],
    ),
  );
}
