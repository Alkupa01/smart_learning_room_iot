// lib/providers/pomodoro_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
// (use flutter_riverpod export for StateNotifier/StateNotifierProvider)

enum PomodoroState { idle, running, paused, shortBreak, finished }

class PomodoroData {
  final PomodoroState state;
  final int secondsLeft;     // detik tersisa
  final int currentSession;  // sesi ke-berapa (1–4)
  final int totalSessions;   // target total sesi
  final bool isBreak;        // sedang break atau fokus
  final List<double> sessionScores; // comfort score tiap sesi

  const PomodoroData({
    this.state          = PomodoroState.idle,
    this.secondsLeft    = 25 * 60,
    this.currentSession = 1,
    this.totalSessions  = 4,
    this.isBreak        = false,
    this.sessionScores  = const [],
  });

  double get progress {
    final total = isBreak ? 5 * 60 : 25 * 60;
    return 1.0 - (secondsLeft / total);
  }

  String get timeLabel {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PomodoroData copyWith({
    PomodoroState? state,
    int? secondsLeft,
    int? currentSession,
    int? totalSessions,
    bool? isBreak,
    List<double>? sessionScores,
  }) {
    return PomodoroData(
      state:          state          ?? this.state,
      secondsLeft:    secondsLeft    ?? this.secondsLeft,
      currentSession: currentSession ?? this.currentSession,
      totalSessions:  totalSessions  ?? this.totalSessions,
      isBreak:        isBreak        ?? this.isBreak,
      sessionScores:  sessionScores  ?? this.sessionScores,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroData> {
  Timer? _timer;

  PomodoroNotifier() : super(const PomodoroData());

  void start() {
    if (state.state == PomodoroState.running) return;
    state = state.copyWith(state: PomodoroState.running);
    _tick();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(state: PomodoroState.paused);
  }

  void resume() {
    state = state.copyWith(state: PomodoroState.running);
    _tick();
  }

  void startBreak() {
    _timer?.cancel();
    state = state.copyWith(
      state:       PomodoroState.shortBreak,
      isBreak:     true,
      secondsLeft: 5 * 60,
    );
    _tick();
  }

  void skipBreak() {
    _timer?.cancel();
    _nextSession();
  }

  void stop() {
    _timer?.cancel();
    state = const PomodoroData();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsLeft <= 0) {
        _timer?.cancel();
        if (state.isBreak) {
          _nextSession();
        } else {
          // Fokus selesai → mulai break otomatis
          state = state.copyWith(
            state:       PomodoroState.shortBreak,
            isBreak:     true,
            secondsLeft: 5 * 60,
          );
          _tick();
        }
        return;
      }
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    });
  }

  void _nextSession() {
    if (state.currentSession >= state.totalSessions) {
      state = state.copyWith(state: PomodoroState.finished);
      return;
    }
    state = state.copyWith(
      state:          PomodoroState.running,
      isBreak:        false,
      secondsLeft:    25 * 60,
      currentSession: state.currentSession + 1,
    );
    _tick();
  }

  void addSessionScore(double score) {
    state = state.copyWith(
      sessionScores: [...state.sessionScores, score],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroData>(
  (ref) => PomodoroNotifier(),
);