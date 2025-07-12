import 'package:flutter/material.dart';
import 'package:waste_tagging_app/services/auth_service.dart';

/// Authentication state widget that provides auth context to child widgets
/// 
/// This widget wraps the app and provides authentication state and methods
/// to all child widgets through InheritedWidget pattern. It's useful for
/// accessing auth state and methods from anywhere in the widget tree.
class AuthProvider extends InheritedWidget {
  final AuthService authService;
  final Widget child;

  const AuthProvider({
    super.key,
    required this.authService,
    required this.child,
  }) : super(child: child);

  /// Get the nearest AuthProvider instance from the widget tree
  static AuthProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>();
  }

  /// Quick access to AuthService from any widget
  static AuthService authServiceOf(BuildContext context) {
    final authProvider = of(context);
    assert(authProvider != null, 'AuthProvider not found in widget tree');
    return authProvider!.authService;
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return authService != oldWidget.authService;
  }
}

/// Account management screen demonstrating multiple authentication methods
/// 
/// This screen shows how to use the AuthService with different authentication
/// providers and manage user accounts with various linked authentication methods.
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  late AuthService _authService;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = AuthProvider.authServiceOf(context);
  }

  /// Link Google account to existing user
  Future<void> _linkGoogleAccount() async {
    if (_authService.isSignedInWithGoogle) {
      _showMessage('Google account is already linked', isError: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.linkWithGoogle();
      _showMessage('Google account linked successfully!', isError: false);
    } on AuthException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('Failed to link Google account', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Sign out from all providers
  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
      // Navigation handled by AuthWrapper
    } catch (e) {
      _showMessage('Failed to sign out', isError: true);
      setState(() => _isLoading = false);
    }
  }

  /// Show success or error message
  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;
    final authProviders = _authService.getAuthProviders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Display Name',
                      value: user?.displayName ?? 'Not set',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'Not available',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.verified_user,
                      label: 'Email Verified',
                      value: user?.emailVerified == true ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authentication methods card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Methods',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email/Password
                    _buildAuthMethodRow(
                      icon: Icons.email,
                      label: 'Email & Password',
                      isLinked: _authService.isSignedInWithEmail,
                    ),
                    const SizedBox(height: 8),
                    
                    // Google
                    _buildAuthMethodRow(
                      icon: Icons.g_translate,
                      label: 'Google',
                      isLinked: _authService.isSignedInWithGoogle,
                      onTap: _authService.isSignedInWithGoogle ? null : _linkGoogleAccount,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Provider information (for debugging)
            if (authProviders.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected Providers',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...authProviders.map(
                        (provider) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $provider',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // Sign out button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build information row widget
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  /// Build authentication method row widget
  Widget _buildAuthMethodRow({
    required IconData icon,
    required String label,
    required bool isLinked,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (isLinked)
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 20,
              )
            else if (onTap != null)
              const Icon(
                Icons.add_circle_outline,
                color: Colors.blue,
                size: 20,
              )
            else
              Icon(
                Icons.remove_circle_outline,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
