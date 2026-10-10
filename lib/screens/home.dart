import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final track = store.track!;
    final habits = store.currentHabits;

    return Scaffold(
      appBar: AppBar(
        title: Text('${track.emoji} ${track.title}'),
        actions: [
          PopupMenuButton<Track>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Alan değiştir',
            onSelected: store.selectTrack,
            itemBuilder: (_) => [
              for (final t in Track.values)
                PopupMenuItem(value: t, child: Text('${t.emoji} ${t.title}')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar & Bildirimler',
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Sınav Alanı için Geri Sayım Kartı
          if (track == Track.study) _ExamCountdownCard(store: store),

          // Seri Durum Kartı (Freeze Bilgisi Dahil)
          if (track != Track.quit) _StreakCard(store: store),
          const SizedBox(height: 8),

          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Henüz bir şey eklemedin.\nBaşlamak için "Ekle" butonuna dokun.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          for (final h in habits)
            h.kind == HabitKind.quit
                ? _QuitCard(habit: h, store: store)
                : _DailyTile(habit: h, store: store),
        ],
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSheet(store: store),
    );
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SettingsDialog(store: store),
    );
  }
}

class _ExamCountdownCard extends StatelessWidget {
  final AppStore store;
  const _ExamCountdownCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final days = store.daysUntilExam;
    return Card(
      color: Colors.indigo.shade50,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.examName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    days != null && days >= 0
                        ? 'Sınava $days gün kaldı!'
                        : 'Sınav günü tamamlandı veya girilmedi.',
                    style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editExam(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editExam(BuildContext context) {
    final nameCtrl = TextEditingController(text: store.examName);
    DateTime selectedDate = store.examDate ?? DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sınav Bilgisini Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Sınav Adı (örn: YKS 2026)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('Tarih Seç: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 1000)),
                );
                if (d != null) selectedDate = d;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              store.setExamDetails(nameCtrl.text.trim(), selectedDate);
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final AppStore store;
  const _StreakCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final days = store.trackStreak;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$days gün', style: Theme.of(context).textTheme.headlineSmall),
                  Text(days == 0
                      ? 'Bugün bir alışkanlığı tamamla, seriyi başlat'
                      : 'Seri devam ediyor, bozma!'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.ac_unit, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Kalan dondurma hakkın: ${store.streakFreezesLeft}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  final Habit habit;
  final AppStore store;
  const _DailyTile({required this.habit, required this.store});

  @override
  Widget build(BuildContext context) {
    final done = habit.doneToday;
    final isFrozen = habit.isFrozenOn(DateTime.now());

    return Card(
      child: ListTile(
        leading: Text(habit.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text('🔥 ${habit.streak} gün seri'),
            if (isFrozen)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('❄️ Donduruldu', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.indigo),
              tooltip: 'Takvim Görünümü',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarScreen(habit: habit, store: store),
                  ),
                );
              },
            ),
            Checkbox(
              value: done,
              shape: const CircleBorder(),
              onChanged: (_) => store.toggleToday(habit),
            ),
          ],
        ),
        onTap: () => store.toggleToday(habit),
        onLongPress: () => _showHabitOptions(context, store, habit),
      ),
    );
  }

  void _showHabitOptions(BuildContext context, AppStore store, Habit habit) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ac_unit, color: Colors.blue),
            title: const Text('Bugün İçin Seriyi Dondur (Streak Freeze)'),
            subtitle: Text('Kalan dondurma hakkınız: ${store.streakFreezesLeft}'),
            onTap: () async {
              Navigator.pop(ctx);
              final success = await store.freezeStreakForToday(habit);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Bugün için seri donduruldu! ❄️'
                      : 'Dondurma hakkınız kalmadı!'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Alışkanlığı Sil'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, store, habit);
            },
          ),
        ],
      ),
    );
  }
}

class _QuitCard extends StatelessWidget {
  final Habit habit;
  final AppStore store;
  const _QuitCard({required this.habit, required this.store});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onLongPress: () => _confirmDelete(context, store, habit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                    Text('${habit.daysClean} gün', style: Theme.of(context).textTheme.headlineSmall),
                    Text('En iyi: ${store.bestQuit(habit)} gün'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _confirmRelapse(context),
                child: const Text('Nüksettim'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRelapse(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayaç sıfırlansın mı?'),
        content: const Text('Sorun değil, herkes düşebilir. En iyi süren kayıtlı kalır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              store.relapse(habit);
              Navigator.pop(ctx);
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(BuildContext context, AppStore store, Habit habit) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('"${habit.name}" silinsin mi?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            store.remove(habit);
            Navigator.pop(ctx);
          },
          child: const Text('Sil'),
        ),
      ],
    ),
  );
}

class _SettingsDialog extends StatelessWidget {
  final AppStore store;
  const _SettingsDialog({required this.store});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ayarlar & Hatırlatıcı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.orange),
            title: const Text('Günlük Hatırlatma'),
            subtitle: Text('Saat: ${store.reminderHour.toString().padLeft(2, '0')}:${store.reminderMinute.toString().padLeft(2, '0')}'),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
              );
              if (t != null) {
                store.setReminderTime(t.hour, t.minute);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(store.isPremium ? Icons.star : Icons.star_border, color: Colors.amber),
            title: Text(store.isPremium ? 'Premium Üye (Aktif)' : 'Premium\'a Geç / Reklam İzle'),
            subtitle: Text(store.isPremium ? 'Sınırsız seri dondurma aktif' : 'Ödüllü reklam izleyerek seri dondurma kazan'),
            onTap: () {
              store.setPremium(!store.isPremium);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
      ],
    );
  }
}

class _AddSheet extends StatefulWidget {
  final AppStore store;
  const _AddSheet({required this.store});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add(String name, String emoji, HabitKind kind) async {
    await widget.store.addHabit(name, emoji, kind);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.store.track!;
    final customKind = track == Track.quit ? HabitKind.quit : HabitKind.daily;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hazır öneriler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final t in track.templates)
              ListTile(
                leading: Text(t.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(t.name),
                onTap: () => _add(t.name, t.emoji, t.kind),
              ),
            const Divider(),
            Text('Kendi alışkanlığın', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Örn: Kitap oku',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final name = _controller.text.trim();
                    if (name.isEmpty) return;
                    _add(name, '⭐', customKind);
                  },
                  child: const Text('Ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
