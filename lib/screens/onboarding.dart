import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

class OnboardingScreen extends StatelessWidget {
  final AppStore store;
  const OnboardingScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Neye odaklanmak istersin?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Sonradan istediğin zaman değiştirebilirsin.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              for (final t in Track.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrackCard(track: t, onTap: () => store.selectTrack(t)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  const _TrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: track.color.withAlpha(30),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(track.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(track.subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
