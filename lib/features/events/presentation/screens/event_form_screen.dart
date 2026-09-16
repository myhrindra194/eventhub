import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_form_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_cover_field.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Créer / modifier un événement.
///
/// Un seul formulaire long plutôt qu’un assistant : un organisateur qui
/// publie son deuxième événement connaît tous les champs, et un assistant
/// lui ferait taper « suivant » quatre fois. Ce qui le rend supportable :
/// les contraintes sont énoncées *avant* l’erreur (lien de couverture en
/// https, longueur minimale du titre, plage de capacité), les erreurs de
/// validation renvoyées par le serveur sont rapportées sur le champ exact
/// qui les a provoquées, et le bouton d’envoi ne défile jamais hors de
/// portée.
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
        appBar: AppTopBar.subPage(
          title: AppStrings.editEvent,
          onBack: () => context.pop(),
        ),
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
  late final _imageUrl = TextEditingController(text: widget.initial?.imageUrl);

  // Types de billets (F-12).
  late bool _useTiers = widget.initial?.hasTiers ?? false;
  late String _currency = widget.initial?.currency ?? 'EUR';
  late final List<_TierFields> _tiers = [
    for (final tier in widget.initial?.tiers ?? const <EventTier>[])
      _TierFields.fromTier(tier, widget.initial!.currencyCode),
  ];

  /// Changer de mode est refusé dès que des places ont été vendues dans le
  /// mode courant (voir `TierPlanner.apply`) : l’interrupteur est désactivé
  /// plutôt que d’échouer à l’enregistrement.
  bool get _tierModeLocked => (widget.initial?.reservedCount ?? 0) > 0;

  int _soldOf(String? tierId) =>
      tierId == null ? 0 : widget.initial?.tier(tierId)?.sold ?? 0;

  bool get _hasPaidTier =>
      _tiers.any((f) => (Money.parse(f.price.text, _currency) ?? 0) > 0);

  late EventCategory _category =
      widget.initial?.category ?? EventCategory.meetup;
  late DateTime _startsAt =
      widget.initial?.startsAt ??
      ref.read(clockProvider)().add(const Duration(days: 7)).withTime(18, 0);

  Map<String, String> _serverErrors = const {};

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    _imageUrl.dispose();
    for (final tier in _tiers) {
      tier.dispose();
    }
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

    if (_useTiers && _tiers.isEmpty) {
      context.showToast(AppStrings.ticketTypesRequired);
      return;
    }

    final draft = EventDraft(
      title: _title.text,
      description: _description.text,
      category: _category,
      startsAt: _startsAt,
      location: _location.text,
      capacity: int.tryParse(_capacity.text.trim()) ?? 0,
      imageUrl: _imageUrl.text,
      currency: _useTiers ? _currency : null,
      tiers: !_useTiers
          ? const []
          : [
              for (final f in _tiers)
                EventTierDraft(
                  id: f.id,
                  name: f.name.text,
                  description: f.description.text,
                  // Les validateurs ont déjà refusé les prix illisibles.
                  price: Money.parse(f.price.text, _currency) ?? -1,
                  capacity: int.tryParse(f.capacity.text.trim()) ?? 0,
                ),
            ],
    );

    final result = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(draft: draft, existingEventId: widget.initial?.id);
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
        // Les règles côté serveur font foi ; on les remonte sur les champs
        // eux-mêmes, pas seulement dans un toast.
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
      // Même retour que partout ailleurs : un formulaire ouvert par-dessus
      // reste une sous-page, et une croix ici contre une flèche ailleurs est
      // exactement ce qui fait paraître une application assemblée en pièces
      // détachées.
      appBar: AppTopBar.subPage(
        title: _isEditing ? AppStrings.editEvent : AppStrings.createEvent,
        onBack: () => context.pop(),
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
              hint: 'Lien https vers une image paysage (16:9), facultatif',
              child: EventCoverField(
                controller: _imageUrl,
                seed: widget.initial?.id ?? 'new-event',
                errorText: _fieldError('imageUrl'),
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
            AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _useTiers,
                onChanged: _tierModeLocked
                    ? null
                    : (v) => setState(() {
                        _useTiers = v;
                        if (v && _tiers.isEmpty) {
                          _tiers.add(
                            _TierFields(
                              name: 'Standard',
                              capacity: _capacity.text.trim().isEmpty
                                  ? '50'
                                  : _capacity.text.trim(),
                            ),
                          );
                        }
                      }),
                title: Text(
                  AppStrings.ticketTypesToggle,
                  style: context.textTheme.titleMedium,
                ),
                subtitle: Text(
                  AppStrings.ticketTypesToggleHint,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!_useTiers)
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
              )
            else
              _TiersEditor(
                tiers: _tiers,
                currency: _currency,
                showCurrency: _hasPaidTier,
                isEditing: _isEditing,
                soldOf: _soldOf,
                tiersError: _fieldError('tiers'),
                currencyError: _fieldError('currency'),
                onChanged: () => setState(() {}),
                onCurrency: (c) => setState(() => _currency = c),
                onAdd: () => setState(() => _tiers.add(_TierFields())),
                onRemove: (i) => setState(() => _tiers.removeAt(i).dispose()),
              ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              AppSurface(
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

/// Contrôleurs de texte d’une ligne de type de billet.
class _TierFields {
  _TierFields({
    this.id,
    String name = '',
    String description = '',
    String price = '0',
    String capacity = '50',
  }) : name = TextEditingController(text: name),
       description = TextEditingController(text: description),
       price = TextEditingController(text: price),
       capacity = TextEditingController(text: capacity);

  factory _TierFields.fromTier(EventTier tier, String currency) => _TierFields(
    id: tier.id,
    name: tier.name,
    description: tier.description,
    price: Money.inputValue(tier.price, currency),
    capacity: '${tier.capacity}',
  );

  final String? id;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController capacity;

  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    capacity.dispose();
  }
}

/// Un bloc encadré par type de billet : le nom, puis le prix et les places
/// sur une même ligne (les deux nombres que l’on compare), puis ce que le
/// billet inclut. Un type qui a déjà vendu le dit et ne peut plus être
/// retiré ; ses places ne peuvent pas descendre sous ce qui a été vendu.
class _TiersEditor extends StatelessWidget {
  const _TiersEditor({
    required this.tiers,
    required this.currency,
    required this.showCurrency,
    required this.isEditing,
    required this.soldOf,
    required this.onChanged,
    required this.onCurrency,
    required this.onAdd,
    required this.onRemove,
    this.tiersError,
    this.currencyError,
  });

  final List<_TierFields> tiers;
  final String currency;
  final bool showCurrency;
  final bool isEditing;
  final int Function(String? id) soldOf;
  final VoidCallback onChanged;
  final ValueChanged<String> onCurrency;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String? tiersError;
  final String? currencyError;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final total = tiers.fold<int>(
      0,
      (sum, f) => sum + (int.tryParse(f.capacity.text.trim()) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SectionLabel(AppStrings.ticketTypes),
            const Spacer(),
            Text(
              '$total ${AppStrings.ticketTypeCapacity.toLowerCase()}',
              style: text.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < tiers.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.brButton,
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '${AppStrings.ticketTypes.substring(0, 6)} ${i + 1}',
                      style: text.labelMedium,
                    ),
                    const Spacer(),
                    if (soldOf(tiers[i].id) > 0)
                      Text(
                        '${soldOf(tiers[i].id)} vendu'
                        '${soldOf(tiers[i].id) > 1 ? 's' : ''}',
                        style: text.labelSmall?.copyWith(letterSpacing: 0),
                      ),
                    IconButton(
                      tooltip: AppStrings.removeTicketType,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: soldOf(tiers[i].id) > 0 || tiers.length == 1
                          ? null
                          : () => onRemove(i),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: tiers[i].name,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: EventTier.maxNameLength,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        decoration: const InputDecoration(
                          hintText: AppStrings.ticketTypeNameHint,
                        ),
                        onChanged: (_) => onChanged(),
                        validator: (v) =>
                            Validators.required(v, label: 'Le nom du billet'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tiers[i].price,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: AppStrings.ticketTypePrice,
                                suffixText: Money.symbol(currency),
                              ),
                              onChanged: (_) => onChanged(),
                              validator: (v) =>
                                  Money.parse(v ?? '', currency) == null
                                  ? AppStrings.invalidPrice
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: tiers[i].capacity,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: AppStrings.ticketTypeCapacity,
                              ),
                              onChanged: (_) => onChanged(),
                              validator: (v) {
                                final base = Validators.positiveInt(
                                  v,
                                  label: 'Le nombre de places',
                                );
                                if (base != null) return base;
                                final sold = soldOf(tiers[i].id);
                                return int.parse(v!.trim()) < sold
                                    ? 'Au moins $sold (déjà vendus)'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: tiers[i].description,
                        maxLength: EventTier.maxDescriptionLength,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: AppStrings.ticketTypeDescriptionHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (tiers.length < EventTier.maxTiers)
          AppButton.secondary(
            label: AppStrings.addTicketType,
            size: AppButtonSize.medium,
            onPressed: onAdd,
          ),
        if (showCurrency) ...[
          const SizedBox(height: AppSpacing.xl),
          LabeledField(
            label: AppStrings.currencyLabel,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final code in Money.currencies)
                  ChoiceChip(
                    label: Text('$code · ${Money.symbol(code)}'),
                    selected: code == currency,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brButton,
                    ),
                    onSelected: (_) => onCurrency(code),
                  ),
              ],
            ),
          ),
        ],
        for (final error in [?tiersError, ?currencyError])
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              error,
              style: text.bodySmall?.copyWith(color: t.danger.fg),
            ),
          ),
        if (isEditing) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.ticketTypesEditHint, style: text.bodySmall),
        ],
      ],
    );
  }
}

/// La catégorie en pastilles réparties sur plusieurs lignes plutôt qu’en
/// liste déroulante : sept options tiennent à l’écran, et les voir toutes
/// va plus vite que d’ouvrir un menu pour les découvrir.
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
                borderRadius: AppRadius.brButton,
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
