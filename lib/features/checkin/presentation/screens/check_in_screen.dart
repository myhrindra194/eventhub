import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/checkin/application/check_in_providers.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Door check-in.
///
/// Built for a volunteer with a queue in front of them: the camera takes
/// most of the screen, the verdict is a full-width coloured band with one
/// word and the holder's name, a distinct haptic separates "entrez" from
/// "non", and the next scan resumes on its own. When the camera is refused
/// or the QR is unreadable, the short code can be typed instead — the same
/// check runs either way.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

/// What the band shows: a verdict, or a QR that is not a ticket at all.
typedef _Outcome = ({CheckInVerdict? verdict, bool notATicket});

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _scanner = MobileScannerController();
  final _code = TextEditingController();
  _Outcome? _outcome;
  bool _busy = false;
  String? _lastRaw;
  DateTime _lastRawAt = DateTime(0);
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    _code.dispose();
    unawaited(_scanner.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || _busy) return;
    // The camera reports the same code many times per second.
    final now = DateTime.now();
    if (raw == _lastRaw && now.difference(_lastRawAt).inSeconds < 4) return;
    _lastRaw = raw;
    _lastRawAt = now;

    final payload = TicketPayload.parse(raw);
    if (payload == null) {
      _show((verdict: null, notATicket: true));
      return;
    }
    await _check(payload.reservationId, payload.code);
  }

  Future<void> _submitCode() async {
    final code = TicketPayload.normalizeCode(_code.text);
    if (code.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    final participants =
        ref.read(eventParticipantsProvider(widget.eventId)).value ?? const [];
    final match = participants
        .where((r) => TicketPayload.normalizeCode(r.ticketCode) == code)
        .firstOrNull;
    if (match == null) {
      _show((
        verdict: const CheckInVerdict(CheckInStatus.notFound),
        notATicket: false,
      ));
      return;
    }
    await _check(match.id, code);
    _code.clear();
  }

  Future<void> _check(String reservationId, String code) async {
    setState(() => _busy = true);
    final result = await ref
        .read(checkInControllerProvider.notifier)
        .scan(
          eventId: widget.eventId,
          reservationId: reservationId,
          code: code,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        _show((verdict: value, notATicket: false));
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  void _show(_Outcome outcome) {
    final admitted = outcome.verdict?.isAdmitted ?? false;
    if (admitted) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() => _outcome = outcome);
    _reset?.cancel();
    _reset = Timer(Duration(seconds: admitted ? 3 : 6), () {
      if (mounted) setState(() => _outcome = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final event = ref.watch(eventByIdProvider(widget.eventId)).value;
    final total =
        ref.watch(eventParticipantsProvider(widget.eventId)).value?.length ?? 0;
    final checkedIn =
        ref.watch(eventCheckInsProvider(widget.eventId)).value?.length ?? 0;

    return AppScaffold(
      dense: true,
      extendBody: false,
      appBar: AppBar(
        title: const Text(AppStrings.checkInTitle),
        actions: [
          ValueListenableBuilder(
            valueListenable: _scanner,
            builder: (_, state, __) => IconButton(
              tooltip: AppStrings.torch,
              onPressed: _scanner.toggleTorch,
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event?.title ?? '',
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  AppStrings.checkedInCount(checkedIn, total),
                  style: text.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.brButton,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scanner,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => ColoredBox(
                        color: t.surfaceSunken,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              AppStrings.cameraUnavailable,
                              textAlign: TextAlign.center,
                              style: text.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const IgnorePointer(
                      child: CustomPaint(painter: _FramePainter()),
                    ),
                    if (_busy) const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedSwitcher(
              duration: AppMotion.short,
              child: _outcome == null
                  ? Padding(
                      key: const ValueKey('hint'),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        AppStrings.scanHint,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    )
                  : _VerdictBand(
                      key: ValueKey(_outcome),
                      outcome: _outcome!,
                      onDismiss: () => setState(() => _outcome = null),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitCode(),
                    decoration: const InputDecoration(
                      hintText: AppStrings.manualEntryHint,
                      prefixIcon: Icon(Icons.keyboard_rounded, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.secondary(
                  label: AppStrings.checkCode,
                  size: AppButtonSize.medium,
                  expand: false,
                  elevated: false,
                  onPressed: _busy ? null : _submitCode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictBand extends StatelessWidget {
  const _VerdictBand({
    required this.outcome,
    required this.onDismiss,
    super.key,
  });

  final _Outcome outcome;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final verdict = outcome.verdict;

    final (tone, icon, title) = outcome.notATicket || verdict == null
        ? (AppTone.danger, Icons.qr_code_2_rounded, AppStrings.notATicket)
        : switch (verdict.status) {
            CheckInStatus.admitted => (
              AppTone.success,
              Icons.check_circle_rounded,
              AppStrings.admitted,
            ),
            CheckInStatus.alreadyCheckedIn => (
              AppTone.warning,
              Icons.history_rounded,
              AppStrings.alreadyCheckedIn(
                AppDateFormats.time(verdict.checkedInAt ?? DateTime.now()),
              ),
            ),
            CheckInStatus.unpaid => (
              AppTone.danger,
              Icons.credit_card_off_rounded,
              AppStrings.ticketUnpaidAtDoor,
            ),
            CheckInStatus.cancelled => (
              AppTone.danger,
              Icons.block_rounded,
              AppStrings.ticketCancelledAtDoor,
            ),
            CheckInStatus.wrongEvent => (
              AppTone.danger,
              Icons.event_busy_rounded,
              AppStrings.ticketWrongEvent,
            ),
            CheckInStatus.invalidCode => (
              AppTone.danger,
              Icons.gpp_bad_rounded,
              AppStrings.ticketInvalidCode,
            ),
            CheckInStatus.notFound => (
              AppTone.danger,
              Icons.help_outline_rounded,
              AppStrings.ticketUnknown,
            ),
          };
    final colors = t.resolve(tone);
    // Name and ticket type only: the door function does not hand out emails.
    final holder = verdict?.holderName;

    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.solid,
        borderRadius: AppRadius.brButton,
        child: InkWell(
          onTap: onDismiss,
          borderRadius: AppRadius.brButton,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, size: 32, color: colors.onSolid),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleLarge?.copyWith(color: colors.onSolid),
                      ),
                      if (holder != null)
                        Text(
                          '$holder · ${verdict!.accessLabel}',
                          style: text.bodySmall?.copyWith(
                            color: colors.onSolid.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

/// Four corner brackets marking where to hold the ticket.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.62;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    const arm = 28.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner + Offset(arm * dx, 0), paint)
        ..drawLine(corner, corner + Offset(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}
