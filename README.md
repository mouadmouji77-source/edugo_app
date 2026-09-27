# 📚 EduGo - Application Éducative Intelligente

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

**Une application Flutter moderne pour l'apprentissage assisté par IA**

[Fonctionnalités](#-fonctionnalités) • [Installation](#-installation) • [Architecture](#-architecture) • [Documentation](#-documentation)

</div>

---

## 🎯 Vue d'ensemble

**EduGo** est une application mobile éducative complète qui utilise l'intelligence artificielle pour aider les étudiants à apprendre plus efficacement. L'application permet de générer des résumés, des quiz, des examens et des cartes mentales à partir de contenu éducatif.

### ✨ Fonctionnalités principales

- 🤖 **Génération de résumés IA** - Créez des résumés intelligents à partir de vos cours
- ❓ **Quiz interactifs** - Générez et passez des quiz pour tester vos connaissances
- 📝 **Générateur d'examens** - Créez des examens professionnels avec différents types de questions
- 🗺️ **Cartes mentales** - Visualisez vos cours sous forme de mind maps interactives
- 📄 **Extraction PDF** - Uploadez des PDFs et extrayez automatiquement le contenu
- 🔊 **Text-to-Speech** - Écoutez vos résumés avec la synthèse vocale
- 💾 **Sauvegarde locale** - Accédez à vos contenus même hors ligne
- 🔐 **Authentification Firebase** - Sécurité et synchronisation cloud
- 📊 **Dashboard** - Suivez vos statistiques et activités
- 🌐 **Multilingue** - Support FR/EN avec détection automatique de langue

---

## 🏗️ Architecture

Le projet suit une **architecture Feature-First** avec une séparation claire des responsabilités :

```
lib/
├── core/              # Infrastructure partagée
│   ├── models/        # Modèles de données
│   ├── router/        # Navigation (GoRouter)
│   ├── theme/         # Thèmes clair/sombre
│   └── widgets/       # Widgets réutilisables
├── features/          # Modules fonctionnels
│   ├── auth/          # Authentification
│   ├── summary/       # Résumés
│   ├── quiz/          # Quiz
│   ├── exam_generator/# Examens
│   ├── mindmap/       # Cartes mentales
│   └── ...
└── services/          # Services métier
    ├── ai_service.dart
    ├── firebase_service.dart
    └── ...
```

### Technologies utilisées

- **Flutter 3.22+** - Framework UI
- **Riverpod 3.0** - State management
- **GoRouter** - Navigation déclarative
- **Firebase** - Backend (Auth, Firestore, Storage, Functions)
- **Groq AI** - Génération de contenu IA
- **SQLite** - Base de données locale
- **Material Design 3** - Design system

---

## 🚀 Installation

### Prérequis

- Flutter SDK 3.22 ou supérieur
- Dart 3.6 ou supérieur
- Android Studio / Xcode (pour le développement mobile)
- Compte Firebase
- Clé API Groq ([obtenir ici](https://console.groq.com/))

### Étapes d'installation

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/ABDELFATTAHBEZZAZ/edugo_app.git
   cd edugo_app
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer les clés API**
   ```bash
   # Copier le fichier d'exemple
   cp lib/config/api_keys.dart.example lib/config/api_keys.dart
   
   # Éditer api_keys.dart et ajouter votre clé Groq
   ```

4. **Configurer Firebase**
   - Téléchargez `google-services.json` depuis la console Firebase
   - Placez-le dans `android/app/google-services.json`
   - Pour iOS, placez `GoogleService-Info.plist` dans `ios/Runner/`

5. **Installer les dépendances Firebase Functions**
   ```bash
   cd functions
   npm install
   cd ..
   ```

6. **Lancer l'application**
   ```bash
   flutter run
   ```

### Configuration des Firebase Functions (Backend)

Les fonctions Firebase sont nécessaires pour certaines fonctionnalités IA. Pour les configurer :

```bash
cd functions
npm install
firebase deploy --only functions
```

Pour le développement local avec émulateurs :

```bash
# Démarrer les émulateurs Firebase
firebase emulators:start

# L'application utilisera automatiquement les émulateurs en mode debug
```

---

## 📱 Génération d'APK

Pour générer un APK Android :

```bash
# APK Release complet
flutter build apk --release

# APK Split (plus petit, par architecture)
flutter build apk --split-per-abi --release
```

L'APK se trouve dans : `build/app/outputs/flutter-apk/`

**⚠️ Important** : Avant de générer l'APK pour production, modifiez `lib/services/ai_service.dart` pour utiliser l'URL de production des Firebase Functions.

Voir [BUILD_APK_QUICK.md](BUILD_APK_QUICK.md) pour plus de détails.

---

## 📖 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture détaillée du projet
- [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md) - Diagrammes d'architecture
- [BUILD_APK_QUICK.md](BUILD_APK_QUICK.md) - Guide de génération d'APK
- [GUIDE_LANCEMENT.md](GUIDE_LANCEMENT.md) - Guide de lancement
- [QUICK_START.md](QUICK_START.md) - Démarrage rapide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Résolution de problèmes

---

## 🎨 Captures d'écran

*(Ajoutez vos captures d'écran ici)*

---

## 🔧 Structure du projet

```
edugo_app/
├── lib/                    # Code source Dart
│   ├── core/              # Infrastructure
│   ├── features/          # Fonctionnalités
│   ├── services/          # Services métier
│   └── main.dart          # Point d'entrée
├── functions/             # Firebase Cloud Functions
│   ├── controllers/       # Contrôleurs
│   ├── services/          # Services backend
│   └── utils/             # Utilitaires
├── android/               # Configuration Android
├── ios/                   # Configuration iOS
├── web/                   # Configuration Web
└── assets/                # Ressources (images, etc.)
```

---

## 🧪 Tests

```bash
# Lancer les tests
flutter test

# Tests avec couverture
flutter test --coverage
```

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

## 👤 Auteur

**ABDELFATTAH BEZZAZ**

- GitHub: [@ABDELFATTAHBEZZAZ](https://github.com/ABDELFATTAHBEZZAZ)

---

## 🙏 Remerciements

- [Flutter](https://flutter.dev/) - Framework UI
- [Firebase](https://firebase.google.com/) - Backend as a Service
- [Groq](https://groq.com/) - API IA
- [Riverpod](https://riverpod.dev/) - State management
- [GoRouter](https://pub.dev/packages/go_router) - Navigation

---

## ⚠️ Notes importantes

- **Sécurité** : Ne commitez jamais `api_keys.dart` ou `google-services.json` sur GitHub
- **Backend** : Les Firebase Functions doivent être déployées pour la production
- **APK** : L'APK ne peut pas accéder à `localhost`, utilisez l'URL de production

---

<div align="center">

**Fait avec ❤️ en utilisant Flutter**

⭐ Si ce projet vous a aidé, n'hésitez pas à lui donner une étoile !

</div>
