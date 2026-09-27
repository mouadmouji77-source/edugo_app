import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get summaries => _firestore.collection('summaries');
  static CollectionReference get quizzes => _firestore.collection('quizzes');
  static CollectionReference get scores => _firestore.collection('scores');
  static CollectionReference get exams => _firestore.collection('exams');
  static CollectionReference get mindmaps => _firestore.collection('mindmaps');

  // Storage
  static Reference get storage => _storage.ref();

  // Auth Methods
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User Profile
  static Future<void> createUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await users.doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await users.doc(uid).get();
  }

  // Stream to listen to profile changes
  static Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return users.doc(uid).snapshots();
  }

  // Upload profile image
  static Future<String> uploadProfileImage(String uid, Uint8List imageBytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('profile_images').child('${uid}_$timestamp.jpg');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    final downloadUrl = await ref.getDownloadURL();
    
    await users.doc(uid).set({
      'photoUrl': downloadUrl,
    }, SetOptions(merge: true));
    
    return downloadUrl;
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    
    if (updates.isNotEmpty) {
      await users.doc(uid).update(updates);
    }
  }
}
