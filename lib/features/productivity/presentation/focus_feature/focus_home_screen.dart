import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/productivity_scope.dart';

import 'widget/focus_complete_dialog.dart';
import 'widget/focus_home_view.dart';
import 'widget/focus_leave_dialog.dart';
import 'widget/focus_paused_view.dart';
import 'widget/focus_running_view.dart';
import 'widget/focus_session_summary_dialog.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  ProductivityController? _controller;
  Timer? _ticker;
  int selectedDuration = 25;
  bool _loading = true;
  bool _autoCompleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ensureProductivityController();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreActiveSession());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTicker();
    }
  }

  Future<void> _bootstrap() async {
    final controller = _controller;
    if (controller == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final active = await controller.loadActiveFocusSession();
      await controller.loadFocusHistory();
      _syncTicker();
      if (active?.isCompleted == true && mounted) {
        await _showCompletion(active!);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreActiveSession() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final active = await controller.loadActiveFocusSession();
      _syncTicker();
      if (mounted) setState(() {});
      if (active?.isCompleted == true && mounted) {
        await _showCompletion(active!);
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _syncTicker() {
    final session = _controller?.activeFocusSession.value;
    if (session == null || !session.isActive) {
      _stopTicker();
      return;
    }
    _startTicker();
  }

  void _startTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _controller?.activeFocusSession.value;
      if (!mounted || session == null) {
        _stopTicker();
        return;
      }
      if (!session.isActive) {
        _stopTicker();
        setState(() {});
        return;
      }
      if (_remainingSeconds(session) <= 0) {
        unawaited(_completeExpiredSession(session));
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _startSession() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final mode = selectedDuration >= 50 ? 'DEEP_FOCUS' : 'POMODORO';
      final session = await controller.startFocusSession(
        mode: mode,
        durationMinutes: selectedDuration,
      );
      if (!mounted) return;
      if (session.isCompleted) {
        await _showCompletion(session);
      } else {
        _syncTicker();
        setState(() {});
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _pauseSession() async {
    final session = _controller?.activeFocusSession.value;
    if (session == null) return;
    try {
      await _controller!.pauseFocusSession(session.sessionId);
      _stopTicker();
      if (mounted) setState(() {});
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _resumeSession() async {
    final session = _controller?.activeFocusSession.value;
    if (session == null) return;
    try {
      await _controller!.resumeFocusSession(session.sessionId);
      _startTicker();
      if (mounted) setState(() {});
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _completeSession() async {
    final session = _controller?.activeFocusSession.value;
    if (session == null) return;
    try {
      final completed = await _controller!.completeFocusSession(
        session.sessionId,
      );
      _stopTicker();
      if (mounted) await _showCompletion(completed);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _completeExpiredSession(ProductivityFocusSession session) async {
    if (_autoCompleting) return;
    _autoCompleting = true;
    try {
      final completed = await _controller!.completeFocusSession(
        session.sessionId,
      );
      _stopTicker();
      if (mounted) await _showCompletion(completed);
    } catch (error) {
      _showError(error);
    } finally {
      _autoCompleting = false;
    }
  }

  Future<void> _leaveSession() async {
    final session = _controller?.activeFocusSession.value;
    if (session == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final leave = await FocusLeaveDialog.show(context);
    if (leave != true || !mounted) return;

    final focusedSeconds = _focusedSeconds(session);
    final focusedMinutes = focusedSeconds ~/ 60;

    try {
      await _controller!.abandonFocusSession(session.sessionId);
      _stopTicker();
      if (mounted) {
        await FocusSessionSummaryDialog.show(
          context,
          focusedMinutes: focusedMinutes,
          xpEarned: 0,
          isAbandoned: true,
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleBack() async {
    if (_controller?.activeFocusSession.value != null) {
      await _leaveSession();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showCompletion(ProductivityFocusSession session) async {
    final minutes = session.durationMinutes > 0
        ? session.durationMinutes
        : (session.focusedSeconds ~/ 60);
    await FocusCompleteDialog.show(
      context,
      focusedMinutes: minutes,
      xpEarned: session.xpEarned,
    );
  }

  int _focusedSeconds(ProductivityFocusSession session) {
    var focused = session.focusedSeconds;
    if (session.isActive) {
      final activeStartedAt = session.activeStartedAt ?? session.startedAt;
      if (activeStartedAt != null) {
        focused += DateTime.now().difference(activeStartedAt).inSeconds;
      }
    }
    return focused.clamp(0, session.durationMinutes * 60).toInt();
  }

  int _remainingSeconds(ProductivityFocusSession session) {
    final planned = session.durationMinutes * 60;
    return (planned - _focusedSeconds(session)).clamp(0, planned).toInt();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorText(error))));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const _UnavailableView();
    }

    return Obx(() {
      final active = controller.activeFocusSession.value;
      return PopScope(
        canPop: active == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && controller.activeFocusSession.value != null) {
            unawaited(_leaveSession());
          }
        },
        child: active == null
            ? FocusHomeView(
                controller: controller,
                selectedDuration: selectedDuration,
                isLoading: _loading,
                onDurationChanged: (val) =>
                    setState(() => selectedDuration = val),
                onStart: _startSession,
                onBack: () => unawaited(_handleBack()),
              )
            : (active.isPaused
                ? FocusPausedView(
                    session: active,
                    remainingSeconds: _remainingSeconds(active),
                    actionLoading: controller.isFocusActionLoading.value,
                    onBack: _handleBack,
                    onResume: _resumeSession,
                    onLeave: _leaveSession,
                  )
                : FocusRunningView(
                    session: active,
                    remainingSeconds: _remainingSeconds(active),
                    actionLoading: controller.isFocusActionLoading.value,
                    onBack: _handleBack,
                    onPause: _pauseSession,
                    onLeave: _leaveSession,
                    onComplete: _completeSession,
                  )),
      );
    });
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('productivity.unavailable'.tr)));
  }
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
