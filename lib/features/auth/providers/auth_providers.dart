import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';

// User profile model
/// Modèle représentant le profil public d'un utilisateur
class UserProfile {
  final String uid; // Identifiant unique Firebase
  final String firstName; // Prénom
  final String lastName; // Nom
  final String email; // Adresse email
  final String? photoUrl; // URL de la photo de profil (optionnel)
  final DateTime? createdAt; // Date d'inscription

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    this.createdAt,
  });

  /// Retourne le nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Crée un profil à partir d'un document Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfile(
      uid: doc.id,
      firstName: data?['firstName'] ?? '',
      lastName: data?['lastName'] ?? '',
      email: data?['email'] ?? '',
      photoUrl: data?['photoUrl'],
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Provider qui écoute les changements d'état de l'authentification (connecté/déconnecté)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.authStateChanges;
});

/// Provider qui expose l'utilisateur Firebase actuel
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user).value;
});

/// Provider qui récupère le profil complet de l'utilisateur depuis Firestore
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  return FirebaseService.getUserProfileStream(user.uid).map((doc) {
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  });
});

/// Provider pour accéder au contrôleur d'authentification
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

/// Contrôleur gérant la logique d'authentification
class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  /// Connexion avec email et mot de passe
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await FirebaseService.signInWithEmailAndPassword(email, password);
  }

  /// Création d'un nouveau compte utilisateur
  Future<void> createUserWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseService.createUserWithEmailAndPassword(email, password);
    
    if (credential.user != null) {
      // Création du profil dans Firestore après l'inscription
      await FirebaseService.createUserProfile(
        uid: credential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> signOut() async {
    await FirebaseService.signOut();
  }

  /// Envoi d'un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseService.sendPasswordResetEmail(email);
  }

  /// Upload d'une nouvelle photo de profil
  Future<String> uploadProfileImage(Uint8List imageBytes) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('Utilisateur non connecté');
    
    return await FirebaseService.uploadProfileImage(user.uid, imageBytes);
  }

  /// Mise à jour des informations du profil
  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('Utilisateur non connecté');
    
    await FirebaseService.updateUserProfile(
      uid: user.uid,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
