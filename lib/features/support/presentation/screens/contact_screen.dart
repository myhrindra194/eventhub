import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/backend/api_client.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// « Nous contacter » : un formulaire qui envoie un vrai email à la boîte de
/// l'entreprise.
///
/// Pourquoi un formulaire plutôt qu'un lien `mailto:` : sur le web et sur un
/// ordinateur sans client de messagerie configuré, `mailto:` n'ouvre rien, et
/// l'utilisateur croit que le bouton est cassé. Le message part ici du Worker
/// `eventhub-api`, avec l'adresse du compte en « répondre à » : l'équipe
/// répond depuis sa boîte, la réponse arrive chez l'utilisateur.
///
/// L'adresse de l'entreprise reste affichée et copiable, pour qui préfère
/// écrire depuis sa propre messagerie. Tant qu'aucune adresse n'est
/// configurée (`SUPPORT_EMAIL`) ou que le Worker n'est pas déployé, l'écran
/// le dit et désactive l'envoi, au lieu de promettre une réponse qui ne
/// viendra pas.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  static const _subjectMax = 120;
  static const _messageMax = 5000;

  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _available =>
      AppLinks.supportEmail.isNotEmpty &&
      ref.read(apiClientProvider).isConfigured;

  Future<void> _send() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _sending = true);
    final result = await ref.read(apiClientProvider).post('/v1/contact', {
      'subject': _subject.text.trim(),
      'message': _message.text.trim(),
    });
    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case Ok():
        context.showSuccess('Message envoyé. Nous vous répondons par email.');
        context.pop();
      case Err(failure: final ValidationFailure failure):
        setState(() => _serverErrors = failure.fieldErrors);
        _formKey.currentState!.validate();
        context.showFailure(failure);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _copyAddress() async {
    await Clipboard.setData(const ClipboardData(text: AppLinks.supportEmail));
    if (mounted) context.showSuccess('Adresse copiée.');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final user = ref.watch(currentUserProvider);
    final available = _available;
    final hasAddress = AppLinks.supportEmail.isNotEmpty;

    return AppScaffold(
      dense: true,
      resizeToAvoidBottomInset: true,
      appBar: AppTopBar.subPage(
        title: 'Nous contacter',
        onBack: () => context.pop(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Une question sur une réservation, un souci avec votre compte, '
              'une idée ? Écrivez-nous : la réponse arrive sur '
              '${user?.email ?? 'votre adresse'}, en général sous 48 h ouvrées.',
              style: text.bodyMedium?.copyWith(
                color: t.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // L'adresse de l'entreprise, lisible et copiable : c'est elle que
            // l'utilisateur retrouvera dans sa messagerie.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADRESSE DE L’ÉQUIPE',
                          style: text.labelSmall?.copyWith(
                            color: t.textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAddress
                              ? AppLinks.supportEmail
                              : 'Bientôt disponible',
                          style: text.titleMedium?.copyWith(
                            color: hasAddress ? t.textPrimary : t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasAddress)
                    TextButton(
                      onPressed: _copyAddress,
                      style: TextButton.styleFrom(
                        foregroundColor: t.brand,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brButton,
                        ),
                      ),
                      child: const Text('Copier'),
                    ),
                ],
              ),
            ),
            if (!available) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'L’envoi de messages depuis l’app n’est pas encore ouvert. Il '
                'le sera dès que la boîte de l’équipe sera en service.',
                style: text.bodySmall?.copyWith(
                  color: t.warning.fg,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            LabeledField(
              label: 'Objet',
              isRequired: true,
              child: TextFormField(
                controller: _subject,
                enabled: available,
                maxLength: _subjectMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                decoration: InputDecoration(
                  hintText: 'Ex. : mon billet ne s’affiche plus',
                  errorText: _serverErrors['subject'],
                ),
                validator: (value) {
                  final length = (value ?? '').trim().length;
                  if (length < 3) return 'Donnez un objet à votre message.';
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LabeledField(
              label: 'Message',
              isRequired: true,
              child: TextFormField(
                controller: _message,
                enabled: available,
                minLines: 6,
                maxLines: 12,
                maxLength: _messageMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Décrivez la situation : l’événement concerné, ce que '
                      'vous avez fait, ce qui s’est passé.',
                  alignLabelWithHint: true,
                  errorText: _serverErrors['message'],
                ),
                validator: (value) {
                  final length = (value ?? '').trim().length;
                  if (length < 10) {
                    return 'Quelques mots de plus pour que l’on puisse vous '
                        'aider (10 caractères au moins).';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: 'Envoyer le message',
              loadingLabel: 'Envoi…',
              isLoading: _sending,
              onPressed: available ? _send : null,
            ),
          ],
        ),
      ),
    );
  }
}
