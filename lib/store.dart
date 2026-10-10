import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  late SharedPreferences _prefs;

  Profile? profile;

  /// gün -> o gün odaklanılan toplam dakika
  final Map<String, int> minutes = {};

  /// seri dondurma ile korunmuş günler
  final Set<String> frozen = {};

  int freezes = 1;
  int bestStreak = 0;
  int lastFreezeAward = 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs.getString('profile');
    if (p != null) {
      profile = Profile.fromJson(jsonDecode(p) as Map<String, dynamic>);
    }
    final m = _prefs.getString('minutes');
    if (m != null) {
      (jsonDecode(m) as Map<String, dynamic>)
          .forEach((k, v) => minutes[k] = v as int);
    }
    frozen.addAll(_prefs.getStringList('frozen') ?? const []);
    freezes = _prefs.getInt('freezes') ?? 1;
    bestStreak = _prefs.getInt('best') ?? 0;
    lastFreezeAward = _prefs.getInt('award') ?? 0;
    if (profile != null) {
      _applyFreeze();
      await _save();
    }
  }

  Future<void> _save() async {
    if (profile != null) {
      await _prefs.setString('profile', jsonEncode(profile!.toJson()));
    }
    await _prefs.setString('minutes', jsonEncode(minutes));
    await _prefs.setStringList('frozen', frozen.toList());
    await _prefs.setInt('freezes', freezes);
    await _prefs.setInt('best', bestStreak);
    await _prefs.setInt('award', lastFreezeAward);
  }

  int minutesOn(DateTime d) => minutes[dayKey(d)] ?? 0;

  int get todayMinutes => minutesOn(DateTime.now());

  bool covered(DateTime d) =>
      minutesOn(d) >= minStreakMinutes || frozen.contains(dayKey(d));

  /// Dün kaçırıldıysa ve ondan önceki gün seri sürüyorsa, bir dondurma harcanır.
  void _applyFreeze() {
    final today = dayOnly(DateTime.now());
    final y = previousDay(today);
    final y2 = previousDay(y);
    if (!covered(y) && covered(y2) && freezes > 0) {
      frozen.add(dayKey(y));
      freezes--;
    }
  }

  int get streak {
    var day = dayOnly(DateTime.now());
    if (!covered(day)) day = previousDay(day);
    var n = 0;
    while (covered(day)) {
      n++;
      day = previousDay(day);
    }
    return n;
  }

  int get totalMinutes => minutes.values.fold(0, (a, b) => a + b);

  int get goalDays {
    final goal = profile?.dailyGoal;
    if (goal == null) return 0;
    return minutes.values.where((m) => m >= goal).length;
  }

  int get daysToExam =>
      daysBetween(DateTime.now(), profile!.examDate);

  Set<String> unlocked() {
    final best = max(bestStreak, streak);
    final total = totalMinutes;
    return {
      if (total > 0) 'first',
      if (best >= 3) 's3',
      if (best >= 7) 's7',
      if (best >= 14) 's14',
      if (best >= 30) 's30',
      if (total >= 600) 'h10',
      if (total >= 3000) 'h50',
      if (total >= 6000) 'h100',
      if (goalDays >= 5) 'g5',
    };
  }

  Future<void> setProfile(Profile p) async {
    profile = p;
    await _save();
    notifyListeners();
  }

  /// Seansı kaydeder, yeni açılan rozetleri döndürür.
  Future<List<Achievement>> completeSession(int mins) async {
    final before = unlocked();
    final key = dayKey(DateTime.now());
    minutes[key] = (minutes[key] ?? 0) + mins;
    final s = streak;
    if (s > bestStreak) bestStreak = s;
    if (s > 0 && s % 7 == 0 && lastFreezeAward != s) {
      freezes = min(2, freezes + 1);
      lastFreezeAward = s;
    }
    final after = unlocked();
    await _save();
    notifyListeners();
    return allAchievements
        .where((a) => after.contains(a.id) && !before.contains(a.id))
        .toList();
  }

  Future<void> reset() async {
    await _prefs.clear();
    profile = null;
    minutes.clear();
    frozen.clear();
    freezes = 1;
    bestStreak = 0;
    lastFreezeAward = 0;
    notifyListeners();
  }
}
