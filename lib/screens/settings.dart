import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

class SettingsScreen extends StatelessWidget {
  final AppStore store;
  const SettingsScreen({super.key, required this.store});

  Future<void> _pickExam(BuildContext context) async {
    final p = store.profile!;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sınav'),
        children: [
          for (final e in examTypes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e),
              child: Text(e),
            ),
        ],
      ),
    );
    if (picked != null) await store.setProfile(p.copyWith(exam: picked));
  }

  Future<void> _pickDate(BuildContext context) async {
    final p = store.profile!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: p.examDate.isBefore(now) ? now : p.examDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) await store.setProfile(p.copyWith(examDate: picked));
  }

  Future<void> _pickGoal(BuildContext context) async {
    final p = store.profile!;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Günlük hedef'),
        children: [
          for (final g in goalOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g),
              child: Text('$g dakika'),
            ),
        ],
      ),
    );
    if (picked != null) await store.setProfile(p.copyWith(dailyGoal: picked));
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm veriler silinsin mi?'),
        content: const Text('Seri, rozetler ve çalışma geçmişin silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await store.reset();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final p = store.profile;
          if (p == null) return const SizedBox.shrink();
          return ListView(
            children: [
              ListTile(
                title: const Text('Sınav'),
                trailing: Text(p.exam),
                onTap: () => _pickExam(context),
              ),
              ListTile(
                title: const Text('Sınav tarihi'),
                trailing: Text(formatDate(p.examDate)),
                onTap: () => _pickDate(context),
              ),
              ListTile(
                title: const Text('Günlük hedef'),
                trailing: Text('${p.dailyGoal} dk'),
                onTap: () => _pickGoal(context),
              ),
              ListTile(
                title: const Text('Seri dondurma'),
                subtitle: const Text(
                  'Bir günü kaçırırsan otomatik kullanılır. '
                  'Her 7 günlük seride 1 tane kazanırsın (en fazla 2).',
                ),
                trailing: Text('🧊 ${store.freezes}'),
              ),
              const Divider(),
              ListTile(
                title: const Text(
                  'Tüm verileri sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmReset(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
