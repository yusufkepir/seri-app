import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/confetti.dart';
import '../widgets/ring.dart';

class FocusScreen extends StatefulWidget {
  final AppStore store;
  const FocusScreen({super.key, required this.store});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _minutes = 25;
  bool _running = false;
  bool _paused = false;
  DateTime? _endAt;
  int _remaining = 25 * 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _paused = false;
      _remaining = _minutes * 60;
      _endAt = DateTime.now().add(Duration(seconds: _remaining));
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_paused || _endAt == null || !_running) return;
    final ms = _endAt!.difference(DateTime.now()).inMilliseconds;
    final left = (ms / 1000).ceil();
    if (left <= 0) {
      _finish();
    } else {
      setState(() => _remaining = left);
    }
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _endAt = DateTime.now().add(Duration(seconds: _remaining));
      }
      _paused = !_paused;
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = 0;
    });
    HapticFeedback.heavyImpact();
    final newly = await widget.store.completeSession(_minutes);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CelebrationScreen(
          store: widget.store,
          minutes: _minutes,
          achievements: newly,
        ),
      ),
    );
  }

  void _giveUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seansı bırakmak istiyor musun?'),
        content: const Text('Bu seans kaydedilmeyecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Devam et'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _timer?.cancel();
              setState(() {
                _running = false;
                _paused = false;
                _remaining = _minutes * 60;
              });
            },
            child: const Text('Bırak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final total = _minutes * 60;
    final progress = _running ? 1 - _remaining / total : 0.0;
    final shown = _running ? _remaining : total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odak seansı'),
        automaticallyImplyLeading: !_running,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Ring(
                  progress: progress,
                  size: 260,
                  stroke: 14,
                  color: color,
                  child: Text(
                    mmss(shown),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_running) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final m in focusOptions)
                        ChoiceChip(
                          label: Text('$m dk'),
                          selected: _minutes == m,
                          onSelected: (_) => setState(() {
                            _minutes = m;
                            _remaining = m * 60;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Başla'),
                  ),
                ] else ...[
                  Text(
                    _paused
                        ? 'Duraklatıldı'
                        : 'Telefonu bırak, sadece bu seansa odaklan.',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                        label: Text(_paused ? 'Devam' : 'Duraklat'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(onPressed: _giveUp, child: const Text('Bırak')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CelebrationScreen extends StatelessWidget {
  final AppStore store;
  final int minutes;
  final List<Achievement> achievements;

  const CelebrationScreen({
    super.key,
    required this.store,
    required this.minutes,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final goal = store.profile!.dailyGoal;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    Text('+$minutes dakika', style: t.headlineLarge),
                    const SizedBox(height: 8),
                    const Text('Harika odaklandın!'),
                    const SizedBox(height: 24),
                    Text('🔥 ${store.streak} günlük seri', style: t.titleLarge),
                    const SizedBox(height: 8),
                    Text('Bugün: ${store.todayMinutes} / $goal dk'),
                    if (achievements.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Yeni rozet!', style: t.titleMedium),
                      const SizedBox(height: 8),
                      for (final a in achievements)
                        Text('${a.emoji} ${a.title}', style: t.titleLarge),
                    ],
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Devam'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}
