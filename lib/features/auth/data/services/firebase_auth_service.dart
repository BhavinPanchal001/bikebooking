import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  final FirebaseAuth? _firebaseAuth;

  bool get isConfigured => _firebaseAuth != null || Firebase.apps.isNotEmpty;

  FirebaseAuth? get _authOrNull =>
      _firebaseAuth ??
      (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  FirebaseAuth get _auth {
    final firebaseAuth = _authOrNull;
    if (firebaseAuth == null) {
      throw StateError(
        'Firebase is not configured. Create a Firebase project and run flutterfire configure before using phone authentication.',
      );
    }
    return firebaseAuth;
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return signInWithCredential(credential);
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  User? get currentUser => _authOrNull?.currentUser;

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateDisplayName(displayName);
    await user.reload();
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
