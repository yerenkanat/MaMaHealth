import '../../core/network/api_client.dart';

class MeProfile {
  const MeProfile({
    required this.name,
    required this.city,
    required this.points,
    required this.streak,
    required this.children,
  });

  final String name;
  final String? city;
  final int points;
  final int streak;
  final int children;

  factory MeProfile.fromJson(Map<String, dynamic> j) => MeProfile(
        name: j['name'] as String? ?? 'Мама',
        city: j['city'] as String?,
        points: (j['points'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        children: (j['children'] as num?)?.toInt() ?? 0,
      );
}

class CheckinResult {
  const CheckinResult({required this.streak, required this.points, required this.awarded});
  final int streak;
  final int points;
  final bool awarded;

  factory CheckinResult.fromJson(Map<String, dynamic> j) => CheckinResult(
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        points: (j['points'] as num?)?.toInt() ?? 0,
        awarded: j['awarded'] as bool? ?? false,
      );
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.category,
    required this.isCritical,
    required this.fireDate,
    required this.profileType,
  });

  final String id;
  final String title;
  final String category; // vaccination | screening | checkup
  final bool isCritical;
  final DateTime fireDate;
  final String profileType; // PREGNANCY | CHILD

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        isCritical: j['isCritical'] as bool? ?? false,
        fireDate: DateTime.tryParse(j['fireDate'] as String? ?? '') ?? DateTime.now(),
        profileType: j['profileType'] as String? ?? 'CHILD',
      );
}

class WeightPoint {
  const WeightPoint({required this.week, required this.gainKg});
  final int week;
  final double gainKg;

  factory WeightPoint.fromJson(Map<String, dynamic> j) => WeightPoint(
        week: (j['week'] as num).toInt(),
        gainKg: (j['gainKg'] as num).toDouble(),
      );
}

class KickSession {
  const KickSession({
    required this.count,
    required this.durationSeconds,
    required this.createdAt,
  });

  final int count;
  final int durationSeconds;
  final DateTime createdAt;

  factory KickSession.fromJson(Map<String, dynamic> j) => KickSession(
        count: (j['count'] as num).toInt(),
        durationSeconds: (j['durationSeconds'] as num).toInt(),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class ContractionLog {
  const ContractionLog({
    required this.durationSeconds,
    required this.intervalSeconds,
    required this.createdAt,
  });

  final int durationSeconds;
  final int? intervalSeconds;
  final DateTime createdAt;

  factory ContractionLog.fromJson(Map<String, dynamic> j) => ContractionLog(
        durationSeconds: (j['durationSeconds'] as num).toInt(),
        intervalSeconds: (j['intervalSeconds'] as num?)?.toInt(),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class DailyLog {
  const DailyLog({
    required this.date,
    required this.mood,
    required this.symptoms,
    required this.note,
  });

  final String date; // YYYY-MM-DD
  final String? mood; // great | good | ok | low | bad
  final List<String> symptoms;
  final String? note;

  factory DailyLog.fromJson(Map<String, dynamic> j) => DailyLog(
        date: j['date'] as String,
        mood: j['mood'] as String?,
        symptoms: ((j['symptoms'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
        note: j['note'] as String?,
      );
}

abstract interface class EngagementService {
  Future<MeProfile> me();
  Future<CheckinResult> checkin();
  Future<List<Reminder>> reminders();
  Future<List<WeightPoint>> weight();
  Future<void> saveWeight(int week, double gainKg);
  Future<List<KickSession>> kicks();
  Future<void> saveKick(int count, int durationSeconds);
  Future<List<ContractionLog>> contractions();
  Future<void> saveContraction(int durationSeconds, int? intervalSeconds);
  Future<List<DailyLog>> dailyLogs();
  Future<void> saveDaily(String date, String? mood, List<String> symptoms, String? note);
  Future<List<String>> checklistState(String key);
  Future<void> saveChecklistState(String key, List<String> items);
  Future<List<ChatTurn>> chatHistory();
  Future<void> saveChatMessage(String role, String text);
  Future<List<BabyEvent>> babyEvents();
  Future<void> saveBabyEvent(String type, String? detail);
  Future<void> setDueDate(String date);
  Future<List<CyclePeriod>> cycles();
  Future<void> saveCycle(DateTime start, DateTime? end);
}

class CyclePeriod {
  const CyclePeriod({required this.start, this.end});
  final DateTime start;
  final DateTime? end;

  static DateTime _d(String s) => DateTime.parse(s);

  factory CyclePeriod.fromJson(Map<String, dynamic> j) => CyclePeriod(
        start: _d(j['startDate'] as String),
        end: j['endDate'] == null ? null : _d(j['endDate'] as String),
      );
}

class BabyEvent {
  const BabyEvent({
    required this.type,
    required this.detail,
    required this.happenedAt,
  });

  final String type; // feed | sleep | diaper
  final String? detail;
  final DateTime happenedAt;

  factory BabyEvent.fromJson(Map<String, dynamic> j) => BabyEvent(
        type: j['type'] as String,
        detail: j['detail'] as String?,
        happenedAt:
            DateTime.tryParse(j['happenedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role; // user | assistant
  final String text;

  factory ChatTurn.fromJson(Map<String, dynamic> j) =>
      ChatTurn(role: j['role'] as String, text: j['text'] as String);
}

/// Боевая реализация — ходит в backend.
class ApiEngagementService implements EngagementService {
  ApiEngagementService(this._api);
  final ApiClient _api;

  @override
  Future<MeProfile> me() async =>
      MeProfile.fromJson(await _api.get('/me') as Map<String, dynamic>);

  @override
  Future<CheckinResult> checkin() async =>
      CheckinResult.fromJson(await _api.post('/me/checkin', const {}) as Map<String, dynamic>);

  @override
  Future<List<Reminder>> reminders() async {
    final data = await _api.get('/reminders') as List<dynamic>;
    return data.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<WeightPoint>> weight() async {
    final data = await _api.get('/me/weight') as List<dynamic>;
    return data.map((e) => WeightPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveWeight(int week, double gainKg) async {
    await _api.post('/me/weight', {'week': week, 'gainKg': gainKg});
  }

  @override
  Future<List<KickSession>> kicks() async {
    final data = await _api.get('/me/kicks') as List<dynamic>;
    return data.map((e) => KickSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveKick(int count, int durationSeconds) async {
    await _api.post('/me/kicks', {'count': count, 'durationSeconds': durationSeconds});
  }

  @override
  Future<List<ContractionLog>> contractions() async {
    final data = await _api.get('/me/contractions') as List<dynamic>;
    return data
        .map((e) => ContractionLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveContraction(int durationSeconds, int? intervalSeconds) async {
    await _api.post('/me/contractions', {
      'durationSeconds': durationSeconds,
      if (intervalSeconds != null) 'intervalSeconds': intervalSeconds,
    });
  }

  @override
  Future<List<DailyLog>> dailyLogs() async {
    final data = await _api.get('/me/daily') as List<dynamic>;
    return data.map((e) => DailyLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveDaily(
      String date, String? mood, List<String> symptoms, String? note) async {
    await _api.post('/me/daily', {
      'date': date,
      'mood': mood,
      'symptoms': symptoms,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  @override
  Future<List<String>> checklistState(String key) async {
    final data = await _api.get('/me/checklist/${Uri.encodeComponent(key)}')
        as Map<String, dynamic>;
    return ((data['items'] as List<dynamic>?) ?? const [])
        .map((e) => e as String)
        .toList();
  }

  @override
  Future<void> saveChecklistState(String key, List<String> items) async {
    await _api.post('/me/checklist/${Uri.encodeComponent(key)}', {'items': items});
  }

  @override
  Future<List<ChatTurn>> chatHistory() async {
    final data = await _api.get('/me/chat') as List<dynamic>;
    return data.map((e) => ChatTurn.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveChatMessage(String role, String text) async {
    await _api.post('/me/chat', {'role': role, 'text': text});
  }

  @override
  Future<List<BabyEvent>> babyEvents() async {
    final data = await _api.get('/me/baby-events') as List<dynamic>;
    return data.map((e) => BabyEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveBabyEvent(String type, String? detail) async {
    await _api.post('/me/baby-events', {
      'type': type,
      if (detail != null) 'detail': detail,
    });
  }

  @override
  Future<void> setDueDate(String date) async {
    await _api.post('/me/pregnancy', {'dueDate': date});
  }

  @override
  Future<List<CyclePeriod>> cycles() async {
    final data = await _api.get('/me/cycles') as List<dynamic>;
    return data.map((e) => CyclePeriod.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveCycle(DateTime start, DateTime? end) async {
    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _api.post('/me/cycles', {
      'startDate': iso(start),
      if (end != null) 'endDate': iso(end),
    });
  }
}

/// Демо-реализация (без бэкенда).
class DemoEngagementService implements EngagementService {
  final int _streak = 3;
  final int _points = 1000;

  @override
  Future<MeProfile> me() async => MeProfile(
        name: 'Айман',
        city: 'Алматы, Қазақстан',
        points: _points,
        streak: _streak,
        children: 1,
      );

  @override
  Future<CheckinResult> checkin() async =>
      CheckinResult(streak: _streak, points: _points, awarded: false);

  @override
  Future<List<Reminder>> reminders() async => [
        Reminder(
          id: '1',
          title: 'Второй скрининг (УЗИ)',
          category: 'screening',
          isCritical: true,
          fireDate: DateTime.now().add(const Duration(days: 3)),
          profileType: 'PREGNANCY',
        ),
        Reminder(
          id: '2',
          title: 'Тест на глюкозу (ГТТ)',
          category: 'checkup',
          isCritical: false,
          fireDate: DateTime.now().add(const Duration(days: 12)),
          profileType: 'PREGNANCY',
        ),
      ];

  final List<WeightPoint> _weight = [
    const WeightPoint(week: 8, gainKg: 0.5),
    const WeightPoint(week: 16, gainKg: 2.5),
    const WeightPoint(week: 24, gainKg: 6.0),
    const WeightPoint(week: 30, gainKg: 9.0),
  ];

  @override
  Future<List<WeightPoint>> weight() async => List.of(_weight);

  @override
  Future<void> saveWeight(int week, double gainKg) async {
    _weight
      ..removeWhere((e) => e.week == week)
      ..add(WeightPoint(week: week, gainKg: gainKg))
      ..sort((a, b) => a.week.compareTo(b.week));
  }

  final List<KickSession> _kicks = [];

  @override
  Future<List<KickSession>> kicks() async => List.of(_kicks);

  @override
  Future<void> saveKick(int count, int durationSeconds) async {
    _kicks.insert(
      0,
      KickSession(
        count: count,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
      ),
    );
  }

  final List<ContractionLog> _contractions = [];

  @override
  Future<List<ContractionLog>> contractions() async => List.of(_contractions);

  @override
  Future<void> saveContraction(int durationSeconds, int? intervalSeconds) async {
    _contractions.insert(
      0,
      ContractionLog(
        durationSeconds: durationSeconds,
        intervalSeconds: intervalSeconds,
        createdAt: DateTime.now(),
      ),
    );
  }

  final Map<String, DailyLog> _daily = {};

  @override
  Future<List<DailyLog>> dailyLogs() async {
    final list = _daily.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> saveDaily(
      String date, String? mood, List<String> symptoms, String? note) async {
    _daily[date] = DailyLog(
      date: date,
      mood: mood,
      symptoms: symptoms,
      note: note,
    );
  }

  final Map<String, List<String>> _checklists = {};

  @override
  Future<List<String>> checklistState(String key) async =>
      List.of(_checklists[key] ?? const []);

  @override
  Future<void> saveChecklistState(String key, List<String> items) async {
    _checklists[key] = List.of(items);
  }

  final List<ChatTurn> _chat = [];

  @override
  Future<List<ChatTurn>> chatHistory() async => List.of(_chat);

  @override
  Future<void> saveChatMessage(String role, String text) async {
    _chat.add(ChatTurn(role: role, text: text));
  }

  final List<BabyEvent> _babyEvents = [];

  @override
  Future<List<BabyEvent>> babyEvents() async => List.of(_babyEvents);

  @override
  Future<void> saveBabyEvent(String type, String? detail) async {
    _babyEvents.insert(
      0,
      BabyEvent(type: type, detail: detail, happenedAt: DateTime.now()),
    );
  }

  @override
  Future<void> setDueDate(String date) async {
    // демо: срок не влияет на статичный InMemory-профиль
  }

  final List<CyclePeriod> _cycles = [
    CyclePeriod(
      start: DateTime.now().subtract(const Duration(days: 26)),
      end: DateTime.now().subtract(const Duration(days: 21)),
    ),
    CyclePeriod(
      start: DateTime.now().subtract(const Duration(days: 54)),
      end: DateTime.now().subtract(const Duration(days: 49)),
    ),
  ];

  @override
  Future<List<CyclePeriod>> cycles() async {
    final list = List.of(_cycles)..sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  @override
  Future<void> saveCycle(DateTime start, DateTime? end) async {
    _cycles
      ..removeWhere((c) =>
          c.start.year == start.year &&
          c.start.month == start.month &&
          c.start.day == start.day)
      ..insert(0, CyclePeriod(start: start, end: end));
  }
}
