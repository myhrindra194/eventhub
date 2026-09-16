/// Les textes français de l'interface. Rassemblés en un seul endroit pour
/// qu'une future migration vers les fichiers ARB de `flutter_localizations`
/// se réduise à un remplacement mécanique.
abstract final class AppStrings {
  static const appName = 'EventHub';
  static const tagline = 'Premium experiences';

  // Onboarding
  static const skip = 'Passer';
  static const getStarted = 'Commencer';
  static const onboarding1Kicker = 'Découvrir';
  static const onboarding1Title = 'Ce qui se passe près de vous, cette semaine';
  static const onboarding1Body =
      'Concerts, conférences, meetups, ateliers. Un catalogue tenu à jour, '
      'filtrable par catégorie et par date.';
  static const onboarding2Kicker = 'Réserver';
  static const onboarding2Title = 'Une place se prend en un geste';
  static const onboarding2Body =
      'Votre billet arrive dans « Billets », avec son statut en temps réel. '
      'Présentez son code à l’entrée, il est scanné sur place.';
  static const onboarding3Kicker = 'Organiser';
  static const onboarding3Title = 'Publiez, suivez, accueillez';
  static const onboarding3Body =
      'Ouvrez votre espace organisateur quand vous le voulez : capacité, '
      'liste des inscrits, contrôle à l’entrée.';

  // Auth
  static const welcomeBack = 'Bon retour';
  static const signInSubtitle = 'Connectez-vous pour continuer sur EventHub';
  static const login = 'Se connecter';
  static const signingIn = 'Connexion…';
  static const register = "S'inscrire";
  static const createAccount = 'Créer un compte';
  static const createAccountSubtitle = 'Rejoignez la communauté';
  static const yourProfile = 'Votre profil';
  static const yourProfileSubtitle =
      'Dites-nous comment vous utiliserez EventHub';
  static const chooseRole = 'Choisissez votre rôle';
  static const continueLabel = 'Continuer';
  static const goBack = 'Retour';
  static const logout = 'Se déconnecter';
  static const email = 'Adresse email';
  static const password = 'Mot de passe';
  static const passwordHint = 'Min. 6 caractères';
  static const firstName = 'Prénom';
  static const lastName = 'Nom';
  static const name = 'Nom';
  static const forgotPassword = 'Mot de passe oublié ?';
  static const resetSent = 'Email de réinitialisation envoyé.';
  static const noAccount = 'Pas encore de compte ?';
  static const haveAccount = 'Déjà un compte ?';
  static const completeProfile = 'Compléter mon profil';
  static const completeProfileHint =
      'Votre compte existe mais votre profil est incomplet.';
  static const allSet = 'Tout est prêt !';
  static const allSetHint =
      'Votre compte a été créé avec succès. Bienvenue sur la plateforme '
      "d'événements premium.";
  static const exploreEvents = 'Explorer les événements';
  static const redirecting = 'Redirection dans 3 secondes…';

  // Navigation
  static const explore = 'Explorer';
  static const search = 'Recherche';
  static const tickets = 'Billets';
  static const profile = 'Profil';
  static const events = 'Événements';
  static const myReservations = 'Mes billets';
  static const myEvents = 'Mes événements';
  static const myEventsSubtitle = 'Gérez vos événements publiés';

  // Events
  static const exploreCaption = 'Explorer';
  static const exploreTitle = 'À la une';
  static const searchEvents = 'Rechercher musique, tech, art…';
  static const searchHint = 'Rechercher un événement';
  static const results = 'Résultats';
  static const filters = 'Filtres';
  static const allCategories = 'Tous';
  static const noEventsTitle = 'Aucun événement';
  static const noEvents = "Aucun événement n'est disponible pour le moment.";
  static const noEventsMatch =
      'Aucun événement ne correspond à votre recherche. Essayez '
      "d'autres mots-clés ou filtres.";
  static const clearFilters = 'Effacer les filtres';
  static const eventNotFound = 'Événement introuvable.';
  static const seatsLeft = 'places restantes';
  static const available = 'Disponible';
  static const sellingFast = 'Dernières places';
  static const onlyLeft = 'Plus que';
  static const soldOut = 'Complet';
  static const noVacancy = 'Aucune place';
  static const past = 'Terminé';
  static const free = 'Gratuit';
  static const organizer = 'Organisateur';
  static const capacity = 'Capacité';
  static const description = 'Description';
  static const location = 'Lieu';
  static const date = 'Date';
  static const time = 'Heure';
  static const category = 'Catégorie';
  static const eventName = "Nom de l'événement";
  static const eventNameHint = 'ex. Flutter Meetup Madagascar';
  static const descriptionHint = 'De quoi parle cet événement ?';
  static const eventBanner = "Bannière de l'événement";
  static const uploadImage = 'Importer une image HD';
  static const changeImage = "Changer l'image";
  static const createEvent = 'Créer un événement';
  static const createFirstEvent = 'Créer mon premier événement';
  static const editEvent = "Modifier l'événement";
  static const deleteEvent = "Supprimer l'événement ?";
  static const deleteEventConfirm =
      "Cette action est irréversible. L'événement disparaît du catalogue.";

  /// Règle serveur : un événement dont des places sont prises ne peut pas
  /// être supprimé.
  static String cannotDeleteWithReservations(int count) =>
      'Impossible de supprimer : $count participant${count > 1 ? 's ont' : ' a'} '
      'réservé. Modifiez l’événement, ou attendez que les places soient '
      'libérées.';
  static const deletePermanently = 'Supprimer définitivement';
  static const publish = 'Publier';
  static const save = 'Enregistrer';
  static const cancel = 'Annuler';
  static const delete = 'Supprimer';
  static const retry = 'Réessayer';
  static const noOrganizerEventsTitle = 'Aucun événement';
  static const noOrganizerEvents =
      "Prêt à organiser quelque chose d'exceptionnel ? Créez votre premier "
      'événement et ouvrez les réservations.';
  static const participants = 'Participants';
  static const noParticipants = 'Aucune réservation pour cet événement.';
  static const booked = 'Réservés';
  static const remaining = 'Restantes';
  static const searchParticipants = 'Rechercher par nom ou email';
  static const live = 'En ligne';
  static const eventLive = 'Événement publié !';
  static const eventLiveHint =
      'Votre événement est en ligne. Il apparaît dès maintenant dans le '
      'catalogue des participants.';
  static const viewDashboard = 'Voir mes événements';
  static const eventUpdated = 'Événement mis à jour.';
  static const eventDeleted = 'Événement supprimé.';

  // Reservations
  static const reserve = 'Réserver ma place';
  static const grabLast = 'Réserver les dernières places';
  static const reserved = 'Réservé';
  static const yourTicket = 'Votre billet';
  static const standardSeat = 'Place standard';
  static const generalAccess = 'Accès général';
  static const viewTicket = 'Voir mon billet';
  static const cancelReservation = 'Annuler ma réservation';
  static const cancelReservationTitle = 'Annuler la réservation ?';
  static const cancelReservationConfirm =
      'Votre place sera libérée et proposée aux autres participants.';
  static const reservationCancelled = 'Réservation annulée.';
  static const bookingConfirmed = 'Réservation confirmée !';
  static const bookingConfirmedHint =
      'Votre place est enregistrée. Préparez-vous à vivre une expérience '
      'inoubliable !';
  static const viewMyTickets = 'Voir mes billets';
  static const showMyTicket = 'Afficher mon billet';
  static const bookedShowTicket = 'Place réservée. Voici votre billet.';
  static const returnHome = "Retour à l'accueil";
  static const upcomingEvents = 'À venir';
  static const pastEvents = 'Passés';
  static const noTicketsTitle = 'Aucun billet';
  static const noTickets =
      "Vous n'avez encore réservé aucun événement. Explorez les événements "
      'autour de vous et lancez-vous !';
  static const statusConfirmed = 'Confirmée';
  static const statusCancelled = 'Annulée';
  static const reservedOn = 'Réservé le';
  static const ticketNumber = 'Billet';

  // Profile
  static const role = 'Rôle';
  static const memberSince = 'Membre depuis';

  // Home sections
  static const goodMorning = 'Bonjour';
  static const goodEvening = 'Bonsoir';
  static const featured = 'À la une';
  static const featuredSubtitle = 'Sélection éditoriale de la semaine';
  static const thisWeek = 'Cette semaine';
  static const thisWeekSubtitle = 'Les 7 prochains jours';
  static const trending = 'Ça se remplit vite';
  static const trendingSubtitle = "Moins de places qu'il n'y paraît";
  static const allEvents = 'Tout le catalogue';
  static const seeAll = 'Tout voir';
  static const browseByCategory = 'Explorer par catégorie';

  // Search
  static const recentSearches = 'Recherches récentes';
  static const suggestions = 'Suggestions';
  static const sortBy = 'Trier par';
  static const sortDateAsc = 'Date (au plus tôt)';
  static const sortDateDesc = 'Date (au plus tard)';
  static const sortAvailability = 'Places disponibles';
  static const sortName = 'Ordre alphabétique';
  static const onlyAvailable = 'Masquer les événements complets';
  static const period = 'Période';
  static const periodAny = 'Peu importe';
  static const periodToday = "Aujourd'hui";
  static const periodWeek = 'Cette semaine';
  static const periodMonth = 'Ce mois-ci';
  static const applyFilters = 'Afficher les résultats';
  static const resetFilters = 'Réinitialiser';
  static const activeFilters = 'filtre(s) actif(s)';

  // Settings
  static const settings = 'Paramètres';
  static const appearance = 'Apparence';
  static const appearanceSubtitle = 'Thème clair, sombre ou automatique';
  static const account = 'Compte';
  static const notifications = 'Notifications';
  static const notificationsReminder = 'Rappel avant un événement';
  static const notificationsReminderHint =
      'Recevoir une alerte 24 h avant le début';
  static const notificationsBookings = 'Réservations sur mes événements';
  static const notificationsBookingsHint =
      'Une notification à chaque réservation ou annulation';
  static const notificationsNews = 'Nouveautés et recommandations';
  static const notificationsNewsHint =
      "Événements suggérés selon vos centres d'intérêt";
  static const support = 'Aide et informations';
  static const helpCenter = "Centre d'aide";
  static const privacy = 'Confidentialité';
  static const terms = "Conditions d'utilisation";
  static const about = 'À propos';
  static const version = 'Version';
  static const logoutTitle = 'Se déconnecter ?';
  static const logoutConfirm =
      'Vous devrez saisir à nouveau vos identifiants à la prochaine ouverture.';
  static const editProfile = 'Modifier mon profil';

  // Modifier le profil
  static const editProfileTitle = 'Votre identité.';
  static const editProfileLead =
      'Le nom qui apparaîtra sur vos prochains billets et événements.';
  static const profileUpdated = 'Profil mis à jour.';
  static const lockedFields = 'Non modifiables';
  static const lockedFieldsHint =
      "L'email sert d'identifiant et le rôle définit votre espace : ils sont "
      'fixés à la création du compte.';
  static const nameUnchanged = 'Aucun changement à enregistrer.';

  // Billet
  static const ticketTitle = 'Billet';
  static const ticketCode = 'Code billet';
  static const ticketHolder = 'Titulaire';
  static const ticketEntrance =
      "Présentez ce code à l'entrée. Montez la luminosité : le scan est plus "
      'rapide.';
  static const ticketCancelledNotice =
      "Ce billet a été annulé. Il ne donne plus accès à l'événement.";
  static const ticketPastNotice =
      'Événement terminé. Le billet est conservé pour mémoire.';
  static const ticketNotFound = 'Ce billet est introuvable.';
  static const viewEvent = "Voir l'événement";
  static const copyCode = 'Copier le code';
  static const codeCopied = 'Code billet copié.';

  // Partage
  static const shareTitle = "Partager l'événement";
  static const shareLead =
      'Le lien ouvre la fiche publique. Les réservations se font dans '
      "l'application.";
  static const publicLink = 'Lien public';
  static const copy = 'Copier';
  static const linkCopied = 'Lien copié dans le presse-papiers.';
  static const copyInvitation = 'Copier une invitation prête à envoyer';
  static const invitationCopied =
      "Invitation copiée — il n'y a plus qu'à la coller.";

  // Export
  static const exportGuestList = 'Exporter la liste';
  static const guestListCopied = 'Liste copiée au format CSV';

  // Organisateur — statistiques et alertes
  static const stats = 'Stats';
  static const statsTitle = 'Statistiques';
  static const statsSubtitle = 'Vos jauges et vos réservations, en direct.';
  static const alerts = 'Alertes';
  static const alertsTitle = 'Alertes';
  static const alertsSubtitle = 'Ce qui bouge sur vos événements.';
  static const watchlist = 'À surveiller';
  static const activity = 'Activité';
  static const noActivityTitle = 'Tout est calme';
  static const noActivity =
      "Rien de neuf pour l'instant. Chaque réservation et chaque annulation "
      'sur vos événements apparaîtra ici.';

  // Forgot password
  static const forgotPasswordTitle = 'Mot de passe oublié';
  static const forgotPasswordSubtitle =
      'Saisissez votre adresse email : nous vous envoyons un lien pour '
      'définir un nouveau mot de passe.';
  static const sendResetLink = 'Envoyer le lien';
  static const resetSentTitle = 'Email envoyé';
  static const resetSentHint =
      'Vérifiez votre boîte de réception, et le dossier spam si besoin.';
  static const backToLogin = 'Retour à la connexion';

  // Stats
  static const totalEvents = 'Événements';
  static const totalParticipants = 'Participants';
  static const fillRate = 'Remplissage';
  static const upcoming = 'À venir';
  static const share = 'Partager';
  static const addToCalendar = 'Ajouter au calendrier';
  static const aboutEvent = 'À propos';
  static const practicalInfo = 'Informations pratiques';

  // Auth — voix éditoriale
  static const signInTitle = 'Bon retour.';
  static const signInLead =
      'Connectez-vous pour retrouver vos billets et vos événements.';
  static const registerTitle = 'Créons votre compte.';
  static const registerLead =
      'Deux minutes, deux étapes. On commence par vous.';
  static const roleStepTitle = 'Comment allez-vous utiliser EventHub ?';
  static const roleStepLead =
      'Ce choix définit votre espace. Il est définitif, alors prenez une '
      'seconde.';
  static const stepIdentity = 'Vos informations';
  static const stepRole = 'Votre rôle';
  static const showPassword = 'Afficher';
  static const hidePassword = 'Masquer';
  static const capsLockOn = 'Majuscules verrouillées';
  static const passwordWeak = 'Trop court';
  static const passwordFair = 'Correct';
  static const passwordGood = 'Solide';
  static const passwordStrong = 'Excellent';
  static const legalNotice =
      "En créant un compte, vous acceptez les conditions d'utilisation et la "
      'politique de confidentialité.';

  // Favoris
  static const favorites = 'Favoris';
  static const myFavorites = 'Mes favoris';
  static const addFavorite = 'Ajouter aux favoris';
  static const removeFavorite = 'Retirer des favoris';
  static const noFavoritesTitle = 'Aucun favori';
  static const noFavorites =
      'Touchez le cœur d’un événement pour le retrouver ici, même quand vous '
      'n’avez pas encore réservé.';
  static const favoriteAdded = 'Ajouté à vos favoris.';
  static const favoriteRemoved = 'Retiré de vos favoris.';

  // Liste d'attente
  static const joinWaitlist = 'Rejoindre la liste d’attente';
  static const leaveWaitlist = 'Quitter la liste';
  static const onWaitlist = 'Vous êtes sur la liste d’attente';
  static const waitlistHint =
      'Vous recevrez une notification dès qu’une place se libère. Premier '
      'arrivé, premier servi.';
  static const waitlistJoined = 'Inscrit sur la liste d’attente.';
  static const waitlistLeft = 'Retiré de la liste d’attente.';
  static String waitlistCount(int n) =>
      '$n personne${n > 1 ? 's' : ''} en liste d’attente';

  // Avis
  static const reviews = 'Avis';
  static const leaveReview = 'Laisser un avis';
  static const editReview = 'Modifier mon avis';
  static const yourReview = 'Votre avis';
  static const ratingLabel = 'Note';
  static const commentHint = 'Ce qui vous a plu, ce qui pourrait changer…';
  static const publishReview = 'Publier l’avis';
  static const reviewPublished = 'Merci pour votre avis.';
  static const reviewDeleted = 'Avis supprimé.';
  static const deleteReview = 'Supprimer mon avis';
  static const noReviews = 'Pas encore d’avis sur cet événement.';
  static String reviewsCount(int n) => '$n avis';

  // Contrôle des billets
  static const scanTickets = 'Scanner les billets';
  static const checkInTitle = 'Contrôle à l’entrée';
  static const admitted = 'Entrée validée';
  static String alreadyCheckedIn(String time) => 'Déjà scanné à $time';
  static const ticketCancelledAtDoor = 'Billet annulé';
  static const ticketWrongEvent = 'Billet d’un autre événement';
  static const ticketInvalidCode = 'Code invalide';
  static const ticketUnknown = 'Billet introuvable';
  static const notATicket = 'Ce QR code n’est pas un billet EventHub.';
  static const manualEntry = 'Saisir un code';
  static const manualEntryHint = 'EH-XXXX-XXXX';
  static const checkCode = 'Vérifier';
  static String checkedInCount(int n, int total) => '$n / $total entrés';
  static const cameraUnavailable =
      'Caméra indisponible. Autorisez l’accès à la caméra dans les réglages, '
      'ou saisissez le code du billet.';
  static const scanNext = 'Scanner le suivant';
  static const checkedIn = 'Entré';
  static const scanHint = 'Placez le QR code du billet dans le cadre.';
  static const torch = 'Lampe';
  static const deletedEvent = 'Événement supprimé';
  static String seeAllReviews(int n) => 'Voir les $n avis';

  // Catalogue, hors ligne, mesure d'audience
  static const loadMoreEvents = 'Charger plus d’événements';
  static const offlineBanner =
      'Hors ligne · vos actions seront envoyées au retour du réseau.';
  static const consentTitle = 'Aidez-nous à améliorer EventHub';
  static const consentBody =
      'Acceptez-vous une mesure d’audience de l’application ?';
  static const consentDetails =
      'Nous mesurons les écrans consultés et quelques actions (réservation, '
      'favori, avis) avec Firebase Analytics, rattachés à un identifiant '
      'technique — jamais à votre nom ni à votre email. Rien n’est vendu ni '
      'utilisé pour de la publicité. Vous pouvez changer d’avis à tout moment '
      'dans les Paramètres.';
  static const consentAccept = 'Accepter';
  static const consentRefuse = 'Refuser';
  static const analyticsSetting = 'Mesure d’audience';
  static const analyticsSettingHint =
      'Écrans consultés et actions clés, sans nom ni email';

  // Centre de notifications
  static const notificationsTitle = 'Notifications';
  static const markAllRead = 'Tout lire';
  static const noNotificationsTitle = 'Aucune notification';
  static const noNotifications =
      'Les réservations, annulations et rappels apparaîtront ici. Ils sont '
      'conservés 30 jours.';
  static const notificationDeleted = 'Notification supprimée.';

  // Connexion Google
  static const continueWithGoogle = 'Continuer avec Google';
  static const googleSigningIn = 'Connexion Google…';

  // Vérification d'email
  static const verifyEmailTitle = 'Confirmez votre adresse email';
  static String verifyEmailForOrganizer(String email) =>
      'Pour publier vos événements, confirmez $email. Nous vous envoyons un '
      'lien.';
  static String verifyEmailForReview(String email) =>
      'Pour publier un avis, confirmez d’abord $email. Nous vous envoyons un '
      'lien.';
  static String verifyEmailSentBody(String email) =>
      'Lien envoyé à $email. Ouvrez-le depuis votre messagerie, puis revenez '
      'ici.';
  static const sendVerificationLink = 'Envoyer le lien';
  static const alreadyVerified = 'Déjà confirmée';
  static const resendVerification = 'Renvoyer le lien';
  static const iVerifiedEmail = 'C’est fait';
  static const verificationSent = 'Lien de vérification envoyé.';
  static String welcomeEmailSent(String email) =>
      'Bienvenue ! Un email de confirmation d’inscription part vers $email.';
  static const roleRequired =
      'Dites-nous comment vous utiliserez EventHub : participant ou '
      'organisateur.';
  static const roleSignUpTitle = 'Vous êtes';
  static const roleOrganizerNote =
      'Votre espace organisateur est ouvert dès l’inscription. Nous vous '
      'demanderons de confirmer votre adresse au moment de publier votre '
      'premier événement.';
  static const stillNotVerified =
      'Adresse pas encore confirmée. Ouvrez le lien reçu par email, puis '
      'réessayez.';
  static const emailVerified = 'Adresse email confirmée.';
  static const emailNotVerifiedForEvent =
      'Confirmez votre adresse email avant de publier un événement : le lien '
      'est dans votre boîte de réception.';

  // Suppression de compte
  static const dangerZone = 'Zone sensible';
  static const deleteAccount = 'Supprimer mon compte';
  static const deleteAccountTitle = 'Supprimer définitivement le compte ?';
  static const deleteAccountBody =
      'Votre profil, vos appareils et vos préférences sont effacés. Vos '
      'réservations à venir sont annulées et leurs places libérées. Cette '
      'action est irréversible.';
  static const deleteAccountPasswordLead =
      'Saisissez votre mot de passe pour confirmer.';
  static const deleteAccountGoogleLead =
      'Vous allez confirmer avec votre compte Google.';
  static const deletingAccount = 'Suppression…';
  static const accountDeleted = 'Votre compte a été supprimé.';

  // Changement de mot de passe
  static const changePassword = 'Changer le mot de passe';
  static const changePasswordTitle = 'Nouveau mot de passe.';
  static const recoveryPasswordTitle = 'Choisissez un mot de passe.';
  static const recoveryPasswordLead =
      'Le lien reçu par email confirme que c’est bien vous : il ne reste qu’à '
      'choisir le nouveau mot de passe.';
  static const changePasswordLead =
      'Saisissez votre mot de passe actuel, puis celui que vous souhaitez '
      'utiliser désormais.';
  static const currentPassword = 'Mot de passe actuel';
  static const newPassword = 'Nouveau mot de passe';
  static const confirmPassword = 'Confirmer le nouveau mot de passe';
  static const passwordMismatch =
      'Les deux mots de passe ne correspondent pas.';
  static const passwordSameAsOld =
      "Le nouveau mot de passe doit être différent de l'ancien.";
  static const passwordChanged = 'Mot de passe mis à jour.';
  static const forgotPasswordLead =
      'Indiquez votre adresse : nous vous envoyons un lien pour en définir un '
      'nouveau.';

  // Splash
  static const splashTagline = 'Vivez chaque instant';
  static const splashLoading = 'Préparation de vos événements…';
  static const continueWith = 'ou continuer avec';
  static const rememberMe = 'Se souvenir de moi';
  static const acceptTerms =
      "J'accepte les conditions d'utilisation et la "
      'politique de confidentialité';
  static const acceptTermsRequired =
      'Vous devez accepter les conditions pour créer un compte.';

  // Generic
  static const loading = 'Chargement…';
  static const errorGeneric = 'Une erreur est survenue.';
  static const connectionLost = 'Connexion perdue';
  static const confirm = 'Confirmer';

  // Profil organisateur public (F-10)
  static const organizerProfileTitle = 'Organisateur';
  static const organizerNotFoundTitle = 'Profil indisponible';
  static const organizerNotFound =
      "Ce compte n'organise plus d'événements sur EventHub, ou il a été "
      'supprimé.';
  static const organizerNoBio = 'Pas encore de présentation.';
  static String organizerSince(String date) => 'Sur EventHub depuis le $date';
  static const followAction = 'Suivre';
  static const followingState = 'Abonné';
  static const followHint =
      'Une notification à chaque nouvel événement publié. Désabonnement en '
      'un geste.';
  static const followingHint =
      'Vous êtes prévenu de ses nouveaux événements. Touchez « Abonné » pour '
      'vous désabonner.';
  static String followersLabel(int n) => n > 1 ? 'abonnés' : 'abonné';
  static String eventsLabel(int n) => n > 1 ? 'événements' : 'événement';
  static const noRatingYet = 'pas encore d’avis';
  static String ratingCountLabel(int n) => n > 1 ? 'sur $n avis' : 'sur 1 avis';
  static const upcomingEventsTitle = 'À venir';
  static const pastEventsTitle = 'Déjà passés';
  static const noUpcomingForOrganizer =
      'Aucune date annoncée pour le moment. Abonnez-vous pour être prévenu '
      'de la prochaine.';
  static const noUpcomingForSelf =
      'Aucun événement à venir. Ceux que vous publierez apparaîtront ici.';
  static const editPublicProfile = 'Modifier ma présentation';
  static const publicProfile = 'Mon profil public';
  static const seeOrganizerProfile = 'Voir le profil';
  static const followingTitle = 'Organisateurs suivis';
  static const noFollowingTitle = 'Aucun abonnement';
  static const noFollowing =
      "Sur la fiche d'un événement, touchez le nom de l'organisateur puis "
      '« Suivre » : ses prochaines dates vous seront notifiées.';
  static const deletedOrganizer = 'Organisateur supprimé';
  static const bioLabel = 'Présentation';
  static const bioHint =
      'Ce que vous organisez, pour qui, où. Visible sur votre profil public.';
  static const bioTooLong = '500 caractères maximum.';
  static const publicProfileSection = 'Profil public';
  static const publicProfileHelp =
      'Votre nom et cette présentation sont visibles par les utilisateurs '
      'connectés. Votre email ne l’est jamais.';

  // Notifications — organisateurs suivis
  static const notificationsFollowed = 'Nouveaux événements';
  static const notificationsFollowedHint =
      'Quand un organisateur que vous suivez publie une date.';

  // Signalement (F-19)
  static const reportAction = 'Signaler';
  static const reportTitle = 'Signaler';
  static const reportLead =
      'Le signalement est anonyme : la personne concernée ne saura pas qui '
      "l'a envoyé. Un avis signalé par plusieurs personnes est masqué en "
      'attendant la vérification.';
  static const reportReasonLabel = 'Motif';
  static const reportDetails = 'Précisions';
  static const reportDetailsHint = 'Ce qui vous a alerté, en quelques mots.';
  static const reportSend = 'Envoyer le signalement';
  static const reportSending = 'Envoi…';
  static const reportSent =
      'Merci. Le signalement a été transmis à la modération.';
  static const reviewHiddenNotice =
      'Votre avis est masqué le temps d’une vérification par la modération.';

  // Partage et export (F-08, F-15)
  static const shareNative = 'Partager…';
  static const exportCsvFile = 'Exporter le CSV';
  static const copyCsv = 'Copier le CSV dans le presse-papiers';

  // Administration — modération
  static const moderationTitle = 'Modération';
  static const moderationOpen = 'À traiter';
  static const moderationClosed = 'Traités';
  static const moderationAll = 'Tout';
  static const moderationNothingOpenTitle = 'Rien à traiter';
  static const moderationNothingOpen =
      'Les nouveaux signalements apparaîtront ici, les plus signalés en '
      'premier.';
  static const moderationNothingClosedTitle = 'Aucun dossier traité';
  static const moderationNothingClosed =
      'Les décisions prises apparaîtront ici, les plus récentes en premier.';
  static String reportsCount(int n) =>
      n > 1 ? '$n signalements' : '$n signalement';
  static const moderationEntryTitle = 'Dossier de modération';
  static const moderationEntryNotFound = 'Ce dossier n’existe plus.';
  static const reportedContent = 'Contenu signalé';
  static const reportsSection = 'Signalements';
  static const decisionsSection = 'Décisions';
  static const noDecisionYet = 'Aucune décision pour le moment.';
  static const lastReason = 'Dernier motif';
  static const unknownReason = 'Motif inconnu';
  static const hiddenBadge = 'Masqué';
  static const suspendedBadge = 'Suspendu';
  static const deletedContent = 'Contenu supprimé depuis le signalement.';
  static const emptyComment = 'Note sans commentaire.';
  static const seatsBookedSuffix = 'places réservées';
  static const openOrganizerProfile = 'Voir le profil public';
  static const statusOpen = 'À traiter';
  static const statusResolved = 'Décidé';
  static const statusDismissed = 'Classé';
  static String reporterLabel(String key) => 'Compte ·$key';
  static const decisionNote = 'Note (facultative)';
  static const decisionNoteRequired = 'Note (obligatoire)';
  static const decisionNoteHint =
      'Transmise à la personne concernée et gardée dans l’historique.';
  static const decisionSending = 'Enregistrement…';
  static const decisionSaved = 'Décision enregistrée.';
  static String eventRemovedToast(int n) =>
      'Événement retiré · $n réservation${n > 1 ? 's' : ''} '
      'annulée${n > 1 ? 's' : ''}.';

  // Administration — rôles
  static const adminRolesTitle = 'Administrateurs';
  static const adminRolesLead =
      'Un administrateur voit les signalements et décide : masquer un avis, '
      'retirer un événement, suspendre un compte. Le rôle ne s’accorde pas '
      'depuis l’application : aucun compte, même administrateur, ne peut en '
      'créer un autre. C’est ce qui empêche une session volée de s’octroyer '
      'la modération.';
  static String adminSince(String date) => 'Administrateur depuis le $date';
  static const adminGrantTitle = 'Accorder ou retirer le rôle';
  static const adminGrantSteps =
      'Console Firebase → Firestore Database → collection « admins ».\n'
      '• Accorder : créer un document dont l’identifiant est l’UID du compte '
      '(Authentication → Users), avec les champs email et grantedAt.\n'
      '• Retirer : supprimer ce document.\n'
      'Le changement prend effet au prochain écran chargé, sans '
      'reconnexion.';
  static const you = 'Vous';
  static const participantRole = 'Participant';

  static const noEventInCategory = 'Aucun événement';

  // Photo de profil et couverture
  static const profilePhoto = 'Photo de profil';
  static const profileCover = 'Photo de couverture';
  static const changePhoto = 'Changer la photo';
  static const addPhoto = 'Ajouter une photo';
  static const removePhoto = 'Retirer la photo';
  static const changeCover = 'Changer la couverture';
  static const addCover = 'Ajouter une couverture';
  static const removeCover = 'Retirer la couverture';
  static const photoFromGallery = 'Choisir dans la galerie';
  static const photoFromCamera = 'Prendre une photo';
  static const photoUpdated = 'Photo mise à jour.';
  static const coverUpdated = 'Couverture mise à jour.';
  static const photoRemoved = 'Photo retirée.';
  static const photoHelp =
      'L’image est compressée sur l’appareil puis envoyée tout de suite ; elle '
      'n’apparaît sur votre profil qu’une fois celui-ci enregistré.';
  static const imageUploadUnavailable =
      'L’import d’images n’est pas disponible sur cette version de '
      'l’application.';
  static const imageUploading = 'Envoi de l’image…';
  static const waitForImageUpload =
      'Patientez : l’image est encore en cours d’envoi.';

  // Co-organisateurs (F-16)
  static const teamTitle = 'Équipe';
  static const teamLead =
      'Les co-organisateurs modifient l’événement, consultent la liste des '
      'participants et scannent les billets. Seul l’organisateur principal '
      'compose l’équipe et peut supprimer l’événement.';
  static const inviteCoOrganizer = 'Inviter un co-organisateur';
  static const coOrganizerEmailHint = 'email d’un compte organisateur';
  static String teamSeatsLeft(int n) =>
      '$n place${n > 1 ? 's' : ''} libre${n > 1 ? 's' : ''} dans l’équipe.';
  static const teamFull = 'Équipe complète : 10 co-organisateurs au plus.';
  static const sendInvitation = 'Envoyer l’invitation';
  static String invitationSent(String email) => 'Invitation envoyée à $email.';
  static const teamMembers = 'Membres';
  static const teamOwner = 'Principal';
  static const pendingInvitations = 'Invitations en attente';
  static const removeMember = 'Retirer';
  static const removeMemberTitle = 'Retirer de l’équipe ?';
  static const removeMemberMessage =
      'Cette personne n’aura plus accès à la liste des participants ni au '
      'contrôle des billets. Elle en sera prévenue.';
  static const memberRemoved = 'Membre retiré de l’équipe.';
  static const cancelInvitation = 'Annuler';
  static const cancelInvitationTitle = 'Annuler l’invitation ?';
  static const cancelInvitationMessage =
      'L’invitation ne pourra plus être acceptée.';
  static const invitationCancelled = 'Invitation annulée.';
  static const leaveTeam = 'Quitter l’équipe';
  static const leaveTeamTitle = 'Quitter l’équipe ?';
  static const leaveTeamMessage =
      'Vous n’aurez plus accès à cet événement. L’organisateur principal '
      'pourra vous inviter de nouveau.';
  static const teamLeft = 'Vous avez quitté l’équipe.';
  static const coOrganizedBadge = 'Co-organisé';
  static const coOrganizedTitle = 'Co-organisés';
  static String coOrganizedSubtitle(int n) =>
      '$n événement${n > 1 ? 's' : ''} où vous faites partie de l’équipe';
  static const invitationsTitle = 'Invitations';
  static const noInvitationsTitle = 'Aucune invitation';
  static const noInvitations =
      'Quand un organisateur vous invitera à co-organiser un événement, '
      'l’invitation apparaîtra ici.';
  static String invitedBy(String name) => 'Invitation de $name';
  static const coOrganizerRights =
      'En acceptant, vous pourrez modifier l’événement, voir les participants '
      'et scanner les billets à l’entrée.';
  static const accept = 'Accepter';
  static const decline = 'Refuser';
  static String invitationAccepted(String title) =>
      'Vous co-organisez « $title ».';
  static const invitationDeclined = 'Invitation refusée.';
  static String pendingInvitationsBanner(int n) =>
      n > 1 ? '$n invitations à co-organiser' : '1 invitation à co-organiser';

  // Types de billets et paiement (F-12, F-11)
  static const ticketTypes = 'Billets';
  static const ticketTypesToggle = 'Plusieurs types de billets';
  static const ticketTypesToggleHint =
      'Standard, étudiant, VIP… gratuits ou payants, chacun avec ses places.';
  static const addTicketType = 'Ajouter un type de billet';
  static const ticketTypeNameHint = 'Nom, ex. Standard';
  static const ticketTypeDescriptionHint = 'Ce que ce billet comprend';
  static const ticketTypePrice = 'Prix (0 = gratuit)';
  static const ticketTypeCapacity = 'Places';
  static const removeTicketType = 'Retirer ce type de billet';
  static const currencyLabel = 'Devise des billets payants';
  static const ticketTypesRequired = 'Ajoutez au moins un type de billet.';
  static const ticketTypesEditHint =
      'Un type déjà vendu ne peut ni être supprimé, ni descendre sous le '
      'nombre de billets vendus.';
  static const invalidPrice = 'Prix invalide.';
  static const freeOrPaid = 'Gratuit ou payant';
  static String fromPrice(String price) => 'Dès $price';
  static const chooseTicket = 'Choisir un billet';
  static const chooseTicketLead =
      'Un billet par personne. Seuls les billets gratuits se réservent pour '
      'l’instant : le paiement en ligne arrive bientôt.';
  static String seatsLeftShort(int n) => n > 1 ? '$n restantes' : '1 restante';
  static const tierSoldOut = 'Complet';
  static String payAmount(String price) => 'Payer $price';
  static const paidTicketUnavailable = 'Paiement en ligne bientôt disponible';
  static const bookFree = 'Réserver gratuitement';
  static const paymentTitle = 'Paiement';
  static const paymentPendingTitle = 'Paiement en cours';
  static String paymentPendingLead(String time) =>
      'Votre place est retenue jusqu’à $time. Terminez le paiement sur la '
      'page Stripe : le billet apparaît ici dès la confirmation.';
  static const resumePayment = 'Reprendre le paiement';
  static const cancelPurchase = 'Annuler l’achat';
  static const cancelPurchaseTitle = 'Annuler l’achat ?';
  static const cancelPurchaseMessage =
      'La place retenue est remise en vente. Rien n’est débité si le paiement '
      'n’était pas terminé.';
  static const purchaseCancelled = 'Achat annulé, place libérée.';
  static const paymentConfirmedTitle = 'Paiement confirmé';
  static const paymentConfirmedLead =
      'Votre billet est prêt, avec son QR code.';
  static const paymentExpiredTitle = 'Place libérée';
  static const paymentExpiredLead =
      'Le paiement n’a pas été finalisé à temps : la place a été remise en '
      'vente. Aucun montant n’a été débité.';
  static const paymentRefundedTitle = 'Billet remboursé';
  static const paymentRefundedLead =
      'Le remboursement apparaît sous 5 à 10 jours ouvrés sur votre relevé.';
  static const openPaymentFailed =
      'Impossible d’ouvrir la page de paiement. Réessayez depuis cet écran.';
  static const refundTicket = 'Annuler et être remboursé';
  static const refundTitle = 'Annuler et être remboursé ?';
  static String refundMessage(String price) =>
      'Votre billet sera annulé et $price vous seront remboursés sur la carte '
      'utilisée. La place sera remise en vente.';
  static const refunded = 'Billet annulé, remboursement en cours.';
  static const ticketPendingNotice =
      'Paiement non finalisé : ce billet n’est pas encore valable.';
  static const ticketUnpaidAtDoor = 'Paiement non finalisé';
  static const amountPaid = 'Montant payé';
  static const revenueLabel = 'Recettes';
  static const revenueNote = 'billets payés en cours, remboursements déduits';
  static const paymentInProgress = 'Paiement en cours';
  static const backToEvent = 'Retour à l’événement';

  // Recommandations (F-18)
  static const forYou = 'Pour vous';
  static const forYouSubtitle =
      'D’après vos billets, vos favoris et les organisateurs que vous suivez';
}
