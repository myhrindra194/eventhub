import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/media/camera_access_prompt.dart';
import 'package:eventhub/core/media/camera_permission.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/media_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/validators.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:eventhub/features/auth/presentation/widgets/profile_images_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Édite le profil de l’utilisateur connecté.
///
/// Le nom pour tout le monde et, pour les organisateurs, la présentation
/// affichée sur leur profil public. L’e-mail et le rôle sont montrés —
/// grisés, avec un cadenas et une phrase qui dit pourquoi — plutôt que
/// cachés : un utilisateur qui cherche « changer mon e-mail » doit apprendre
/// que ce n’est pas possible ici, au lieu de se demander s’il a raté un menu.
///
/// L’avatar au-dessus du formulaire suit le nom au fur et à mesure de la
/// frappe ; c’est l’aperçu le moins coûteux de ce que le changement donnera
/// ailleurs.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Reprend `isString(bio, 0, 500)` de firestore.rules.
  static const _bioMax = 500;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;

  /// Les liens des images tels qu'ils seront enregistrés.
  ///
  /// Le fichier part vers Cloudinary dès qu'il est choisi — c'est ce qui
  /// permet d'afficher la vraie image hébergée avant d'enregistrer — mais le
  /// lien n'entre dans Firestore qu'au « Enregistrer », comme le nom :
  /// renoncer à la page ne doit rien changer au profil. Le prix de ce choix
  /// est une image orpheline dans la médiathèque quand l'utilisateur
  /// abandonne, que l'envoi non signé ne peut pas supprimer.
  String? _photoUrl;
  String? _coverUrl;
  bool _photosChanged = false;
  bool _uploadingPhoto = false;
  bool _uploadingCover = false;

  bool get _uploading => _uploadingPhoto || _uploadingCover;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name);
    _bio = TextEditingController(text: user?.bio);
    _photoUrl = user?.photoUrl;
    _coverUrl = user?.coverUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _isOrganizer => ref.read(currentUserProvider)?.isOrganizer ?? false;

  bool get _isDirty {
    final user = ref.read(currentUserProvider);
    final nameChanged = _name.text.trim() != (user?.name ?? '');
    final bioChanged =
        _isOrganizer && _bio.text.trim() != (user?.bio ?? '').trim();
    return nameChanged || bioChanged || _photosChanged;
  }

  /// Choisit, remplace ou retire une des deux images.
  ///
  /// Les refus — image trop lourde, envoi échoué, réseau coupé — portent déjà
  /// leur phrase : il suffit de la montrer, l'image précédente restant en
  /// place.
  Future<void> _editImage({required bool cover}) async {
    final flow = ref.read(imageUploadFlowProvider);
    final current = cover ? _coverUrl : _photoUrl;
    final hasImage = current != null && current.isNotEmpty;
    if (!flow.isAvailable && !hasImage) {
      context.showToast(AppStrings.imageUploadUnavailable);
      return;
    }

    final choice = await showPhotoSourceSheet(
      context,
      cover: cover,
      hasImage: hasImage,
      canUpload: flow.isAvailable,
    );
    if (choice == null || !mounted) return;

    if (choice == PhotoChoice.remove) {
      setState(() {
        if (cover) {
          _coverUrl = null;
        } else {
          _photoUrl = null;
        }
        _photosChanged = true;
      });
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // La permission est réglée *avant* d'afficher l'indicateur d'envoi : sinon
    // l'avatar tournerait derrière la feuille d'explication, comme si un envoi
    // était déjà parti. Caméra et galerie passent toutes deux par une demande
    // d'autorisation expliquée : le produit veut que l'utilisateur accorde
    // l'accès en connaissance de cause, même là où le sélecteur système
    // pourrait s'en passer.
    final allowed = choice == PhotoChoice.camera
        ? await ensureMediaAccess(
            context,
            ref.read(cameraAccessGateProvider),
            MediaAccess.camera,
          )
        : await ensureMediaAccess(
            context,
            ref.read(photoLibraryAccessGateProvider),
            MediaAccess.photos,
          );
    if (!allowed || !mounted) return;

    setState(() => cover ? _uploadingCover = true : _uploadingPhoto = true);
    final result = await flow.run(
      kind: cover ? ImageKind.profileCover : ImageKind.avatar,
      source: choice == PhotoChoice.camera
          ? PhotoSource.camera
          : PhotoSource.gallery,
      ownerId: user.id,
    );
    if (!mounted) return;
    setState(() => cover ? _uploadingCover = false : _uploadingPhoto = false);

    switch (result) {
      // L'utilisateur a refermé la galerie sans rien choisir.
      case null:
        return;
      case Ok(:final value):
        setState(() {
          if (cover) {
            _coverUrl = value.url;
          } else {
            _photoUrl = value.url;
          }
          _photosChanged = true;
        });
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  String? _validate(String? value) {
    final base = Validators.minLength(value, 2, label: 'Le nom');
    if (base != null) return base;
    // Reprend `isString(name, 2, 80)` de firestore.rules : échouer ici avec
    // une phrase plutôt que sur le serveur avec une erreur de permission.
    if (value!.trim().length > 80) return '80 caractères maximum.';
    return null;
  }

  String? _validateBio(String? value) =>
      (value ?? '').trim().length > _bioMax ? AppStrings.bioTooLong : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_uploading) {
      context.showToast(AppStrings.waitForImageUpload);
      return;
    }

    if (!_isDirty) {
      context.showToast(AppStrings.nameUnchanged);
      return;
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _name.text,
          bio: _isOrganizer ? _bio.text.trim() : null,
          photoUrl: _photoUrl,
          coverUrl: _coverUrl,
          updatePhotos: _photosChanged,
        );

    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.profileUpdated);
        context.pop();
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final preview = _name.text.trim().isEmpty ? (user?.name ?? '') : _name.text;

    return AuthShell(
      title: AppStrings.editProfileTitle,
      lead: AppStrings.editProfileLead,
      showMark: false,
      hero: ProfileImagesEditor(
        name: preview,
        photoUrl: _photoUrl,
        coverUrl: _coverUrl,
        onEditPhoto: () => _editImage(cover: false),
        onEditCover: () => _editImage(cover: true),
        uploadingPhoto: _uploadingPhoto,
        uploadingCover: _uploadingCover,
      ),
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldGroup(
                children: [
                  FieldRow(
                    icon: Icons.person_outline_rounded,
                    controller: _name,
                    label: AppStrings.name,
                    hint: 'Elvis Rakoto',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: (user?.isOrganizer ?? false)
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    validator: _validate,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (user?.isOrganizer ?? false)
                        ? null
                        : (_) => _submit(),
                  ),
                ],
              ),
              if (user?.isOrganizer ?? false) ...[
                const SizedBox(height: AppSpacing.xxl),
                const SectionLabel(AppStrings.publicProfileSection),
                const SizedBox(height: AppSpacing.md),
                FieldGroup(
                  children: [
                    TextFormField(
                      controller: _bio,
                      minLines: 3,
                      maxLines: 7,
                      maxLength: _bioMax,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _validateBio,
                      onChanged: (_) => setState(() {}),
                      style: context.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: AppStrings.bioLabel,
                        hintText: AppStrings.bioHint,
                        alignLabelWithHint: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                        counterStyle: context.textTheme.labelSmall?.copyWith(
                          color: t.textTertiary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.publicProfileHelp,
                  style: context.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SectionLabel(AppStrings.lockedFields),
        const SizedBox(height: AppSpacing.md),
        FieldGroup(
          children: [
            _LockedRow(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: user?.email ?? '',
            ),
            _LockedRow(
              icon: Icons.badge_outlined,
              label: AppStrings.role,
              value: user?.role.label ?? '',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.lockedFieldsHint,
          style: context.textTheme.bodySmall?.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: AppStrings.save,
          loadingLabel: 'Enregistrement…',
          isLoading: isLoading,
          onPressed: _isDirty && !_uploading ? _submit : null,
        ),
      ],
    );
  }
}

/// Une ligne en lecture seule ayant la même géométrie que [FieldRow], pour
/// que les deux groupes s’alignent colonne par colonne.
class _LockedRow extends StatelessWidget {
  const _LockedRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 19, color: t.textTertiary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 86, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: text.bodyLarge?.copyWith(color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: t.textTertiary),
        ],
      ),
    );
  }
}
