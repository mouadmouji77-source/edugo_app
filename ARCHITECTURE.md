# Architecture du Projet EduGo

## 📐 Vue d'ensemble

**EduGo** est une application Flutter éducative utilisant une architecture **Feature-First** avec **Riverpod** pour la gestion d'état et **GoRouter** pour la navigation.

## 🏗️ Pattern Architectural

### **Feature-First Architecture (Clean Architecture simplifiée)**

Le projet suit une architecture modulaire basée sur les fonctionnalités (features), où chaque feature est autonome et contient sa propre logique de présentation.

```
lib/
├── core/           # Code partagé et infrastructure
├── features/       # Modules fonctionnels indépendants
├── services/       # Services métier et API
└── main.dart      # Point d'entrée
```

---

## 📁 Structure Détaillée

### **1. Core (`lib/core/`)**
Code partagé utilisé dans toute l'application.

#### **Models (`core/models/`)**
- `summary.dart` - Modèle de résumé
- `quiz.dart` - Modèle de quiz et questions
- `exam.dart` - Modèle d'examen
- `mindmap.dart` - Modèle de carte mentale
- `quiz_score.dart` - Modèle de score de quiz

#### **Router (`core/router/`)**
- `app_router.dart` - Configuration GoRouter avec :
  - Gestion de l'authentification (redirections)
  - Routes déclaratives
  - Navigation type-safe

#### **Theme (`core/theme/`)**
- `app_theme.dart` - Thèmes clair/sombre avec Material 3

#### **Localization (`core/localization/`)**
- `app_localizations.dart` - Support multilingue (FR/EN)

#### **Widgets (`core/widgets/`)**
- `adaptive_layout.dart` - Layout adaptatif (mobile/desktop)
- `custom_text_field.dart` - Champ de texte réutilisable
- `loading_overlay.dart` - Overlay de chargement

---

### **2. Features (`lib/features/`)**
Chaque feature est un module indépendant avec sa propre structure.

#### **Structure d'une Feature**
```
feature_name/
├── presentation/
│   ├── providers/      # Riverpod providers (state management)
│   ├── screens/        # Écrans de l'application
│   └── widgets/        # Widgets spécifiques à la feature
└── providers/          # Providers partagés (si nécessaire)
```

#### **Features Disponibles**

1. **Auth** - Authentification
   - Login/Register
   - Gestion du profil utilisateur
   - Providers: `auth_providers.dart`

2. **Dashboard** - Tableau de bord
   - Vue d'ensemble des activités
   - Widgets: stats, résumés récents, quiz récents

3. **Summary** - Résumés
   - Génération de résumés IA
   - Affichage et export PDF
   - Widgets: actions, contenu

4. **Quiz** - Quiz interactifs
   - Génération depuis résumés
   - Passage de quiz
   - Résultats et scores

5. **Exam Generator** - Générateur d'examens
   - Création d'examens professionnels
   - Prévisualisation et export PDF
   - Widget: `exam_preview.dart`

6. **MindMap** - Cartes mentales
   - Génération interactive
   - Édition et export
   - Widget: `mindmap_view.dart`

7. **PDF Upload** - Upload de PDF
   - Extraction de texte
   - Traitement automatique

8. **Course Input** - Saisie de cours
   - Saisie manuelle de texte
   - Génération de résumés

9. **History** - Historique
   - Consultation des activités passées

10. **Profile** - Profil utilisateur
    - Gestion du compte
    - Photo de profil

11. **Saved** - Sauvegardes
    - Résumés sauvegardés localement

---

### **3. Services (`lib/services/`)**
Services métier et intégrations externes.

#### **AiService** (`ai_service.dart`)
- Génération de résumés
- Extraction de mots-clés
- Génération de quiz
- Génération d'examens
- Génération de mind maps
- Extraction de texte PDF
- **Backend**: Firebase Cloud Functions

#### **FirebaseService** (`firebase_service.dart`)
- Authentification (Firebase Auth)
- Base de données (Cloud Firestore)
- Stockage (Firebase Storage)
- Collections: users, summaries, quizzes, scores, exams, mindmaps

#### **LocalDatabaseService** (`local_database_service.dart`)
- Base de données locale (SQLite)
- Sauvegarde offline
- Tables: saved_summaries, saved_quizzes

#### **TTSService** (`tts_service.dart`)
- Text-to-Speech (Web Speech API)
- Support multilingue (FR/EN/AR)

---

## 🔄 Flux de Données

### **State Management avec Riverpod**

```
Screen → Provider → Controller → Service → API/Database
         ↓
      State Update
         ↓
      UI Rebuild
```

#### **Types de Providers utilisés**
- `StreamProvider` - Pour les données Firebase (temps réel)
- `Provider` - Pour les dépendances et controllers
- `NotifierProvider` - Pour l'état local complexe

#### **Exemple de Flux**
```dart
// 1. Provider expose le stream
final summaryProvider = StreamProvider.family<Summary?, String>((ref, id) {
  return FirebaseService.summaries.doc(id).snapshots()...
});

// 2. Controller gère la logique métier
final summaryControllerProvider = Provider<SummaryController>((ref) {
  return SummaryController(ref);
});

// 3. Screen consomme le provider
class SummaryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider(summaryId));
    // ...
  }
}
```

---

## 🧭 Navigation

### **GoRouter Configuration**

- **Routes déclaratives** dans `app_router.dart`
- **Redirections automatiques** basées sur l'authentification
- **Paramètres de route** (`:id`, query parameters)
- **Navigation type-safe**

#### **Routes Principales**
```
/login              → LoginScreen
/register           → RegisterScreen
/dashboard           → DashboardScreen
/course-input        → CourseInputScreen
/pdf-upload          → PdfUploadScreen
/summary/:id         → SummaryScreen
/quiz/:id            → QuizScreen
/quiz-result/:id     → QuizResultScreen
/exam-generator       → ExamGeneratorScreen
/exam/:id            → ExamDetailsScreen
/mindmap             → MindMapScreen
/mindmap/:id         → MindMapScreen
/history             → HistoryScreen
/profile             → ProfileScreen
/saved-summaries     → SavedSummariesScreen
```

---

## 🔐 Authentification

### **Flow d'Authentification**

1. **Login/Register** → Firebase Auth
2. **Création du profil** → Firestore (`users` collection)
3. **Redirection automatique** via GoRouter
4. **State global** via `authStateProvider`

### **Protection des Routes**
- Routes publiques: `/login`, `/register`
- Routes protégées: Toutes les autres
- Redirection automatique si non authentifié

---

## 💾 Persistance des Données

### **Firebase Firestore (Cloud)**
- Résumés, Quiz, Examens, MindMaps
- Synchronisation temps réel
- Collections par utilisateur (`uid`)

### **SQLite (Local)**
- Sauvegarde offline
- Résumés et quiz sauvegardés
- Synchronisation manuelle

---

## 🎨 UI/UX

### **Material Design 3**
- Thèmes clair/sombre
- Design system cohérent
- Google Fonts (Poppins, Inter)

### **Layout Adaptatif**
- Mobile: Bottom Navigation Bar
- Desktop/Tablette: Navigation Rail
- Widget: `AdaptiveLayout`

### **Internationalisation**
- Français (par défaut)
- Anglais
- Support RTL (arabe pour le contenu)

---

## 🔌 Intégrations Externes

### **Backend (Firebase Functions)**
- **Base URL**: `http://127.0.0.1:5001/edugo-a78a0/us-central1` (dev)
- **Endpoints**:
  - `/generateSummary`
  - `/generateQuiz`
  - `/extractKeywords`
  - `/extractPdfText`
  - `/generateMindMap`
  - `/generateExam`
  - `/textToSpeech`

### **APIs Utilisées**
- **Groq AI** - Génération de contenu IA
- **Firebase** - Backend as a Service
- **Web Speech API** - Text-to-Speech

---

## 📦 Dépendances Principales

### **State Management**
- `flutter_riverpod: ^3.0.3` - Gestion d'état

### **Navigation**
- `go_router: ^17.0.1` - Navigation déclarative

### **Firebase**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`

### **UI**
- `google_fonts` - Polices
- `flutter_quill` - Éditeur de texte riche
- `cached_network_image` - Images

### **PDF**
- `pdf`, `printing` - Génération et impression PDF

### **Local Storage**
- `sqflite` - Base de données SQLite

### **Autres**
- `uuid` - Génération d'IDs
- `http` - Requêtes HTTP
- `file_picker` - Sélection de fichiers

---

## 🎯 Principes de Conception

### **1. Séparation des Responsabilités**
- **Services** → Logique métier et API
- **Providers** → Gestion d'état
- **Screens** → Présentation
- **Widgets** → Composants réutilisables

### **2. Modularité**
- Features indépendantes
- Pas de couplage entre features
- Code partagé dans `core/`

### **3. Réutilisabilité**
- Widgets core réutilisables
- Services centralisés
- Models partagés

### **4. Testabilité**
- Controllers isolés
- Services mockables
- Providers testables

---

## 🚀 Points d'Entrée

### **main.dart**
```dart
1. Initialisation Firebase
2. ProviderScope (Riverpod)
3. EduGoApp (MaterialApp.router)
4. Configuration du router
```

---

## 📊 Diagramme de Flux

```
User Action
    ↓
Screen (UI)
    ↓
Provider (State)
    ↓
Controller (Logic)
    ↓
Service (API/Database)
    ↓
Backend/Storage
    ↓
Response
    ↓
State Update
    ↓
UI Rebuild
```

---

## 🔍 Bonnes Pratiques Appliquées

✅ **Feature-First Architecture** - Organisation par fonctionnalités  
✅ **Riverpod** - State management moderne et type-safe  
✅ **GoRouter** - Navigation déclarative  
✅ **Separation of Concerns** - Logique séparée de la présentation  
✅ **Reusable Components** - Widgets et services réutilisables  
✅ **Type Safety** - Utilisation de types Dart stricts  
✅ **Error Handling** - Gestion d'erreurs dans les services  
✅ **Offline Support** - Sauvegarde locale avec SQLite  
✅ **Internationalization** - Support multilingue  
✅ **Material Design 3** - Design moderne et cohérent  

---

## 📝 Notes Importantes

- **Backend**: Les fonctions Firebase sont dans `functions/index.js`
- **Local Development**: Utilise l'émulateur Firebase local
- **Production**: Utilise les Cloud Functions déployées
- **State**: Tous les états sont gérés via Riverpod
- **Navigation**: Toutes les navigations passent par GoRouter

---

*Dernière mise à jour: Après nettoyage du code (2025)*

