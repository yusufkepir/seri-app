String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// a gününden b gününe kalan gün sayısı (yaz saati kaymasından etkilenmez)
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

String mmss(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

const examTypes = ['YKS', 'LGS', 'KPSS', 'ALES', 'DGS', 'Diğer'];
const goalOptions = [30, 60, 90, 120, 180];
const focusOptions = [15, 25, 45, 60];

/// Bir günün seriye sayılması için gereken en az çalışma süresi (dakika)
const minStreakMinutes = 10;

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String desc;
  const Achievement(this.id, this.emoji, this.title, this.desc);
}

const allAchievements = [
  Achievement('first', '🌱', 'İlk Adım', 'İlk odak seansını tamamla'),
  Achievement('s3', '🔥', '3 Gün Seri', '3 gün üst üste çalış'),
  Achievement('s7', '⚡', '7 Gün Seri', '7 gün üst üste çalış'),
  Achievement('s14', '🚀', '14 Gün Seri', '14 gün üst üste çalış'),
  Achievement('s30', '👑', '30 Gün Seri', '30 gün üst üste çalış'),
  Achievement('h10', '⏱️', '10 Saat', 'Toplam 10 saat odaklan'),
  Achievement('h50', '📚', '50 Saat', 'Toplam 50 saat odaklan'),
  Achievement('h100', '🏆', '100 Saat', 'Toplam 100 saat odaklan'),
  Achievement('g5', '🎯', 'Hedef Avcısı', 'Günlük hedefi 5 kez tamamla'),
];

class Profile {
  final String exam;
  final DateTime examDate;
  final int dailyGoal;

  const Profile({
    required this.exam,
    required this.examDate,
    required this.dailyGoal,
  });

  Profile copyWith({String? exam, DateTime? examDate, int? dailyGoal}) =>
      Profile(
        exam: exam ?? this.exam,
        examDate: examDate ?? this.examDate,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );

  Map<String, dynamic> toJson() => {
        'exam': exam,
        'examDate': examDate.toIso8601String(),
        'dailyGoal': dailyGoal,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        exam: j['exam'] as String,
        examDate: DateTime.parse(j['examDate'] as String),
        dailyGoal: j['dailyGoal'] as int,
      );
}
