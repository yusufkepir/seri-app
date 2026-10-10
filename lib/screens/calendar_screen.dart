import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';

class CalendarScreen extends StatefulWidget {
  final Habit habit;
  final AppStore store;
  const CalendarScreen({super.key, required this.habit, required this.store});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji} ${habit.name} - Takvim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ay seçici
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  '${_focusedMonth.year} - ${_focusedMonth.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Gün isimleri
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Pzt', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Sal', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Çar', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Per', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Cum', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Cmt', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Paz', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            // Izgara Takvim Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: daysInMonth + firstDayOffset,
              itemBuilder: (context, index) {
                if (index < firstDayOffset) {
                  return const SizedBox();
                }
                final dayNum = index - firstDayOffset + 1;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                final isDone = habit.isDoneOn(date);
                final isFrozen = habit.isFrozenOn(date);
                final isRecovered = habit.isRecoveredOn(date);
                final isToday = dayKey(date) == dayKey(now);

                Color bgColor = Colors.grey.shade200;
                Widget child = Text('$dayNum', style: const TextStyle(fontSize: 12));

                if (isDone) {
                  bgColor = Colors.green.shade400;
                  child = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      const Icon(Icons.check, size: 12, color: Colors.white),
                    ],
                  );
                } else if (isFrozen) {
                  bgColor = Colors.blue.shade300;
                  child = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      const Text('❄️', style: TextStyle(fontSize: 10)),
                    ],
                  );
                } else if (isRecovered) {
                  bgColor = Colors.orange.shade300;
                  child = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      const Text('🛡️', style: TextStyle(fontSize: 10)),
                    ],
                  );
                }

                return InkWell(
                  onTap: () {
                    if (date.isBefore(now) || isToday) {
                      widget.store.toggleDay(habit, date);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? Border.all(color: Colors.indigo, width: 2) : null,
                    ),
                    child: Center(child: child),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Lejant / Açıklamalar
            Wrap(
              spacing: 12,
              children: [
                _buildLegend(Colors.green.shade400, 'Tamamlandı'),
                _buildLegend(Colors.blue.shade300, '❄️ Donduruldu'),
                _buildLegend(Colors.orange.shade300, '🛡️ Kurtarıldı'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
