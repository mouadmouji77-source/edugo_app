# 🔧 Guide de Configuration - EduGo

Ce guide vous aidera à configurer correctement votre environnement de développement pour EduGo.

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ Flutter SDK 3.22+ installé
- ✅ Dart 3.6+ installé
- ✅ Un compte Firebase créé
- ✅ Un compte Groq avec une clé API
- ✅ Android Studio / Xcode (pour le développement mobile)

## 🔑 Configuration des Clés API

### 1. Clé API Groq

**⚠️ IMPORTANT : Ne commitez JAMAIS votre clé API sur GitHub !**

1. Obtenez votre clé API Groq sur [console.groq.com](https://console.groq.com/)
2. Copiez le fichier d'exemple :
   ```bash
   cp lib/config/api_keys.dart.example lib/config/api_keys.dart
   ```
3. Ouvrez `lib/config/api_keys.dart` et remplacez `VOTRE_CLE_GROQ_ICI` par votre vraie clé :
   ```dart
   static const String groqApiKey = 'VOTRE_CLE_GROQ_ICI';
   ```

Le fichier `api_keys.dart` est déjà dans `.gitignore` et ne sera pas commité.

## 🔥 Configuration Firebase

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Créez un nouveau projet ou utilisez un projet existant
3. Activez les services suivants :
   - **Authentication** (Email/Password)
   - **Cloud Firestore**
   - **Firebase Storage**
   - **Cloud Functions**

### 2. Configuration Android

1. Dans Firebase Console, ajoutez une application Android
2. Téléchargez `google-services.json`
3. Placez-le dans `android/app/google-services.json`

### 3. Configuration iOS (si nécessaire)

1. Dans Firebase Console, ajoutez une application iOS
2. Téléchargez `GoogleService-Info.plist`
3. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### 4. Configuration Firebase Functions

1. Installez Firebase CLI :
   ```bash
   npm install -g firebase-tools
   ```

2. Connectez-vous à Firebase :
   ```bash
   firebase login
   ```

3. Initialisez Firebase dans le projet :
   ```bash
   firebase init
   ```
   Sélectionnez :
   - Functions
   - Utilisez un projet existant ou créez-en un nouveau

4. Installez les dépendances :
   ```bash
   cd functions
   npm install
   cd ..
   ```

5. Déployez les fonctions (pour la production) :
   ```bash
   firebase deploy --only functions
   ```

### 5. Configuration des émulateurs (Développement local)

Pour développer localement avec les émulateurs Firebase :

1. Démarrez les émulateurs :
   ```bash
   firebase emulators:start
   ```

2. L'application utilisera automatiquement les émulateurs en mode debug.

## 🚀 Premier lancement

1. **Installer les dépendances Flutter** :
   ```bash
   flutter pub get
   ```

2. **Vérifier la configuration** :
   ```bash
   flutter doctor
   ```

3. **Lancer l'application** :
   ```bash
   flutter run
   ```

## 🔍 Vérification

Pour vérifier que tout est bien configuré :

- ✅ L'application se lance sans erreur
- ✅ Vous pouvez vous connecter/créer un compte
- ✅ La génération de résumés fonctionne
- ✅ Les données sont sauvegardées dans Firestore

## 🐛 Problèmes courants

### Erreur : "API key not found"
- Vérifiez que `api_keys.dart` existe et contient votre clé valide
- Vérifiez que la clé API Groq est active sur console.groq.com

### Erreur : "Firebase not initialized"
- Vérifiez que `google-services.json` est présent dans `android/app/`
- Vérifiez que Firebase est bien initialisé dans `main.dart`

### Erreur : "Functions not found"
- Vérifiez que les Firebase Functions sont déployées
- En développement, vérifiez que les émulateurs sont démarrés

## 📚 Ressources

- [Documentation Flutter](https://docs.flutter.dev/)
- [Documentation Firebase](https://firebase.google.com/docs)
- [Documentation Groq](https://console.groq.com/docs)
- [Guide d'architecture](ARCHITECTURE.md)

---

**Besoin d'aide ?** Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md) ou ouvrez une issue sur GitHub.

