# 🔧 Guide de Dépannage - Erreur PDF Extraction

## ❌ Erreur : "Failed to fetch" lors de l'extraction PDF

### 🔍 Diagnostic

L'erreur `ClientException: Failed to fetch` indique que l'application Flutter ne peut pas se connecter aux Firebase Functions.

### ✅ Solution 1 : Vérifier que les Firebase Functions sont lancées

**Étape 1** : Ouvrir un terminal et aller à la racine du projet

**Étape 2** : Lancer les émulateurs Firebase
```bash
firebase emulators:start --only functions
```

**Étape 3** : Attendre de voir ce message :
```
✔  functions[us-central1-extractPdfText]: http function initialized
✔  All emulators ready!
```

**Étape 4** : Vérifier que le serveur écoute sur le port 5001
```bash
# Windows PowerShell
netstat -an | findstr "5001"

# Vous devriez voir quelque chose comme :
# TCP    127.0.0.1:5001         0.0.0.0:0              LISTENING
```

### ✅ Solution 2 : Utiliser le script de démarrage

Double-cliquez sur `start-emulators.bat` à la racine du projet.

### ✅ Solution 3 : Vérifier l'URL dans le code

Vérifiez que dans `lib/services/ai_service.dart`, l'URL est correcte :

```dart
// Pour développement local (émulateur)
static const String _baseUrl = 'http://127.0.0.1:5001/edugo-a78a0/us-central1';

// Pour production (Cloud Functions déployées)
// static const String _baseUrl = 'https://us-central1-edugo-a78a0.cloudfunctions.net';
```

**Important** : La première ligne doit être décommentée pour le développement local.

### ✅ Solution 4 : Tester manuellement l'endpoint

Ouvrez votre navigateur et allez à :
```
http://127.0.0.1:5001/edugo-a78a0/us-central1/extractPdfText
```

Si vous voyez une erreur (normal pour GET), c'est que le serveur fonctionne ! ✅

Si vous voyez "This site can't be reached", les fonctions ne sont pas lancées. ❌

### ✅ Solution 5 : Vérifier les dépendances

Assurez-vous que toutes les dépendances sont installées :

```bash
cd functions
npm install
```

### ✅ Solution 6 : Vérifier les logs Firebase

Si les fonctions sont lancées mais ne répondent pas, vérifiez les logs :

```bash
# Dans le terminal où les émulateurs tournent
# Vous devriez voir les logs des requêtes
```

### 🎯 Ordre de Lancement Correct

1. **D'abord** : Lancer les Firebase Functions
   ```bash
   firebase emulators:start --only functions
   ```

2. **Ensuite** : Lancer l'application Flutter
   ```bash
   flutter run
   ```

### 📝 Checklist

- [ ] Firebase Functions sont lancées (port 5001 en écoute)
- [ ] L'URL dans `ai_service.dart` pointe vers `http://127.0.0.1:5001/...`
- [ ] Les dépendances sont installées (`npm install` dans `functions/`)
- [ ] Aucun firewall ne bloque le port 5001
- [ ] L'application Flutter est lancée après les Functions

### 🐛 Autres Problèmes Possibles

#### Problème : Port déjà utilisé
**Solution** : Arrêter les autres processus utilisant le port 5001
```bash
# Windows
netstat -ano | findstr :5001
taskkill /PID <PID> /F
```

#### Problème : CORS Error
**Solution** : Le controller utilise déjà CORS, mais vérifiez que `cors` est bien installé :
```bash
cd functions
npm install cors
```

#### Problème : PDF trop volumineux
**Solution** : Les PDFs très volumineux peuvent causer des timeouts. Le code a maintenant un timeout de 60 secondes.

### 💡 Message d'Erreur Amélioré

Le code a été mis à jour pour afficher un message d'erreur plus clair :
- Si le serveur n'est pas accessible, vous verrez : "Network error: Unable to connect to the server. Please make sure Firebase Functions are running..."
- Si le timeout est dépassé, vous verrez : "Request timeout: PDF extraction took too long"

