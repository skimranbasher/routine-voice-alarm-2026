import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoutineAlarmApp());
}

class RoutineAlarmApp extends StatelessWidget {
  const RoutineAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'রুটিন ও ভয়েস এলার্ম ২০২৬',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

enum TaskCategory { prayer, youtube, office, course, meal, sleep }

class RoutineTask {
  final String id;
  String startTime;
  String endTime;
  final String title;
  final String subtitle;
  final String voiceMessage;
  final TaskCategory category;

  RoutineTask({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.subtitle,
    required this.voiceMessage,
    required this.category,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String _selectedDayType = 'auto';
  bool _alarmEnabled = true;
  String? _lastTriggeredKey;

  Map<String, String> _prayerTimes = {
    'fajr': '05:30',
    'dhuhr': '13:30',
    'asr': '16:15',
    'maghrib': '17:45',
    'isha': '19:30',
  };

  List<bool> _ytVideosDone = List.filled(7, false);

  final List<String> _holidays2026 = [
    '2026-02-04',
    '2026-02-21',
    '2026-03-18',
    '2026-03-19',
    '2026-03-20',
    '2026-03-21',
    '2026-03-26',
    '2026-04-14',
    '2026-05-01',
    '2026-05-04',
    '2026-05-25',
    '2026-06-26',
    '2026-08-05',
    '2026-08-25',
    '2026-09-04',
    '2026-10-20',
    '2026-10-21',
    '2026-12-16',
    '2026-12-25',
  ];

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadSavedData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
      _checkRealTimeAlarm();
    });
  }

  Future<void> _initServices() async {
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmEnabled = prefs.getBool('alarm_enabled') ?? true;
      for (var key in _prayerTimes.keys) {
        _prayerTimes[key] = prefs.getString('prayer_$key') ?? _prayerTimes[key]!;
      }
      for (int i = 0; i < 7; i++) {
        _ytVideosDone[i] = prefs.getBool('yt_done_$i') ?? false;
      }
    });
  }

  Future<void> _savePrayerTime(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_$key', value);
    setState(() {
      _prayerTimes[key] = value;
    });
  }

  Future<void> _toggleYtVideo(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ytVideosDone[index] = !_ytVideosDone[index];
    });
    await prefs.setBool('yt_done_$index', _ytVideosDone[index]);
  }

  String _getEffectiveDayType() {
    if (_selectedDayType != 'auto') return _selectedDayType;
    final dateStr =
        "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}";
    final isGovHoliday = _holidays2026.contains(dateStr);

    if (_now.weekday == DateTime.friday) return 'fri';
    if (_now.weekday == DateTime.saturday || isGovHoliday) return 'sat';
    if (_now.weekday == DateTime.monday || _now.weekday == DateTime.wednesday) {
      return 'mon_wed';
    }
    return 'sun_tue_thu';
  }

  List<RoutineTask> _getTasksForType(String type) {
    final fajr = _prayerTimes['fajr']!;
    final dhuhr = _prayerTimes['dhuhr']!;
    final asr = _prayerTimes['asr']!;
    final maghrib = _prayerTimes['maghrib']!;
    final isha = _prayerTimes['isha']!;

    if (type == 'fri') {
      return [
        RoutineTask(
          id: 'fri_fajr',
          startTime: fajr,
          endTime: '05:45',
          title: 'ফজরের নামায আদায়',
          subtitle: 'ওজু ও ফজরের ফরজ ও সুন্নত নামায',
          voiceMessage: 'এখন ফজরের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'fri_yt1',
          startTime: '05:45',
          endTime: '08:00',
          title: 'ইউটিউব সেশন ১ (৪টি স্ক্রিপ্ট ও ভয়েস)',
          subtitle: 'EverRise Audiobooks: আগামী ৪ দিনের ভিডিওর স্ক্রিপ্ট ও AI ভয়েস',
          voiceMessage: 'এখন ইউটিউব চ্যানেলের প্রথম সেশন এবং স্ক্রিপ্ট তৈরির সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'fri_prep',
          startTime: '08:00',
          endTime: '09:00',
          title: 'সকালের প্রস্তুতি ও নাস্তা (১ম বেলা)',
          subtitle: 'টয়লেট, গোসল ও সকালের খাবার',
          voiceMessage: 'এখন সকালের প্রস্তুতি এবং নাস্তা খাওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
        RoutineTask(
          id: 'fri_yt2',
          startTime: '09:00',
          endTime: '12:15',
          title: 'ইউটিউব সেশন ২ (৪টি ভিডিও রেন্ডারিং)',
          subtitle: 'অডিও এডিটিং ও ৪টি ভিডিও রেন্ডারিং সম্পন্ন করা',
          voiceMessage: 'এখন ইউটিউব ভিডিও এডিটিং এবং রেন্ডারিং করার সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'fri_jummah',
          startTime: dhuhr,
          endTime: '14:30',
          title: 'পবিত্র জুমার নামায ও দুপুরের খাবার',
          subtitle: 'মসজিদে জুমার নামায আদায় এবং ২য় বেলার খাবার',
          voiceMessage: 'এখন পবিত্র জুমার নামায এবং দুপুরের খাবারের সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'fri_asr',
          startTime: asr,
          endTime: '16:30',
          title: 'আছরের নামায আদায়',
          subtitle: 'আছরের নামায ও হালকা বিরতি',
          voiceMessage: 'এখন আছরের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'fri_yt3',
          startTime: '16:30',
          endTime: '17:40',
          title: 'ইউটিউব সেশন ৩ (থাম্বনেইল ও এসইও)',
          subtitle: '৪টি ভিডিওর থাম্বনেইল, টাইটেল ও ডেসক্রিপশন তৈরি',
          voiceMessage: 'এখন ইউটিউব ভিডিওর থাম্বনেইল এবং এসইও করার সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'fri_maghrib',
          startTime: maghrib,
          endTime: '18:00',
          title: 'মাগরিবের নামায আদায়',
          subtitle: 'মাগরিবের নামায আদায়',
          voiceMessage: 'এখন মাগরিবের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'fri_yt4',
          startTime: '18:00',
          endTime: '19:20',
          title: '৪টি ভিডিও আপলোড ও Schedule করা',
          subtitle: 'শনি থেকে মঙ্গলবারের ৪টি ভিডিও শিডিউল করা',
          voiceMessage: 'এখন ইউটিউবে ৪টি ভিডিও আপলোড ও শিডিউল করার সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'fri_isha',
          startTime: isha,
          endTime: '19:45',
          title: 'এশার নামায আদায়',
          subtitle: 'এশার ফরজ, সুন্নত ও বিতর নামায',
          voiceMessage: 'এখন এশার নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'fri_rev',
          startTime: '19:45',
          endTime: '21:30',
          title: 'সাপ্তাহিক কোর্স রিভিশন ও অটোমেশন',
          subtitle: 'AI অটোমেশন ও ইউটিউব কোর্সের প্র্যাকটিস',
          voiceMessage: 'এখন এআই অটোমেশন কোর্সের সাপ্তাহিক প্র্যাকটিস করার সময় হয়েছে।',
          category: TaskCategory.course,
        ),
        RoutineTask(
          id: 'fri_dinner',
          startTime: '21:30',
          endTime: '22:15',
          title: 'রাতের খাবার (৩য় বেলা)',
          subtitle: 'রাতের খাবার ও পারিবারিক সময়',
          voiceMessage: 'এখন রাতের খাবার খাওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
        RoutineTask(
          id: 'fri_sleep',
          startTime: '23:15',
          endTime: '05:15',
          title: 'রাতের ঘুম (৬ ঘণ্টা)',
          subtitle: 'রাত ১১:১৫ থেকে ভোর ৫:১৫ পর্যন্ত টানা ঘুম',
          voiceMessage: 'এখন ঘুমানোর সময় হয়েছে। শুভ রাত্রি।',
          category: TaskCategory.sleep,
        ),
      ];
    }

    if (type == 'sat') {
      return [
        RoutineTask(
          id: 'sat_fajr',
          startTime: fajr,
          endTime: '05:45',
          title: 'ফজরের নামায আদায়',
          subtitle: 'ওজু ও ফজরের নামায',
          voiceMessage: 'এখন ফজরের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'sat_yt1',
          startTime: '05:45',
          endTime: '08:00',
          title: 'ইউটিউব সেশন ১ (বাকি ৩টি স্ক্রিপ্ট ও ভয়েস)',
          subtitle: 'বুধ, বৃহস্পতি ও শুক্রবারের ৩টি ভিডিওর স্ক্রিপ্ট ও ভয়েস',
          voiceMessage: 'এখন ইউটিউবের বাকি ৩টি ভিডিওর স্ক্রিপ্ট তৈরির সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'sat_prep',
          startTime: '08:00',
          endTime: '09:00',
          title: 'সকালের প্রস্তুতি ও নাস্তা (১ম বেলা)',
          subtitle: 'টয়লেট, গোসল ও সকালের নাস্তা',
          voiceMessage: 'এখন সকালের নাস্তা খাওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
        RoutineTask(
          id: 'sat_yt2',
          startTime: '09:00',
          endTime: '13:15',
          title: 'ইউটিউব সেশন ২ (৩টি ভিডিও এডিট ও Schedule)',
          subtitle: '৩টি ভিডিও রেন্ডারিং, থাম্বনেইল ও আপলোড সম্পন্ন করা',
          voiceMessage: 'এখন ৩টি ভিডিও এডিটিং এবং শিডিউল করার সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'sat_dhuhr',
          startTime: dhuhr,
          endTime: '14:15',
          title: 'যোহরের নামায ও দুপুরের খাবার (২য় বেলা)',
          subtitle: 'যোহরের নামায আদায় এবং দুপুরের খাবার',
          voiceMessage: 'এখন যোহরের নামায এবং দুপুরের খাবারের সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'sat_asr',
          startTime: asr,
          endTime: '16:30',
          title: 'আছরের নামায আদায়',
          subtitle: 'আছরের নামায আদায়',
          voiceMessage: 'এখন আছরের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'sat_growth',
          startTime: '16:30',
          endTime: '17:40',
          title: 'ইউটিউব গ্রোথ ও কমেন্ট স্ট্র্যাটেজি',
          subtitle: 'প্রাসঙ্গিক চ্যানেলে কৌশলগত কমেন্ট ও অ্যানালিটিক্স চেক',
          voiceMessage: 'এখন ইউটিউব চ্যানেলের এনগেজমেন্ট ও কমেন্ট করার সময় হয়েছে।',
          category: TaskCategory.youtube,
        ),
        RoutineTask(
          id: 'sat_maghrib',
          startTime: maghrib,
          endTime: '18:00',
          title: 'মাগরিবের নামায আদায়',
          subtitle: 'মাগরিবের নামায আদায়',
          voiceMessage: 'এখন মাগরিবের নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'sat_isha',
          startTime: isha,
          endTime: '19:45',
          title: 'এশার নামায আদায়',
          subtitle: 'এশার নামায ও ক্লাসের প্রস্তুতি',
          voiceMessage: 'এখন এশার নামায আদায় করার সময় হয়েছে।',
          category: TaskCategory.prayer,
        ),
        RoutineTask(
          id: 'sat_ai_class',
          startTime: '20:00',
          endTime: '22:00',
          title: 'এআই অটোমেশন কোর্সের ক্লাস (২ ঘণ্টা)',
          subtitle: 'রাত ৮:০০ থেকে ১০:০০ পর্যন্ত লাইভ ক্লাস',
          voiceMessage: 'এখন এআই অটোমেশন কোর্সের ক্লাসের সময় হয়েছে।',
          category: TaskCategory.course,
        ),
        RoutineTask(
          id: 'sat_dinner',
          startTime: '22:00',
          endTime: '22:30',
          title: 'রাতের খাবার (৩য় বেলা)',
          subtitle: 'রাতের খাবার ও আগামীকাল অফিসের প্রস্তুতি',
          voiceMessage: 'এখন রাতের খাবার খাওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
        RoutineTask(
          id: 'sat_sleep',
          startTime: '23:15',
          endTime: '05:15',
          title: 'রাতের ঘুম (৬ ঘণ্টা)',
          subtitle: 'রাত ১১:১৫ থেকে ভোর ৫:১৫ পর্যন্ত ঘুম',
          voiceMessage: 'এখন ঘুমানোর সময় হয়েছে। শুভ রাত্রি।',
          category: TaskCategory.sleep,
        ),
      ];
    }

    List<RoutineTask> officeTasks = [
      RoutineTask(
        id: 'off_fajr',
        startTime: fajr,
        endTime: '05:45',
        title: 'ফজরের নামায আদায়',
        subtitle: 'ভোর ৫:১৫-তে ওঠা, ওজু ও ফজরের নামায',
        voiceMessage: 'এখন ফজরের নামায আদায় করার সময় হয়েছে।',
        category: TaskCategory.prayer,
      ),
      RoutineTask(
        id: 'off_deep',
        startTime: '05:45',
        endTime: '07:30',
        title: 'সকালের ডিপ ওয়ার্ক (১ ঘণ্টা ৪৫ মি.)',
        subtitle: 'ইউটিউব স্ক্রিপ্টিং বা গত রাতের AI ক্লাস প্র্যাকটিস',
        voiceMessage: 'এখন সকালের ডিপ ওয়ার্ক এবং ইউটিউব কাজের সময় হয়েছে।',
        category: TaskCategory.youtube,
      ),
      RoutineTask(
        id: 'off_prep',
        startTime: '07:30',
        endTime: '08:15',
        title: 'অফিসের প্রস্তুতি ও টয়লেট (৪৫ মিনিট)',
        subtitle: 'পায়খানা/টয়লেট সারা, গোসল ও অফিসের পোশাক পরা',
        voiceMessage: 'এখন অফিসের প্রস্তুতি নেওয়ার সময় হয়েছে।',
        category: TaskCategory.office,
      ),
      RoutineTask(
        id: 'off_breakfast',
        startTime: '08:15',
        endTime: '08:45',
        title: 'সকালের নাস্তা (১ম বেলার খাবার)',
        subtitle: 'নাস্তা খাওয়া ও অফিসের ব্যাগ গুছিয়ে নেওয়া',
        voiceMessage: 'এখন সকালের নাস্তা খাওয়ার সময় হয়েছে।',
        category: TaskCategory.meal,
      ),
      RoutineTask(
        id: 'off_commute_go',
        startTime: '08:45',
        endTime: '09:00',
        title: 'অফিসে যাতায়াত (১৫ মিনিট)',
        subtitle: 'সকাল ৯:০০টার মধ্যে অফিসে পৌঁছানো',
        voiceMessage: 'এখন অফিসের উদ্দেশ্যে রওনা দেওয়ার সময় হয়েছে।',
        category: TaskCategory.office,
      ),
      RoutineTask(
        id: 'off_work1',
        startTime: '09:00',
        endTime: '13:15',
        title: 'সরকারি অফিসের কাজ (১ম পর্ব)',
        subtitle: 'মনোযোগ দিয়ে অফিসের দায়িত্ব পালন',
        voiceMessage: 'এখন অফিসের কাজ শুরু করার সময় হয়েছে।',
        category: TaskCategory.office,
      ),
      RoutineTask(
        id: 'off_dhuhr',
        startTime: dhuhr,
        endTime: '14:00',
        title: 'যোহরের নামায ও দুপুরের খাবার (২য় বেলা)',
        subtitle: 'অফিসে যোহরের নামায ও দুপুরের খাবার বিরতি',
        voiceMessage: 'এখন যোহরের নামায এবং দুপুরের খাবারের সময় হয়েছে।',
        category: TaskCategory.prayer,
      ),
      RoutineTask(
        id: 'off_asr',
        startTime: asr,
        endTime: '16:30',
        title: 'আছরের নামায আদায়',
        subtitle: 'অফিসে আছরের নামায আদায়',
        voiceMessage: 'এখন আছরের নামায আদায় করার সময় হয়েছে।',
        category: TaskCategory.prayer,
      ),
      RoutineTask(
        id: 'off_maghrib',
        startTime: maghrib,
        endTime: '18:00',
        title: 'মাগরিবের নামায আদায়',
        subtitle: 'অফিসেই মাগরিবের নামায আদায় করে নেওয়া',
        voiceMessage: 'এখন মাগরিবের নামায আদায় করার সময় হয়েছে।',
        category: TaskCategory.prayer,
      ),
      RoutineTask(
        id: 'off_commute_back',
        startTime: '18:30',
        endTime: '18:45',
        title: 'অফিস ছুটি ও বাসায় ফেরা (১৫ মিনিট)',
        subtitle: 'সন্ধ্যা ৬:৩০-এ অফিস শেষ করে বাসায় ফেরা',
        voiceMessage: 'এখন অফিস ছুটি এবং বাসায় ফেরার সময় হয়েছে।',
        category: TaskCategory.office,
      ),
      RoutineTask(
        id: 'off_yt_daily',
        startTime: '18:45',
        endTime: '19:20',
        title: 'ফ্রেশ হওয়া ও ইউটিউব ডেইলি টাস্ক',
        subtitle: 'আজকের শিডিউল ভিডিও পাবলিশ চেক ও কমেন্ট রিপ্লাই',
        voiceMessage: 'এখন ইউটিউব চ্যানেলের প্রতিদিনের ভিডিও চেক করার সময় হয়েছে।',
        category: TaskCategory.youtube,
      ),
      RoutineTask(
        id: 'off_isha',
        startTime: isha,
        endTime: '19:45',
        title: 'এশার নামায আদায়',
        subtitle: 'এশার নামায আদায়',
        voiceMessage: 'এখন এশার নামায আদায় করার সময় হয়েছে।',
        category: TaskCategory.prayer,
      ),
    ];

    if (type == 'mon_wed') {
      officeTasks.addAll([
        RoutineTask(
          id: 'mw_dinner',
          startTime: '19:40',
          endTime: '20:00',
          title: 'রাতের খাবার (ক্লাস শুরুর আগে)',
          subtitle: 'সোম ও বুধবার দুটি ক্লাস থাকায় আগেই রাতের খাবার সম্পন্ন',
          voiceMessage: 'এখন রাতের খাবার খেয়ে নেওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
        RoutineTask(
          id: 'mw_ai_class',
          startTime: '20:00',
          endTime: '21:30',
          title: 'এআই অটোমেশন ক্লাস (১.৫ ঘণ্টা লাইভ)',
          subtitle: 'রাত ৯:৩০-এ শেষ ৩০ মিনিট স্ক্রিন রেকর্ড চালু রেখে ইউটিউব ক্লাসে জয়েন',
          voiceMessage: 'এখন এআই অটোমেশন কোর্সের ক্লাসের সময় হয়েছে।',
          category: TaskCategory.course,
        ),
        RoutineTask(
          id: 'mw_yt_class',
          startTime: '21:30',
          endTime: '23:00',
          title: 'ইউটিউব কোর্সের ক্লাস (সোম ও বুধ)',
          subtitle: 'রাত ৯:৩০ থেকে ১১:০০ পর্যন্ত ইউটিউব কোর্স ক্লাস',
          voiceMessage: 'এখন ইউটিউব কোর্সের ক্লাসে জয়েন করার সময় হয়েছে।',
          category: TaskCategory.course,
        ),
      ]);
    } else {
      officeTasks.addAll([
        RoutineTask(
          id: 'stt_ai_class',
          startTime: '20:00',
          endTime: '22:00',
          title: 'এআই অটোমেশন কোর্সের ক্লাস (২ ঘণ্টা)',
          subtitle: 'রাত ৮:০০ থেকে ১০:০০ পর্যন্ত লাইভ ক্লাস',
          voiceMessage: 'এখন এআই অটোমেশন কোর্সের ক্লাসের সময় হয়েছে।',
          category: TaskCategory.course,
        ),
        RoutineTask(
          id: 'stt_dinner',
          startTime: '22:00',
          endTime: '22:30',
          title: 'রাতের খাবার (৩য় বেলার খাবার)',
          subtitle: 'ক্লাস শেষে রাতের খাবার ও বিশ্রাম',
          voiceMessage: 'এখন রাতের খাবার খাওয়ার সময় হয়েছে।',
          category: TaskCategory.meal,
        ),
      ]);
    }

    officeTasks.add(
      RoutineTask(
        id: 'off_sleep',
        startTime: '23:15',
        endTime: '05:15',
        title: 'রাতের ঘুম (৬ ঘণ্টা)',
        subtitle: 'রাত ১১:১৫ থেকে ভোর ৫:১৫ পর্যন্ত টানা ঘুম',
        voiceMessage: 'এখন ঘুমানোর সময় হয়েছে। শুভ রাত্রি।',
        category: TaskCategory.sleep,
      ),
    );

    return officeTasks;
  }

  Future<void> _playDistinctEffect(TaskCategory category) async {
    switch (category) {
      case TaskCategory.prayer:
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 250));
        await HapticFeedback.heavyImpact();
        break;
      case TaskCategory.youtube:
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
        break;
      case TaskCategory.office:
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.vibrate();
        break;
      case TaskCategory.course:
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case TaskCategory.meal:
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.lightImpact();
        break;
      case TaskCategory.sleep:
        await HapticFeedback.lightImpact();
        break;
    }
  }

  Future<void> _speakAlarm(String message, [TaskCategory? category]) async {
    if (category != null) {
      await _playDistinctEffect(category);
    }
    await _flutterTts.speak(message);
  }

  void _checkRealTimeAlarm() {
    if (!_alarmEnabled) return;
    final currentHM =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";
    final key = "${_now.day}_$currentHM";
    if (_lastTriggeredKey == key) return;

    final tasks = _getTasksForType(_getEffectiveDayType());
    for (final task in tasks) {
      if (task.startTime == currentHM && _now.second < 3) {
        _lastTriggeredKey = key;
        _speakAlarm(task.voiceMessage, task.category);
        _showAlarmDialog(task);
        break;
      }
    }
  }

  void _showAlarmDialog(RoutineTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Icon(_getCategoryIcon(task.category),
                color: _getCategoryColor(task.category)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '${task.voiceMessage}\n\nসময়: ${task.startTime} - ${task.endTime}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              _flutterTts.stop();
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('ঠিক আছে (বন্ধ করুন)'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.prayer:
        return const Color(0xFF10B981);
      case TaskCategory.youtube:
        return const Color(0xFFF43F5E);
      case TaskCategory.office:
        return const Color(0xFF38BDF8);
      case TaskCategory.course:
        return const Color(0xFFA855F7);
      case TaskCategory.meal:
        return const Color(0xFFF59E0B);
      case TaskCategory.sleep:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.prayer:
        return Icons.mosque;
      case TaskCategory.youtube:
        return Icons.play_circle_fill;
      case TaskCategory.office:
        return Icons.work;
      case TaskCategory.course:
        return Icons.memory;
      case TaskCategory.meal:
        return Icons.restaurant;
      case TaskCategory.sleep:
        return Icons.bedtime;
    }
  }

  void _openPrayerSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final labels = {
          'fajr': 'ফজরের নামায',
          'dhuhr': 'যোহরের নামায',
          'asr': 'আছরের নামায',
          'maghrib': 'মাগরিবের নামায',
          'isha': 'এশার নামায',
        };
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🕌 ইসলামিক ফাউন্ডেশনের নামাযের সময়সূচী আপডেট',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...labels.entries.map((entry) {
                return ListTile(
                  dense: true,
                  title: Text(entry.value),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final parts = _prayerTimes[entry.key]!.split(':');
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        ),
                      );
                      if (picked != null) {
                        final formatted =
                            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                        await _savePrayerTime(entry.key, formatted);
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
                    child: Text(_prayerTimes[entry.key]!),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveType = _getEffectiveDayType();
    final tasks = _getTasksForType(effectiveType);
    final doneCount = _ytVideosDone.where((e) => e).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('রুটিন ও ভয়েস এলার্ম ২০২৬',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('সরকারি চাকরি • ৫ ওয়াক্ত নামায • EverRise Audiobooks',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'নামাযের ওয়াক্ত পরিবর্তন',
            icon: const Icon(Icons.mosque, color: Color(0xFF10B981)),
            onPressed: _openPrayerSettingsModal,
          ),
          Switch(
            value: _alarmEnabled,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('alarm_enabled', val);
              setState(() => _alarmEnabled = val);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'সাপ্তাহিক ভিডিও: $doneCount / 7',
                        style: const TextStyle(
                            color: Color(0xFFF43F5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    const days = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];
                    final done = _ytVideosDone[index];
                    return GestureDetector(
                      onTap: () => _toggleYtVideo(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF10B981)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: done ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildDayChip('auto', 'আজকের রুটিন (Auto)'),
                _buildDayChip('sun_tue_thu', 'রবি/মঙ্গল/বৃহঃ'),
                _buildDayChip('mon_wed', 'সোম ও বুধ (২ ক্লাস)'),
                _buildDayChip('fri', 'শুক্রবার (৪ ভিডিও)'),
                _buildDayChip('sat', 'শনিবার/ছুটি (৩ ভিডিও)'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: tasks.length,
              itemBuilder: (ctx, i) {
                final t = tasks[i];
                final color = _getCategoryColor(t.category);
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.4), width: 1),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(_getCategoryIcon(t.category),
                          color: color, size: 20),
                    ),
                    title: Text(
                      t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          '⏰ ${t.startTime} - ${t.endTime}',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                        Text(t.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'ভয়েস ও এলার্ম টেস্ট করুন',
                      icon: const Icon(Icons.volume_up, color: Color(0xFF38BDF8)),
                      onPressed: () =>
                          _speakAlarm(t.voiceMessage, t.category),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String key, String label) {
    final selected = _selectedDayType == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: const Color(0xFF38BDF8),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) => setState(() => _selectedDayType = key),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
