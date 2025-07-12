import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Comprehensive authentication service that handles multiple sign-in methods
/// 
/// This service provides a unified interface for all authentication operations
/// including email/password and Google Sign-In, with proper error handling
/// and state management.
class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Google Sign-In instance with configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Configure scopes if needed for additional permissions
    scopes: ['email', 'profile'],
  );

  /// Test Google Sign-In configuration
  /// 
  /// This method helps diagnose Google Sign-In setup issues
  Future<void> testGoogleSignInConfiguration() async {
    try {
      print('🔵 Testing Google Sign-In configuration...');
      
      // Check if Google Sign-In is available
      final bool isAvailable = await _googleSignIn.isSignedIn();
      print('🔵 Google Sign-In available: $isAvailable');
      
      // Check current signed-in account
      final GoogleSignInAccount? currentAccount = _googleSignIn.currentUser;
      print('🔵 Current Google account: ${currentAccount?.email ?? 'None'}');
      
      // Test silent sign-in (won't show UI)
      final GoogleSignInAccount? silentAccount = await _googleSignIn.signInSilently();
      print('🔵 Silent sign-in result: ${silentAccount?.email ?? 'None'}');
      
    } catch (e) {
      print('🔴 Google Sign-In configuration test failed: $e');
    }
  }

  /// Current authenticated user
  /// 
  /// Returns the currently signed-in Firebase user or null if not authenticated
  User? get currentUser => _firebaseAuth.currentUser;

  /// Authentication state changes stream
  /// 
  /// Listen to this stream to react to authentication state changes
  /// throughout the application lifecycle
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// User changes stream (includes profile updates)
  /// 
  /// This stream includes both auth state changes and user profile updates
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  // MARK: - Email/Password Authentication

  /// Sign in with email and password
  /// 
  /// Throws [FirebaseAuthException] with specific error codes:
  /// - user-not-found: No user record found
  /// - wrong-password: Invalid password
  /// - invalid-email: Malformed email address
  /// - user-disabled: User account has been disabled
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred during sign-in');
    }
  }

  /// Create account with email and password
  /// 
  /// Throws [FirebaseAuthException] with specific error codes:
  /// - email-already-in-use: Email is already registered
  /// - weak-password: Password is too weak
  /// - invalid-email: Malformed email address
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 AuthService: Creating account with email/password...');
      print('Email: ${email.trim()}');
      
      final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      print('🟢 AuthService: Account created and user signed in successfully!');
      print('User ID: ${result.user?.uid}');
      print('Email: ${result.user?.email}');
      print('Email verified: ${result.user?.emailVerified}');
      print('Is new user: ${result.additionalUserInfo?.isNewUser}');
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('🔴 AuthService: FirebaseAuthException during account creation: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      print('🔴 AuthService: Unexpected error during account creation: ${e.toString()}');
      throw AuthException('An unexpected error occurred during account creation');
    }
  }

  // MARK: - Google Sign-In Integration

  /// Sign in with Google account (with retry mechanism)
  /// 
  /// This method handles the complete Google Sign-In flow:
  /// 1. Initiates Google sign-in popup/screen
  /// 2. Retrieves Google authentication credentials
  /// 3. Creates Firebase credentials from Google tokens
  /// 4. Signs into Firebase with Google credentials
  /// 
  /// Returns [UserCredential] on success, null if user cancels
  /// Throws [AuthException] on failure
  Future<UserCredential?> signInWithGoogle() async {
    const int maxRetries = 2;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔵 Starting Google Sign-In flow (attempt $attempt/$maxRetries)...');
        
        // Clear any existing sign-in state first
        await _googleSignIn.signOut();
        
        // Step 1: Trigger the Google Sign-In flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        // User cancelled the sign-in process
        if (googleUser == null) {
          print('🟡 User cancelled Google Sign-In');
          return null;
        }

        print('🔵 Google user obtained: ${googleUser.email}');
        print('🔵 Google user ID: ${googleUser.id}');
        print('🔵 Google user display name: ${googleUser.displayName}');

        // Step 2: Obtain authentication details from the Google account
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Ensure we have the required tokens
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('🔴 Failed to obtain required tokens');
          print('Access Token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
          print('ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');
          
          if (attempt < maxRetries) {
            print('🟡 Retrying Google Sign-In...');
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          
          throw AuthException('Failed to obtain Google authentication tokens');
        }

        print('🔵 Google tokens obtained successfully');
        print('🔵 Access Token length: ${googleAuth.accessToken?.length}');
        print('🔵 ID Token length: ${googleAuth.idToken?.length}');

        // Step 3: Create Firebase credential from Google tokens
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('🔵 Firebase credential created');

        // Step 4: Sign in to Firebase with the Google credential
        final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
        
        print('🟢 Firebase authentication successful');
        print('User ID: ${result.user?.uid}');
        print('Email: ${result.user?.email}');
        print('Display Name: ${result.user?.displayName}');
        print('Photo URL: ${result.user?.photoURL}');
        print('Is new user: ${result.additionalUserInfo?.isNewUser}');
        print('Provider ID: ${result.credential?.providerId}');
        
        // Verify the user is properly authenticated
        if (result.user == null) {
          throw AuthException('Authentication succeeded but user is null');
        }
        
        return result;
        
      } on FirebaseAuthException catch (e) {
        print('🔴 FirebaseAuthException: ${e.code} - ${e.message}');
        
        if (attempt < maxRetries && _shouldRetry(e.code)) {
          print('🟡 Retrying due to recoverable error...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        throw _handleFirebaseAuthError(e);
      } catch (e) {
        print('🔴 Unexpected error during Google Sign-In: ${e.toString()}');
        print('Error type: ${e.runtimeType}');
        
        if (attempt < maxRetries) {
          print('🟡 Retrying due to unexpected error...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        
        throw AuthException('Google sign-in failed: ${e.toString()}');
      }
    }
    
    throw AuthException('Google sign-in failed after $maxRetries attempts');
  }
  
  /// Check if an error code should trigger a retry
  bool _shouldRetry(String errorCode) {
    const retryableErrors = [
      'network-request-failed',
      'timeout',
      'unavailable',
    ];
    return retryableErrors.contains(errorCode);
  }

  /// Link Google account to existing Firebase user
  /// 
  /// This allows users to add Google Sign-In as an additional authentication
  /// method to their existing email/password account
  Future<UserCredential> linkWithGoogle() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw AuthException('No user is currently signed in');
    }

    try {
      // Get Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential to the current user
      return await currentUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Failed to link Google account: ${e.toString()}');
    }
  }

  // MARK: - Account Management

  /// Sign out from all authentication providers
  /// 
  /// This method ensures complete sign-out by calling both Firebase
  /// and Google sign-out methods
  Future<void> signOut() async {
    try {
      // Sign out from both Firebase and Google to ensure complete logout
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Send password reset email
  /// 
  /// Sends a password reset email to the provided email address
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Failed to send password reset email');
    }
  }

  /// Update user display name
  /// 
  /// Updates the display name for the currently authenticated user
  Future<void> updateDisplayName({required String displayName}) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }

    try {
      await user.updateDisplayName(displayName.trim());
      await user.reload(); // Refresh user data
    } catch (e) {
      throw AuthException('Failed to update display name: ${e.toString()}');
    }
  }

  /// Delete user account
  /// 
  /// Permanently deletes the user account and all associated data
  /// Requires recent authentication for security
  Future<void> deleteAccount() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }

    try {
      await user.delete();
      await _googleSignIn.signOut(); // Ensure Google sign-out
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException('Please sign in again before deleting your account');
      }
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  /// Reauthenticate user with email and password
  /// 
  /// Required before sensitive operations like account deletion or password change
  Future<void> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Reauthentication failed: ${e.toString()}');
    }
  }

  /// Reauthenticate user with Google
  /// 
  /// Required before sensitive operations for Google-authenticated users
  Future<void> reauthenticateWithGoogle() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google reauthentication was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Google reauthentication failed: ${e.toString()}');
    }
  }

  /// Debug utility to print current authentication state
  void debugAuthState() {
    final User? user = _firebaseAuth.currentUser;
    print('🔍 === AUTHENTICATION STATE DEBUG ===');
    print('🔍 Firebase currentUser: ${user?.uid ?? 'null'}');
    print('🔍 Email: ${user?.email ?? 'null'}');
    print('🔍 Display Name: ${user?.displayName ?? 'null'}');
    print('🔍 Email Verified: ${user?.emailVerified ?? 'null'}');
    print('🔍 Photo URL: ${user?.photoURL ?? 'null'}');
    print('🔍 Providers: ${user?.providerData.map((p) => p.providerId).toList() ?? 'null'}');
    print('🔍 Google currentUser: ${_googleSignIn.currentUser?.email ?? 'null'}');
    print('🔍 =====================================');
  }

  /// Get list of authentication providers for current user
  /// 
  /// Returns a list of provider IDs (e.g., 'password', 'google.com')
  List<String> getAuthProviders() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return [];
    
    return user.providerData.map((info) => info.providerId).toList();
  }

  /// Check if user has specific authentication provider
  /// 
  /// Useful for determining available authentication options
  bool hasAuthProvider(String providerId) {
    return getAuthProviders().contains(providerId);
  }

  /// Check if user is signed in with Google
  bool get isSignedInWithGoogle => hasAuthProvider('google.com');

  /// Check if user is signed in with email/password
  bool get isSignedInWithEmail => hasAuthProvider('password');

  // MARK: - Error Handling

  /// Convert Firebase Auth errors to user-friendly messages
  /// 
  /// This method provides consistent error handling across the application
  AuthException _handleFirebaseAuthError(FirebaseAuthException e) {
    print('🔴 Firebase Auth Error: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No account found with this email address');
      case 'wrong-password':
        return AuthException('Incorrect password');
      case 'email-already-in-use':
        return AuthException('An account already exists with this email');
      case 'weak-password':
        return AuthException('Password is too weak');
      case 'invalid-email':
        return AuthException('Invalid email address');
      case 'user-disabled':
        return AuthException('This account has been disabled');
      case 'too-many-requests':
        return AuthException('Too many failed attempts. Please try again later');
      case 'operation-not-allowed':
        return AuthException('This sign-in method is not enabled');
      case 'account-exists-with-different-credential':
        return AuthException('An account already exists with a different sign-in method');
      case 'invalid-credential':
        return AuthException('Invalid credentials provided');
      case 'credential-already-in-use':
        return AuthException('This credential is already associated with another account');
      case 'requires-recent-login':
        return AuthException('Please sign in again to perform this action');
      case 'network-request-failed':
        return AuthException('Network error. Please check your connection and try again');
      case 'app-not-authorized':
        return AuthException('App not authorized for Google Sign-In. Please contact support');
      case 'invalid-api-key':
        return AuthException('Invalid API key configuration. Please contact support');
      case 'popup-blocked':
        return AuthException('Sign-in popup was blocked. Please allow popups and try again');
      case 'popup-closed-by-user':
        return AuthException('Sign-in was cancelled');
      default:
        return AuthException('Authentication failed: ${e.message ?? 'Unknown error'}');
    }
  }
}

/// Custom exception class for authentication errors
/// 
/// Provides a consistent way to handle and display authentication errors
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}