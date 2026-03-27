import 'package:flutter/material.dart';
import 'package:mindfulness/features/breathing/presentation/breathing_screen.dart';
import 'package:mindfulness/features/focus_timer/presentation/timer_screen.dart';

/// Shell tab: Pomodoro timer + breathing patterns.
class FocusPracticeScreen extends StatelessWidget {
  const FocusPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus & breathe'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Timer', icon: Icon(Icons.timer_outlined)),
              Tab(text: 'Breathing', icon: Icon(Icons.air_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TimerScreen(embedded: true),
            BreathingScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
