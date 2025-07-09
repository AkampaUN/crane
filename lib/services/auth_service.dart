import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final Logger _logger = Logger('AuthService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: UniversalPlatform.isWeb || UniversalPlatform.isDesktop
        ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
        : null,
    scopes: ['email'],
  );

   static void initializeLogging() {
    Logger.root.level = Level.ALL; // Set your desired log level
    Logger.root.onRecord.listen((record) {
      // You can customize how logs are displayed
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('StackTrace: ${record.stackTrace}');
      }
    });
  }


  // Email/password sign in (kept original functionality)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserExists(userCredential.user!);
      _logger.info('User signed in with email: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _logger.severe(
        'Email sign-in failed for $email',
        e,
        e.stackTrace,
      );
      rethrow;
    }
  }

  // Google sign in (kept original functionality)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _ensureUserExists(userCredential.user!);
      _logger.info('User signed in with Google: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e,stackTrace ) {
      _logger.severe(
        'Google sign-in failed',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Get current user (kept original functionality)
  User? get currentUser => _auth.currentUser;

  // New helper method to ensure user data exists in Firestore
  Future<void> _ensureUserExists(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': user.providerData.isNotEmpty 
              ? user.providerData[0].providerId 
              : 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
         _logger.finer('Updated last login for ${user.email}');
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to ensure user exists in Firestore',
        e,
        stackTrace,
      );
    }
  }

  // Optional: Add sign out functionality if needed
  Future<void> signOut() async {
    try{
    await _auth.signOut();
    await _googleSignIn.signOut();
    _logger.info('User signed out');
    } catch (e, stackTrace) {
      _logger.severe('Sign out failed', e, stackTrace);
      rethrow;
    }
  }

  // Optional: Add password reset functionality if needed
  Future<void> sendPasswordResetEmail(String email) async {
    try{
    await _auth.sendPasswordResetEmail(email: email);
  
   _logger.info('Password reset email sent to $email');
    } catch (e, stackTrace) {
      _logger.severe('Failed to send password reset email', e, stackTrace);
      rethrow;
    }
  }
}