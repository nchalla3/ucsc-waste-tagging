import 'package:flutter/material.dart';
import 'package:waste_tagging_app/services/auth_service.dart';

/// Modern sign-up screen with multiple registration options
/// 
/// This screen provides a clean interface for user registration supporting
/// both email/password and Google Sign-In methods with comprehensive validation
/// and error handling.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  // Form and validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  
  // Authentication service
  final AuthService _authService = AuthService();
  
  // UI State management
  bool _isEmailSignUpLoading = false;
  bool _isGoogleSignUpLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers
  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  /// Trigger shake animation for error feedback
  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  // MARK: - Authentication Methods

  /// Handle email/password sign-up
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShakeAnimation();
      return;
    }

    setState(() {
      _isEmailSignUpLoading = true;
    });

    try {
      print('🔵 SignUpPage: Creating new user account...');
      
      // Create user account (this automatically signs the user in)
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('🟢 SignUpPage: Account created successfully!');
      print('User ID: ${userCredential.user?.uid}');
      print('Email: ${userCredential.user?.email}');

      // Update display name if provided
      if (_displayNameController.text.trim().isNotEmpty) {
        print('🔵 SignUpPage: Updating display name...');
        await _authService.updateDisplayName(
          displayName: _displayNameController.text.trim(),
        );
        print('🟢 SignUpPage: Display name updated successfully');
      }

      print('🟢 SignUpPage: User registration and sign-in complete!');
      print('AuthWrapper should now detect the signed-in user and navigate to HomePage');

      // Navigation handled automatically by AuthWrapper
    } on AuthException catch (e) {
      print('🔴 SignUpPage: AuthException - ${e.message}');
      _handleAuthError(e.message);
    } catch (e) {
      print('🔴 SignUpPage: Unexpected error - ${e.toString()}');
      _handleAuthError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSignUpLoading = false;
        });
      }
    }
  }

  /// Handle Google Sign-Up
  Future<void> _handleGoogleSignUp() async {
    print('🔵 SignUpPage: Starting Google Sign-Up...');
    
    setState(() {
      _isGoogleSignUpLoading = true;
    });

    try {
      print('🔵 SignUpPage: Calling AuthService.signInWithGoogle()...');
      final result = await _authService.signInWithGoogle();
      
      if (result == null) {
        // User cancelled Google Sign-In
        print('🟡 SignUpPage: User cancelled Google Sign-Up');
      } else {
        // Success case - user is now signed in
        print('🟢 SignUpPage: Google Sign-Up successful!');
        print('User: ${result.user?.email}');
        print('Is new user: ${result.additionalUserInfo?.isNewUser}');
        print('AuthWrapper should now detect the signed-in user and navigate to HomePage');
      }
    } on AuthException catch (e) {
      print('🔴 SignUpPage: AuthException - ${e.message}');
      _handleAuthError(e.message);
    } catch (e) {
      print('🔴 SignUpPage: Unexpected error - ${e.toString()}');
      _handleAuthError('Google sign-up failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSignUpLoading = false;
        });
      }
    }
  }

  /// Handle authentication errors with user feedback
  void _handleAuthError(String message) {
    _triggerShakeAnimation();
    
    // Show error snackbar for user feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // MARK: - Validation Methods

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password requirements
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    // Additional password strength requirements
    if (!value.contains(RegExp(r'[A-Za-z]'))) {
      return 'Password must contain at least one letter';
    }
    
    return null;
  }

  /// Validate password confirmation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate display name
  String? _validateDisplayName(String? value) {
    if (value != null && value.isNotEmpty && value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    return null;
  }

  // MARK: - UI Building Methods

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeAnimation.value * 10;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildEmailSignUpForm(theme),
                    const SizedBox(height: 32),
                    _buildDivider(theme),
                    const SizedBox(height: 32),
                    _buildGoogleSignUpButton(theme),
                    const SizedBox(height: 24),
                    _buildBottomActions(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the header section
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Join Waste Tracking',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to start tracking waste',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build email/password sign-up form
  Widget _buildEmailSignUpForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display name field (optional)
          TextFormField(
            controller: _displayNameController,
            textInputAction: TextInputAction.next,
            enabled: !_isEmailSignUpLoading && !_isGoogleSignUpLoading,
            validator: _validateDisplayName,
            decoration: InputDecoration(
              labelText: 'Display Name (Optional)',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isEmailSignUpLoading && !_isGoogleSignUpLoading,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            enabled: !_isEmailSignUpLoading && !_isGoogleSignUpLoading,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !_isEmailSignUpLoading && !_isGoogleSignUpLoading,
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleEmailSignUp(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sign up button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isEmailSignUpLoading || _isGoogleSignUpLoading) 
                  ? null 
                  : _handleEmailSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isEmailSignUpLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build divider between sign-up methods
  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Build Google Sign-Up button
  Widget _buildGoogleSignUpButton(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: (_isEmailSignUpLoading || _isGoogleSignUpLoading) 
            ? null 
            : _handleGoogleSignUp,
        icon: _isGoogleSignUpLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                Icons.g_translate, // Using a suitable Google-style icon
                size: 20,
                color: theme.colorScheme.primary,
              ),
        label: Text(
          _isGoogleSignUpLoading ? 'Creating account...' : 'Continue with Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Build bottom action buttons
  Widget _buildBottomActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        TextButton(
          onPressed: (_isEmailSignUpLoading || _isGoogleSignUpLoading) 
              ? null 
              : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
