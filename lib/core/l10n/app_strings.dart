/// French UI strings. Kept in one place so a future `flutter_localizations`
/// ARB migration is a mechanical find/replace.
abstract final class AppStrings {
  static const appName = 'EventHub';
  static const tagline = 'Premium experiences';

  // Onboarding
  static const skip = 'Passer';
  static const getStarted = 'Commencer';
  static const onboarding1Title = 'Découvrez les événements près de vous';
  static const onboarding1Body =
      'Concerts, conférences, meetups, ateliers : explorez un catalogue '
      'sélectionné et filtrez par catégorie.';
  static const onboarding2Title = 'Réservez en un geste';
  static const onboarding2Body =
      'Une place se réserve en un tap. Retrouvez vos billets et leur statut '
      'dans « Billets », en temps réel.';
  static const onboarding3Title = 'Organisez et suivez vos participants';
  static const onboarding3Body =
      'Publiez un événement, gérez sa capacité et consultez la liste des '
      'personnes inscrites.';

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
      'Cette action est irréversible. Toutes les réservations associées '
      'seront perdues.';
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
  static const comingSoon = 'Bientôt disponible';

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

  // Changement de mot de passe
  static const changePassword = 'Changer le mot de passe';
  static const changePasswordTitle = 'Nouveau mot de passe.';
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
}
