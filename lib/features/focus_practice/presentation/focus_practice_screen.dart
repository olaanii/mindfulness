import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/breathing/presentation/breathing_screen.dart';
import 'package:mindfulness/features/focus_timer/presentation/timer_screen.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

/// Shell tab: Pomodoro timer + breathing patterns.
class FocusPracticeScreen extends ConsumerWidget {
  const FocusPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authServiceProvider).currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: MindfulBackground(
          bottomPadding: 124,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopBlurBar(
                  title: 'Mindfulness',
                  trailing: UserAvatarBadge(
                    email: user?.email,
                    onTap: () => context.push('/account'),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primaryYellow.withValues(alpha: 0.35),
                      ),
                    ),
                    labelStyle: Theme.of(context).textTheme.labelMedium,
                    tabs: const [
                      Tab(text: 'Timer'),
                      Tab(text: 'Breathing'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Expanded(
                  child: TabBarView(
                    children: [
                      TimerScreen(embedded: true),
                      BreathingScreen(embedded: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
