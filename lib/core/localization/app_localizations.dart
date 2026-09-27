import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum for supported languages
enum AppLanguage { french, english }

// Provider for current language (uses Notifier for Riverpod 3.x)
final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(() {
  return LanguageNotifier();
});

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    return AppLanguage.french; // French by default
  }

  void toggleLanguage() {
    state = state == AppLanguage.french ? AppLanguage.english : AppLanguage.french;
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

// Provider to get translations
final translationsProvider = Provider<AppTranslations>((ref) {
  final lang = ref.watch(languageProvider);
  return AppTranslations(lang);
});

class AppTranslations {
  final AppLanguage currentLanguage;

  AppTranslations(this.currentLanguage);

  bool get isFrench => currentLanguage == AppLanguage.french;
  bool get isEnglish => currentLanguage == AppLanguage.english;

  String get locale => isFrench ? 'fr' : 'en';

  // ===== GENERAL =====
  String get appName => 'EduGo';
  String get loading => isFrench ? 'Chargement...' : 'Loading...';
  String get error => isFrench ? 'Erreur' : 'Error';
  String get cancel => isFrench ? 'Annuler' : 'Cancel';
  String get confirm => isFrench ? 'Confirmer' : 'Confirm';
  String get save => isFrench ? 'Enregistrer' : 'Save';
  String get delete => isFrench ? 'Supprimer' : 'Delete';
  String get edit => isFrench ? 'Modifier' : 'Edit';
  String get close => isFrench ? 'Fermer' : 'Close';
  String get yes => isFrench ? 'Oui' : 'Yes';
  String get no => isFrench ? 'Non' : 'No';

  // ===== NAVIGATION =====
  String get dashboard => isFrench ? 'Tableau de bord' : 'Dashboard';
  String get history => isFrench ? 'Historique' : 'History';
  String get profile => isFrench ? 'Profil' : 'Profile';
  String get settings => isFrench ? 'Paramètres' : 'Settings';

  // ===== AUTHENTICATION =====
  String get login => isFrench ? 'Connexion' : 'Login';
  String get logout => isFrench ? 'Déconnexion' : 'Logout';
  String get signUp => isFrench ? 'Inscription' : 'Sign Up';
  String get email => isFrench ? 'Email' : 'Email';
  String get password => isFrench ? 'Mot de passe' : 'Password';
  String get confirmPassword => isFrench ? 'Confirmer le mot de passe' : 'Confirm Password';
  String get firstName => isFrench ? 'Prénom' : 'First Name';
  String get lastName => isFrench ? 'Nom' : 'Last Name';
  String get forgotPassword => isFrench ? 'Mot de passe oublié ?' : 'Forgot Password?';
  String get resetPassword => isFrench ? 'Réinitialiser le mot de passe' : 'Reset Password';
  String get createAccount => isFrench ? 'Créer un compte' : 'Create Account';
  String get alreadyHaveAccount => isFrench ? 'Déjà un compte ?' : 'Already have an account?';
  String get noAccount => isFrench ? 'Pas de compte ?' : "Don't have an account?";
  String get signIn => isFrench ? 'Se connecter' : 'Sign In';
  String get signOut => isFrench ? 'Se déconnecter' : 'Sign Out';
  String get signOutConfirm => isFrench 
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?' 
      : 'Are you sure you want to sign out?';

  // ===== DASHBOARD =====
  String greeting(String name) => isFrench 
      ? 'Bonjour, $name 👋' 
      : 'Hello, $name 👋';
  String get welcomeBack => isFrench ? 'Bienvenue ! 👋' : 'Welcome! 👋';
  String get readyToLearn => isFrench 
      ? 'Prêt à apprendre quelque chose de nouveau ?' 
      : 'Ready to learn something new?';
  String get newSummary => isFrench ? 'Nouveau Résumé' : 'New Summary';
  String get createSummaryDesc => isFrench 
      ? 'Créez des résumés IA à partir de texte ou PDF' 
      : 'Create AI-powered summaries from text or PDF';
  String get examGenerator => isFrench ? 'Générateur d\'Examens' : 'Exam Generator';
  String get examGeneratorDesc => isFrench 
      ? 'Créez des examens professionnels à partir de vos PDF' 
      : 'Create professional exams from your course PDFs';
  String get mindmapGenerator => isFrench ? 'Générateur de MindMap' : 'MindMap Generator';
  String get mindmapGeneratorDesc => isFrench 
      ? 'Créez des cartes mentales interactives' 
      : 'Create interactive mind maps from your content';
  String get recentSummaries => isFrench ? 'Résumés Récents' : 'Recent Summaries';
  String get recentQuizzes => isFrench ? 'Quiz Récents' : 'Recent Quizzes';
  String get viewAll => isFrench ? 'Voir tout' : 'View All';

  // ===== PROFILE =====
  String get myProfile => isFrench ? 'Mon Profil' : 'My Profile';
  String get accountInfo => isFrench ? 'Informations du Compte' : 'Account Information';
  String get userId => isFrench ? 'ID Utilisateur' : 'User ID';
  String get emailVerified => isFrench ? 'Email Vérifié' : 'Email Verified';
  String get lastSignIn => isFrench ? 'Dernière Connexion' : 'Last Sign In';
  String get accountCreated => isFrench ? 'Compte Créé' : 'Account Created';
  String get security => isFrench ? 'Sécurité' : 'Security';
  String get resetPasswordDesc => isFrench 
      ? 'Recevoir un lien de réinitialisation par email' 
      : 'Receive a password reset link via email';
  String get activeMember => isFrench ? 'Membre Actif' : 'Active Member';
  String get notAvailable => isFrench ? 'Non disponible' : 'Not available';
  String get notSpecified => isFrench ? 'Non renseigné' : 'Not specified';
  String get profilePhotoUpdated => isFrench 
      ? 'Photo de profil mise à jour !' 
      : 'Profile photo updated!';
  String get aboutApp => isFrench ? 'À propos de EduGo' : 'About EduGo';
  String get version => isFrench ? 'Version' : 'Version';
  String get platform => isFrench ? 'Plateforme' : 'Platform';
  String get aiPowered => isFrench ? 'IA Utilisée' : 'AI Powered';

  // ===== LANGUAGE =====
  String get languageLabel => isFrench ? 'Langue' : 'Language';
  String get french => isFrench ? 'Français' : 'French';
  String get english => isFrench ? 'Anglais' : 'English';
  String get switchLanguage => isFrench ? 'Changer de langue' : 'Switch Language';

  // ===== SUMMARIES =====
  String get summary => isFrench ? 'Résumé' : 'Summary';
  String get summaries => isFrench ? 'Résumés' : 'Summaries';
  String get generateSummary => isFrench ? 'Générer un résumé' : 'Generate Summary';
  String get enterText => isFrench ? 'Entrez votre texte' : 'Enter your text';
  String get uploadPdf => isFrench ? 'Télécharger un PDF' : 'Upload PDF';
  String get writeManually => isFrench ? 'Écrire manuellement' : 'Write Manually';

  // ===== QUIZ =====
  String get quiz => isFrench ? 'Quiz' : 'Quiz';
  String get quizzes => isFrench ? 'Quiz' : 'Quizzes';
  String get startQuiz => isFrench ? 'Commencer le Quiz' : 'Start Quiz';
  String get score => isFrench ? 'Score' : 'Score';
  String get correct => isFrench ? 'Correct' : 'Correct';
  String get incorrect => isFrench ? 'Incorrect' : 'Incorrect';
  String get nextQuestion => isFrench ? 'Question Suivante' : 'Next Question';
  String get finishQuiz => isFrench ? 'Terminer le Quiz' : 'Finish Quiz';
  String get tryAgain => isFrench ? 'Réessayer' : 'Try Again';

  // ===== NOTIFICATIONS =====
  String get notifications => isFrench ? 'Notifications' : 'Notifications';
  String get noNotifications => isFrench ? 'Aucune notification' : 'No notifications';

  // ===== ERRORS =====
  String get errorOccurred => isFrench 
      ? 'Une erreur s\'est produite' 
      : 'An error occurred';
  String get tryAgainLater => isFrench 
      ? 'Veuillez réessayer plus tard' 
      : 'Please try again later';
  String get invalidEmail => isFrench 
      ? 'Email invalide' 
      : 'Invalid email';
  String get passwordTooShort => isFrench 
      ? 'Le mot de passe doit contenir au moins 6 caractères' 
      : 'Password must be at least 6 characters';
  String get passwordsDoNotMatch => isFrench 
      ? 'Les mots de passe ne correspondent pas' 
      : 'Passwords do not match';
  String get fieldRequired => isFrench 
      ? 'Ce champ est requis' 
      : 'This field is required';
  String get nameTooShort => isFrench 
      ? 'Le nom doit contenir au moins 2 caractères' 
      : 'Name must be at least 2 characters';

  // ===== DIALOGS =====
  String get howToAddContent => isFrench 
      ? 'Comment voulez-vous ajouter votre contenu ?' 
      : 'How would you like to add your content?';
  String get createNewSummary => isFrench 
      ? 'Créer un Nouveau Résumé' 
      : 'Create New Summary';
}
