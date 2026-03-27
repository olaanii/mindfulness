import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mindfulness/core/notifications/notification_service.dart';
import 'package:mindfulness/core/routing/app_router.dart'
    show appRouterProvider, rootNavigatorKey;
import 'package:mindfulness/core/theme/app_theme.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';
import 'package:mindfulness/features/mood/providers/post_session_mood_provider.dart';
import 'package:mindfulness/firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web resolves assets under `assets/`; including the prefix twice 404s.
  await dotenv.load(
    fileName: kIsWeb ? 'env/firebase.env' : 'assets/env/firebase.env',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tzdata.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: MindfulnessApp()));
}

class MindfulnessApp extends ConsumerWidget {
  const MindfulnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pendingFocusSessionMoodProvider, (prev, next) {
      final id = next;
      if (id == null || id.isEmpty) return;
      ref.read(pendingFocusSessionMoodProvider.notifier).clear();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final navCtx = rootNavigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          showMoodCheckInSheet(navCtx, ref, sessionId: id);
        }
      });
    });
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Mindfulness',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
