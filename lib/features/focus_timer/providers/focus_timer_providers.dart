import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/focus_timer/application/focus_timer_notifier.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_models.dart';

export 'package:mindfulness/features/focus_timer/data/session_repository.dart'
    show sessionRepositoryProvider;

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerViewState>(
      FocusTimerNotifier.new,
    );
