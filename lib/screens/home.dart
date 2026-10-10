import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/ring.dart';
import 'focus.dart';
import 'settings.dart';

class HomeScreen extends StatelessWidget {
  final AppStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final p = store.profile!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(store: store)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Countdown(store: store),
          const SizedBox(height: 12),
          _TodayCard(store: store),
          _Section(title: 'Son 7 gün', child: _WeekBars(store: store)),
          _Section(
            title: 'Son 12 hafta',
            child: _Heatmap(store: store, goal: p.dailyGoal),
          ),
          _Section(title: 'Rozetler', child: _Achievements(store: store)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final AppStore store;
  const _Countdown({required this.store});

  @override
  Widget build(BuildContext context) {
    final p = store.profile!;
    final days = store.daysToExam;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final text = days < 0
        ? 'Sınav geçti'
        : days == 0
            ? 'Sınav bugün! 🍀'
            : '$days gün kaldı';
    return Card(
      color: scheme.primaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.exam} · ${formatDate(p.examDate)}',
                      style: t.labelLarge),
                  const SizedBox(height: 4),
                  Text(text, style: t.headlineMedium),
                ],
              ),
            ),
            const Text('🎯', style: TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final AppStore store;
  const _TodayCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final p = store.profile!;
    final today = store.todayMinutes;
    final streak = store.streak;
    final t = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Ring(
                  progress: today / p.dailyGoal,
                  size: 110,
                  stroke: 12,
                  color: color,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$today', style: t.headlineSmall),
                      Text('/ ${p.dailyGoal} dk', style: t.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔥 $streak gün seri', style: t.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        streak == 0
                            ? 'Bugün çalışıp serini başlat'
                            : today >= minStreakMinutes
                                ? 'Bugünün serisi güvende'
                                : 'Seriyi korumak için bugün en az $minStreakMinutes dk çalış',
                        style: t.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text('🧊 ${store.freezes} seri dondurma', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FocusScreen(store: store)),
                ),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Odak seansı başlat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  final AppStore store;
  const _WeekBars({required this.store});

  static const _letters = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

  @override
  Widget build(BuildContext context) {
    final goal = store.profile!.dailyGoal;
    final color = Theme.of(context).colorScheme.primary;
    final today = dayOnly(DateTime.now());
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i),
    ];
    final values = days.map(store.minutesOn).toList();
    final maxV = max(goal, values.reduce(max));
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    values[i] > 0 ? '${values[i]}' : '',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: max(4.0, 70.0 * values[i] / maxV),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: values[i] >= goal ? color : color.withAlpha(110),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _letters[days[i].weekday - 1],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final AppStore store;
  final int goal;
  const _Heatmap({required this.store, required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    const weeks = 12;
    const gap = 4.0;
    return LayoutBuilder(
      builder: (context, c) {
        final size = (c.maxWidth - gap * (weeks - 1)) / weeks;
        final today = dayOnly(DateTime.now());
        final start = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1) - (weeks - 1) * 7,
        );
        Widget cell(DateTime d) {
          Color? fill;
          if (!d.isAfter(today)) {
            final m = store.minutesOn(d);
            if (m > 0) {
              final ratio = min(1.0, m / goal);
              fill = color.withAlpha((70 + 185 * ratio).round());
            } else if (store.frozen.contains(dayKey(d))) {
              fill = Colors.lightBlue.withAlpha(120);
            } else {
              fill = color.withAlpha(25);
            }
          }
          return Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(bottom: gap),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }

        return Row(
          children: [
            for (var w = 0; w < weeks; w++)
              Padding(
                padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                child: Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      cell(DateTime(
                        start.year,
                        start.month,
                        start.day + w * 7 + d,
                      )),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Achievements extends StatelessWidget {
  final AppStore store;
  const _Achievements({required this.store});

  @override
  Widget build(BuildContext context) {
    final unlocked = store.unlocked();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in allAchievements)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${a.title}: ${a.desc}')),
              );
            },
            child: Opacity(
              opacity: unlocked.contains(a.id) ? 1 : 0.3,
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 4),
                    Text(
                      a.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
