import 'package:flutter/material.dart';

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

/// daily: her gün işaretlenen alışkanlık, quit: bırakma sayacı
enum HabitKind { daily, quit }

enum Track { study, quit, fitness }

class HabitTemplate {
  final String name;
  final String emoji;
  final HabitKind kind;
  const HabitTemplate(this.name, this.emoji, this.kind);
}

extension TrackInfo on Track {
  String get title => switch (this) {
        Track.study => 'Sınav Çalışması',
        Track.quit => 'Bırakma Sayacı',
        Track.fitness => 'Spor ve Sağlık',
      };

  String get subtitle => switch (this) {
        Track.study => 'YKS, KPSS ve diğer sınavlar için günlük çalışma serisi',
        Track.quit => 'Sigara, şeker gibi bırakmak istediklerin için sayaç',
        Track.fitness => 'Su, adım, antrenman gibi sağlıklı rutinler',
      };

  String get emoji => switch (this) {
        Track.study => '📚',
        Track.quit => '🚭',
        Track.fitness => '💪',
      };

  Color get color => switch (this) {
        Track.study => const Color(0xFF3F51B5),
        Track.quit => const Color(0xFFE53935),
        Track.fitness => const Color(0xFF2E7D32),
      };

  List<HabitTemplate> get templates => switch (this) {
        Track.study => const [
            HabitTemplate('Soru çöz', '✏️', HabitKind.daily),
            HabitTemplate('Konu tekrarı yap', '📖', HabitKind.daily),
            HabitTemplate('Deneme sınavı çöz', '📝', HabitKind.daily),
            HabitTemplate('Yanlışlarını gözden geçir', '🔍', HabitKind.daily),
          ],
        Track.quit => const [
            HabitTemplate('Sigara', '🚬', HabitKind.quit),
            HabitTemplate('Şeker', '🍬', HabitKind.quit),
            HabitTemplate('Sosyal medya', '📱', HabitKind.quit),
            HabitTemplate('Kafein', '☕', HabitKind.quit),
          ],
        Track.fitness => const [
            HabitTemplate('2 litre su iç', '💧', HabitKind.daily),
            HabitTemplate('30 dk yürüyüş', '🚶', HabitKind.daily),
            HabitTemplate('Antrenman yap', '🏋️', HabitKind.daily),
            HabitTemplate('Erken uyu', '😴', HabitKind.daily),
          ],
      };
}

class Habit {
  final String id;
  final String name;
  final String emoji;
  final Track track;
  final HabitKind kind;
  final DateTime createdAt;

  /// daily alışkanlıklar için tamamlanan günler (yyyy-MM-dd)
  final Set<String> done;

  /// Seri dondurma tarihleri (yyyy-MM-dd)
  final Set<String> frozenDates;

  /// Geri kazanma (recovery) görevi tamamlandı mı (Tarih key'leri)
  final Set<String> recoveredDates;

  /// quit alışkanlıkları için bırakma başlangıcı ve en iyi süre
  DateTime? quitStart;
  int bestQuitDays;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.track,
    required this.kind,
    required this.createdAt,
    Set<String>? done,
    Set<String>? frozenDates,
    Set<String>? recoveredDates,
    this.quitStart,
    this.bestQuitDays = 0,
  })  : done = done ?? <String>{},
        frozenDates = frozenDates ?? <String>{},
        recoveredDates = recoveredDates ?? <String>{};

  bool get doneToday => done.contains(dayKey(DateTime.now()));

  bool isDoneOn(DateTime d) => done.contains(dayKey(d));
  bool isFrozenOn(DateTime d) => frozenDates.contains(dayKey(d));
  bool isRecoveredOn(DateTime d) => recoveredDates.contains(dayKey(d));

  bool isCompletedOrSavedOn(DateTime d) {
    final k = dayKey(d);
    return done.contains(k) || frozenDates.contains(k) || recoveredDates.contains(k);
  }

  int get streak {
    var day = DateTime.now();
    // Eğer bugün henüz yapılmadıysa ve dondurulmadıysa dünden başla
    if (!isCompletedOrSavedOn(day)) {
      day = previousDay(day);
    }
    var n = 0;
    while (isCompletedOrSavedOn(day)) {
      n++;
      day = previousDay(day);
    }
    return n;
  }

  int get daysClean {
    final start = quitStart;
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'track': track.name,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'done': done.toList(),
        'frozenDates': frozenDates.toList(),
        'recoveredDates': recoveredDates.toList(),
        'quitStart': quitStart?.toIso8601String(),
        'bestQuitDays': bestQuitDays,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        track: Track.values.byName(j['track'] as String),
        kind: HabitKind.values.byName(j['kind'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        done: Set<String>.from(j['done'] as List? ?? []),
        frozenDates: Set<String>.from(j['frozenDates'] as List? ?? []),
        recoveredDates: Set<String>.from(j['recoveredDates'] as List? ?? []),
        quitStart: j['quitStart'] == null
            ? null
            : DateTime.parse(j['quitStart'] as String),
        bestQuitDays: (j['bestQuitDays'] as int?) ?? 0,
      );
}
