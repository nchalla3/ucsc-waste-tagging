import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:waste_tagging_app/services/auth_service.dart';
import 'signup_page.dart';

/// Modern login screen with multiple authentication options
/// 
/// This screen provides a clean, accessible interface for user authentication
/// supporting both email/password and Google Sign-In methods with comprehensive
/// error handling and loading states.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Form and validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Authentication service
  final AuthService _authService = AuthService();
  
  // UI State management
  bool _isEmailSignInLoading = false;
  bool _isGoogleSignInLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  
  // Animation controllers for smooth UX
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

  /// Handle email/password sign-in
  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShakeAnimation();
      return;
    }

    setState(() {
      _isEmailSignInLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation handled by AuthWrapper
    } on AuthException catch (e) {
      _handleAuthError(e.message);
    } catch (e) {
      _handleAuthError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSignInLoading = false;
        });
      }
    }
  }

  /// Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    print('🔵 LoginPage: Starting Google Sign-In...');
    
    setState(() {
      _isGoogleSignInLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 LoginPage: Calling AuthService.signInWithGoogle()...');
      final result = await _authService.signInWithGoogle();
      
      if (result == null) {
        // User cancelled Google Sign-In
        print('🟡 LoginPage: User cancelled Google Sign-In');
        setState(() {
          _errorMessage = 'Google sign-in was cancelled';
        });
      } else {
        // Success case - Firebase user should be created
        print('🟢 LoginPage: Google Sign-In successful!');
        print('User: ${result.user?.email}');
        print('AuthWrapper should now detect the user and navigate to HomePage');
      }
    } on AuthException catch (e) {
      print('🔴 LoginPage: AuthException - ${e.message}');
      _handleAuthError(e.message);
    } catch (e, stackTrace) {
      print('🔴 LoginPage: Unexpected error - ${e.toString()}');
      print('Stack trace: $stackTrace');
      _handleAuthError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSignInLoading = false;
        });
        print('🔵 LoginPage: Google Sign-In process completed, loading state reset');
      }
    }
  }

  /// Handle authentication errors with user feedback
  void _handleAuthError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _triggerShakeAnimation();
    
    // Show error snackbar for additional feedback
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

  /// Navigate to password reset screen
  void _showPasswordResetDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _PasswordResetDialog(
        authService: _authService,
      ),
    );
  }

  /// Navigate to sign-up screen
  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SignUpPage(),
      ),
    );
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
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.top - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 48),
                      _buildEmailSignInForm(theme),
                      const SizedBox(height: 32),
                      _buildDivider(theme),
                      const SizedBox(height: 32),
                      _buildGoogleSignInButton(theme),
                      const SizedBox(height: 24),
                      _buildBottomActions(theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the header section with app branding
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.recycling,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue waste tracking',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build email/password sign-in form
  Widget _buildEmailSignInForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isEmailSignInLoading && !_isGoogleSignInLoading,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              errorText: _errorMessage?.contains('email') == true ? _errorMessage : null,
            ),
          ),
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !_isEmailSignInLoading && !_isGoogleSignInLoading,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleEmailSignIn(),
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
              errorText: _errorMessage?.contains('password') == true ? _errorMessage : null,
            ),
          ),
          const SizedBox(height: 8),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: (_isEmailSignInLoading || _isGoogleSignInLoading) 
                  ? null 
                  : _showPasswordResetDialog,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sign in button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isEmailSignInLoading || _isGoogleSignInLoading) 
                  ? null 
                  : _handleEmailSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isEmailSignInLoading
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
                      'Sign In',
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

  /// Build divider between sign-in methods
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

  /// Build Google Sign-In button
  Widget _buildGoogleSignInButton(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: (_isEmailSignInLoading || _isGoogleSignInLoading) 
            ? null 
            : _handleGoogleSignIn,
        icon: _isGoogleSignInLoading
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
          _isGoogleSignInLoading ? 'Signing in...' : 'Continue with Google',
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
    return Column(
      children: [
        // Sign up row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            TextButton(
              onPressed: (_isEmailSignInLoading || _isGoogleSignInLoading) 
                  ? null 
                  : _navigateToSignUp,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        // Debug button (only in debug mode)
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _authService.debugAuthState(),
            icon: const Icon(Icons.bug_report, size: 16),
            label: const Text('Debug Auth State'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

/// Password reset dialog widget
/// 
/// Provides a clean interface for users to request password reset emails
class _PasswordResetDialog extends StatefulWidget {
  final AuthService authService;

  const _PasswordResetDialog({
    required this.authService,
  });

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Send password reset email
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${_emailController.text.trim()}',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                }
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Email'),
        ),
      ],
    );
  }
}
