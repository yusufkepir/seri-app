import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  static const _kTrack = 'track';
  static const _kHabits = 'habits';
  static const _kExamDate = 'exam_date';
  static const _kExamName = 'exam_name';
  static const _kFreezeCount = 'freeze_count';
  static const _kDailyReminderHour = 'reminder_hour';
  static const _kDailyReminderMinute = 'reminder_minute';
  static const _kIsPremium = 'is_premium';

  late SharedPreferences _prefs;
  Track? track;
  final List<Habit> _habits = [];

  DateTime? examDate;
  String examName = 'YKS 2026';
  int streakFreezesLeft = 2; // Kullanıcıya verilen hak
  int reminderHour = 20; // Varsayılan saat 20:00
  int reminderMinute = 0;
  bool isPremium = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs.getString(_kTrack);
    if (t != null) {
      track = Track.values.where((e) => e.name == t).firstOrNull;
    }
    final raw = _prefs.getString(_kHabits);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _habits
        ..clear()
        ..addAll(list.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
    }

    final eDateStr = _prefs.getString(_kExamDate);
    if (eDateStr != null) {
      examDate = DateTime.tryParse(eDateStr);
    } else {
      // Varsayılan Sınav Tarihi (Örn: 2026 YKS yaklaşık tarihi)
      examDate = DateTime(2026, 6, 20);
    }

    examName = _prefs.getString(_kExamName) ?? 'YKS 2026';
    streakFreezesLeft = _prefs.getInt(_kFreezeCount) ?? 2;
    reminderHour = _prefs.getInt(_kDailyReminderHour) ?? 20;
    reminderMinute = _prefs.getInt(_kDailyReminderMinute) ?? 0;
    isPremium = _prefs.getBool(_kIsPremium) ?? false;
  }

  List<Habit> get currentHabits =>
      _habits.where((h) => h.track == track).toList();

  /// Seçili alandaki günlük alışkanlıklardan en az biri yapılan veya dondurulan ardışık gün sayısı
  int get trackStreak {
    final daily =
        currentHabits.where((h) => h.kind == HabitKind.daily).toList();
    if (daily.isEmpty) return 0;

    bool anySaved(DateTime d) => daily.any((h) => h.isCompletedOrSavedOn(d));
    var day = DateTime.now();
    if (!anySaved(day)) day = previousDay(day);
    var n = 0;
    while (anySaved(day)) {
      n++;
      day = previousDay(day);
    }
    return n;
  }

  int bestQuit(Habit h) => max(h.bestQuitDays, h.daysClean);

  /// Sınava kalan gün sayısı
  int? get daysUntilExam {
    if (examDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
    return target.difference(today).inDays;
  }

  Future<void> _save() async {
    await _prefs.setString(
        _kHabits, jsonEncode(_habits.map((h) => h.toJson()).toList()));
    if (track != null) await _prefs.setString(_kTrack, track!.name);
    if (examDate != null) await _prefs.setString(_kExamDate, examDate!.toIso8601String());
    await _prefs.setString(_kExamName, examName);
    await _prefs.setInt(_kFreezeCount, streakFreezesLeft);
    await _prefs.setInt(_kDailyReminderHour, reminderHour);
    await _prefs.setInt(_kDailyReminderMinute, reminderMinute);
    await _prefs.setBool(_kIsPremium, isPremium);
  }

  Future<void> selectTrack(Track t) async {
    track = t;
    await _save();
    notifyListeners();
  }

  Future<void> addHabit(String name, String emoji, HabitKind kind) async {
    final now = DateTime.now();
    _habits.add(Habit(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      track: track!,
      kind: kind,
      createdAt: now,
      quitStart: kind == HabitKind.quit ? now : null,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> toggleToday(Habit h) async {
    final key = dayKey(DateTime.now());
    if (!h.done.remove(key)) h.done.add(key);
    await _save();
    notifyListeners();
  }

  /// Belirli bir günün durumunu değiştir (Takvim ekranı için)
  Future<void> toggleDay(Habit h, DateTime date) async {
    final key = dayKey(date);
    if (h.done.contains(key)) {
      h.done.remove(key);
    } else {
      h.done.add(key);
    }
    await _save();
    notifyListeners();
  }

  /// Seri Dondurma Haklarını Kullanma (Streak Freeze)
  Future<bool> freezeStreakForToday(Habit h) async {
    if (streakFreezesLeft <= 0) return false;
    final key = dayKey(DateTime.now());
    h.frozenDates.add(key);
    streakFreezesLeft--;
    await _save();
    notifyListeners();
    return true;
  }

  /// Kaçırılan günü geri kazanma görevi (Streak Recovery Task)
  Future<void> recoverMissedDay(Habit h, DateTime date) async {
    final key = dayKey(date);
    h.recoveredDates.add(key);
    await _save();
    notifyListeners();
  }

  /// Sınav Bilgisi Güncelleme
  Future<void> setExamDetails(String name, DateTime date) async {
    examName = name;
    examDate = date;
    await _save();
    notifyListeners();
  }

  /// Hatırlatma Saatini Güncelleme
  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
    await _save();
    notifyListeners();
  }

  /// Premium durumunu aktifleştirme (Abonelik / Ödüllü Reklam sonrası)
  Future<void> setPremium(bool active) async {
    isPremium = active;
    await _save();
    notifyListeners();
  }

  Future<void> relapse(Habit h) async {
    h.bestQuitDays = max(h.bestQuitDays, h.daysClean);
    h.quitStart = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> remove(Habit h) async {
    _habits.removeWhere((x) => x.id == h.id);
    await _save();
    notifyListeners();
  }
}
