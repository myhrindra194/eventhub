import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_form_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_image_picker.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit an event.
///
/// One long form rather than a wizard: an organizer publishing their second
/// event knows every field, and a wizard would make them tap "suivant" four
/// times. What makes it bearable is that constraints are stated *before*
/// the mistake (image size, minimum title, capacity range), server-side
/// validation errors are mapped back onto the exact field that caused
/// them, and the submit button never scrolls out of reach.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.eventId});

  final String? eventId;

  bool get isEditing => eventId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isEditing) return const _EventForm();

    return AsyncValueWidget(
      value: ref.watch(eventByIdProvider(eventId!)),
      isEmpty: (e) => e == null,
      empty: AppScaffold(
        appBar: AppBar(),
        body: const EmptyStateView(message: AppStrings.eventNotFound),
      ),
      data: (e) => _EventForm(initial: e),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.initial});

  final Event? initial;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();

  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _capacity = TextEditingController(
    text: widget.initial?.capacity.toString() ?? '50',
  );

  late EventCategory _category =
      widget.initial?.category ?? EventCategory.meetup;
  late DateTime _startsAt =
      widget.initial?.startsAt ??
      ref.read(clockProvider)().add(const Duration(days: 7)).withTime(18, 0);

  PendingImage? _pendingImage;
  Map<String, String> _serverErrors = const {};

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt.isAfter(now) ? _startsAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    setState(() => _startsAt = date.withTime(_startsAt.hour, _startsAt.minute));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;
    setState(() => _startsAt = _startsAt.withTime(time.hour, time.minute));
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final draft = EventDraft(
      title: _title.text,
      description: _description.text,
      category: _category,
      startsAt: _startsAt,
      location: _location.text,
      capacity: int.tryParse(_capacity.text.trim()) ?? 0,
      imageUrl: widget.initial?.imageUrl,
    );

    final result = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(
          draft: draft,
          existingEventId: widget.initial?.id,
          image: _pendingImage,
        );
    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        if (_isEditing) {
          context.showSuccess(AppStrings.eventUpdated);
          context.pop();
        } else {
          context.pushReplacement(AppRoutes.organizerEventPublishedPath(value));
        }
      case Err(failure: final ValidationFailure failure):
        // Server-side rules are the source of truth; surface them on the
        // fields themselves rather than only in a toast.
        setState(() => _serverErrors = failure.fieldErrors);
        _formKey.currentState!.validate();
        context.showFailure(failure);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  String? _fieldError(String field) => _serverErrors[field];

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(eventFormControllerProvider).isLoading;
    final t = context.tokens;

    return AppScaffold(
      dense: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editEvent : AppStrings.createEvent),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: AppStrings.cancel,
          onPressed: () => context.pop(),
        ),
      ),
      bottomBar: FrostedBar(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        child: AppButton.primary(
          label: _isEditing ? AppStrings.save : AppStrings.publish,
          loadingLabel: _isEditing ? 'Enregistrement…' : 'Publication…',
          icon: _isEditing ? Icons.check_rounded : Icons.rocket_launch_rounded,
          isLoading: isLoading,
          onPressed: _submit,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            120,
          ),
          children: [
            LabeledField(
              label: AppStrings.eventBanner,
              hint: 'JPG ou PNG, 5 Mo maximum — format paysage recommandé',
              child: EventImagePicker(
                currentUrl: widget.initial?.imageUrl,
                pending: _pendingImage,
                onPicked: (image) => setState(() => _pendingImage = image),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            LabeledField(
              label: AppStrings.eventName,
              isRequired: true,
              child: TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                decoration: InputDecoration(
                  hintText: AppStrings.eventNameHint,
                  errorText: _fieldError('title'),
                ),
                validator: (v) => Validators.minLength(
                  v,
                  EventDraft.titleMinLength,
                  label: 'Le titre',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LabeledField(
              label: AppStrings.description,
              isRequired: true,
              hint: 'Programme, intervenants, ce qu\'il faut apporter…',
              child: TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppStrings.descriptionHint,
                  alignLabelWithHint: true,
                  errorText: _fieldError('description'),
                ),
                validator: (v) =>
                    Validators.required(v, label: 'La description'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LabeledField(
              label: AppStrings.category,
              child: _CategoryPicker(
                value: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: AppStrings.date,
                    child: PickerField(
                      icon: Icons.calendar_month_rounded,
                      value: AppDateFormats.shortDate(_startsAt),
                      onTap: _pickDate,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: LabeledField(
                    label: AppStrings.time,
                    child: PickerField(
                      icon: Icons.schedule_rounded,
                      value: AppDateFormats.time(_startsAt),
                      onTap: _pickTime,
                    ),
                  ),
                ),
              ],
            ),
            if (_fieldError('startsAt') != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.xs,
                ),
                child: Text(
                  _fieldError('startsAt')!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: t.danger.fg,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            LabeledField(
              label: AppStrings.location,
              isRequired: true,
              child: TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'ex. Antananarivo, Analakely',
                  prefixIcon: const Icon(Icons.place_outlined, size: 20),
                  errorText: _fieldError('location'),
                ),
                validator: (v) => Validators.required(v, label: 'Le lieu'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LabeledField(
              label: AppStrings.capacity,
              isRequired: true,
              hint: 'Nombre total de places mises en vente',
              child: TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '50',
                  prefixIcon: const Icon(Icons.event_seat_outlined, size: 20),
                  suffixText: 'places',
                  errorText: _fieldError('capacity'),
                ),
                validator: (v) =>
                    Validators.positiveInt(v, label: 'La capacité'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              AppSurface(
                elevation: SurfaceElevation.flat,
                color: t.info.bg,
                borderColor: t.info.border,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: t.info.fg,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Réduire la capacité en dessous du nombre de places '
                        'déjà réservées sera refusé.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: t.info.fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Category as a wrap of chips rather than a dropdown: seven options fit on
/// screen, and seeing them all is faster than opening a menu to discover
/// them.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final EventCategory value;
  final ValueChanged<EventCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in EventCategory.values)
          GestureDetector(
            onTap: () => onChanged(category),
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: category == value
                    ? category.color(context)
                    : t.surfaceSunken,
                borderRadius: AppRadius.brPill,
                border: Border.all(
                  color: category == value ? category.color(context) : t.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 15,
                    color: category == value ? Colors.white : t.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: category == value ? Colors.white : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
