import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

class OnboardingScreen extends StatefulWidget {
  final AppStore store;
  const OnboardingScreen({super.key, required this.store});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String? _exam;
  DateTime? _date;
  int _goal = 60;

  bool get _canNext => switch (_step) {
        0 => _exam != null,
        1 => _date != null,
        _ => true,
      };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 120)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      widget.store.setProfile(
        Profile(exam: _exam!, examDate: _date!, dailyGoal: _goal),
      );
    }
  }

  Widget _title(String text, [String? sub]) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.headlineMedium),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(sub, style: t.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Hangi sınava hazırlanıyorsun?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in examTypes)
                  ChoiceChip(
                    label: Text(e),
                    selected: _exam == e,
                    onSelected: (_) => setState(() => _exam = e),
                  ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Sınav ne zaman?', 'Geri sayımı ana ekranda göreceksin.'),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(_date == null ? 'Tarih seç' : formatDate(_date!)),
            ),
            if (_date != null) ...[
              const SizedBox(height: 16),
              Text(
                '${daysBetween(DateTime.now(), _date!)} gün kaldı',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(
              'Günlük hedefin ne kadar?',
              'Her gün yapabileceğin bir süre seç. Küçük başlamak, bırakmamaktan iyidir.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in goalOptions)
                  ChoiceChip(
                    label: Text('$g dk'),
                    selected: _goal == g,
                    onSelected: (_) => setState(() => _goal = g),
                  ),
              ],
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Hazırsın! 🎯'),
            Text('Sınav: $_exam · ${formatDate(_date!)}'),
            const SizedBox(height: 8),
            Text('Günlük hedef: $_goal dakika'),
            const SizedBox(height: 16),
            const Text(
              'İlk odak seansını başlatıp serini bugün başlat. '
              'Bir günü kaçırırsan seri dondurma seni korur.',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LinearProgressIndicator(value: (_step + 1) / 4),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _stepContent(),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Geri'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canNext ? _next : null,
                    child: Text(_step == 3 ? 'Başla' : 'Devam'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
