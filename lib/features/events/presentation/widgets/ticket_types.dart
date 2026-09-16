import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:flutter/material.dart';

/// « Gratuit », « 25,00 € », « Dès 15,00 € », « Gratuit ou payant ».
String eventPriceLabel(Event event) {
  final min = event.minPrice;
  if (min == null) return AppStrings.free;
  if (event.tiers.any((t) => t.isFree)) return AppStrings.freeOrPaid;
  final price = Money.format(min, event.currencyCode);
  final samePrice = event.tiers.every((t) => t.price == min);
  return samePrice ? price : AppStrings.fromPrice(price);
}

String tierPriceLabel(EventTier tier, String currency) =>
    tier.isFree ? AppStrings.free : Money.format(tier.price, currency);

/// Les types de billets d’un événement, présentés comme une grille
/// tarifaire à filets : ce que le billet inclut à gauche, le prix et les
/// places restantes à droite (F-12).
class TicketTypesSection extends StatelessWidget {
  const TicketTypesSection({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(AppStrings.ticketTypes),
        const SizedBox(height: AppSpacing.md),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.brButton,
            border: Border.all(color: t.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < event.tiers.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.borderSubtle),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.tiers[i].name, style: text.titleSmall),
                            if (event.tiers[i].description.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                event.tiers[i].description,
                                style: text.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            tierPriceLabel(event.tiers[i], event.currencyCode),
                            style: text.titleSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            event.tiers[i].isSoldOut
                                ? AppStrings.tierSoldOut
                                : AppStrings.seatsLeftShort(
                                    event.tiers[i].available,
                                  ),
                            style: text.labelSmall?.copyWith(
                              letterSpacing: 0,
                              color: event.tiers[i].isSoldOut
                                  ? t.danger.fg
                                  : t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Choisit un type de billet avant la réservation. Les types complets ou
/// payants restent listés (la grille tarifaire ne doit pas changer sous les
/// yeux de l’utilisateur) mais ne peuvent pas être sélectionnés : sans
/// serveur de paiement, seule une place gratuite est réservable, et un type
/// payant le dit plutôt que d’ouvrir un parcours de paiement qui ne peut
/// pas aboutir.
Future<EventTier?> showTicketTypePicker(BuildContext context, Event event) {
  return showAppSheet<EventTier>(
    context: context,
    builder: (_) => _TicketTypePicker(event: event),
  );
}

class _TicketTypePicker extends StatefulWidget {
  const _TicketTypePicker({required this.event});

  final Event event;

  @override
  State<_TicketTypePicker> createState() => _TicketTypePickerState();
}

class _TicketTypePickerState extends State<_TicketTypePicker> {
  late EventTier? _selected = widget.event.tiers
      .where((t) => !t.isSoldOut && t.isFree)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final selected = _selected;
    final currency = widget.event.currencyCode;

    return AppSheet(
      title: AppStrings.chooseTicket,
      subtitle: widget.event.title,
      actions: [
        AppButton.primary(
          label: selected == null
              ? AppStrings.chooseTicket
              : AppStrings.bookFree,
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.chooseTicketLead,
              style: text.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < widget.event.tiers.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: t.borderSubtle),
                    _TierOption(
                      tier: widget.event.tiers[i],
                      currency: currency,
                      selected: widget.event.tiers[i].id == selected?.id,
                      onTap:
                          widget.event.tiers[i].isSoldOut ||
                              !widget.event.tiers[i].isFree
                          ? null
                          : () => setState(
                              () => _selected = widget.event.tiers[i],
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierOption extends StatelessWidget {
  const _TierOption({
    required this.tier,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final EventTier tier;
  final String currency;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final disabled = onTap == null;

    return Semantics(
      selected: selected,
      enabled: !disabled,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            color: selected ? t.brand.withValues(alpha: 0.08) : null,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? t.brand : t.borderStrong,
                      width: selected ? 5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.name, style: text.titleSmall),
                      if (tier.description.isNotEmpty)
                        Text(tier.description, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        tier.isSoldOut
                            ? AppStrings.tierSoldOut
                            : !tier.isFree
                            ? AppStrings.paidTicketUnavailable
                            : AppStrings.seatsLeftShort(tier.available),
                        style: text.labelSmall?.copyWith(
                          letterSpacing: 0,
                          color: tier.isSoldOut ? t.danger.fg : t.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  tierPriceLabel(tier, currency),
                  style: text.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
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
