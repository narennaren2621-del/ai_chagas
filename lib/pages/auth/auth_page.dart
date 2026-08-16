import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:chagas_predictor/config/app_config.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/widgets/auth/brand_lockup.dart';
import 'package:chagas_predictor/widgets/auth/google_auth_button.dart';
import 'package:chagas_predictor/widgets/auth/segmented_auth.dart';
import 'package:chagas_predictor/widgets/auth/welcome_panel.dart';
import 'package:chagas_predictor/services/patient/patient_service.dart';
import 'package:chagas_predictor/pages/dashboard/dashboard_page.dart';
import 'package:chagas_predictor/pages/dashboard/doctor_dashboard_page.dart';
import 'package:chagas_predictor/pages/dashboard/admin_dashboard_page.dart';
import 'package:chagas_predictor/pages/patient/patient_details_page.dart';
import 'package:chagas_predictor/services/admin/admin_portal_service.dart';
import 'package:chagas_predictor/services/auth/firebase_auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  int _selectedRole = 0; // 0: Patient, 1: Doctor, 2: Admin
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _googleReady = false;
  String? _googleError;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn.instance;
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(clientId: AppConfig.googleOAuthClientId);
      _googleSubscription = _googleSignIn.authenticationEvents.listen(
        _handleGoogleAuthentication,
        onError: _handleGoogleError,
      );
      _googleSignIn.attemptLightweightAuthentication();
      if (mounted) setState(() => _googleReady = true);
    } catch (error) {
      _handleGoogleError(error);
    }
  }

  Future<void> _handleGoogleAuthentication(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn || !mounted) return;
    final role = _selectedRole == 2 ? 'Admin' : (_selectedRole == 1 ? 'Doctor' : 'Patient');
    final authService = FirebaseAuthService();
    final email = event.user.email;
    final name = event.user.displayName ?? email.split('@').first;
    final photoUrl = event.user.photoUrl;

    late final AuthResult result;
    if (_isLogin) {
      result = await authService.signInWithOAuth(
        email: email,
        name: name,
        photoUrl: photoUrl,
      );
    } else {
      result = await authService.registerWithOAuth(
        email: email,
        name: name,
        role: role,
        photoUrl: photoUrl,
      );
    }

    if (!mounted) return;

    if (!result.success || result.profile == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_person_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Access Denied'),
            ],
          ),
          content: Text(
            result.errorMessage ?? 'Google Sign-In Failed: You must sign up for an account before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (_isLogin) {
                  _switchMode(false);
                }
              },
              child: Text(_isLogin ? 'Go to Sign Up' : 'OK'),
            ),
          ],
        ),
      );
      return;
    }

    _goToDashboard(result.profile!, isNewSignup: !_isLogin);
  }

  void _handleGoogleError(Object error) {
    if (!mounted) return;
    setState(
      () => _googleError = 'Google sign-in is unavailable. Please try again.',
    );
  }

  Future<void> _signInWithGoogle() async {
    if (!_googleReady) return;
    try {
      await _googleSignIn.authenticate();
    } catch (error) {
      _handleGoogleError(error);
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _isLogin ? email.split('@').first : _nameController.text.trim();
    final role = _selectedRole == 2 ? 'Admin' : (_selectedRole == 1 ? 'Doctor' : 'Patient');

    final authService = FirebaseAuthService();
    late final AuthResult result;

    if (_isLogin) {
      result = await authService.signInWithEmail(
        email: email,
        password: password,
      );
    } else {
      result = await authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    }

    if (!mounted) return;

    if (!result.success || result.profile == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_person_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Access Denied'),
            ],
          ),
          content: Text(
            result.errorMessage ?? 'Sign-In Failed: You must sign up for an account before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (_isLogin) {
                  _switchMode(false);
                }
              },
              child: Text(_isLogin ? 'Go to Sign Up' : 'OK'),
            ),
          ],
        ),
      );
      return;
    }

    _goToDashboard(result.profile!, isNewSignup: !_isLogin);
    final action = _isLogin ? 'Welcome back' : 'Account created';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — verified authentication.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _goToDashboard(UserProfile profile, {bool isNewSignup = false}) async {
    final emailLower = profile.email.toLowerCase();

    // Admin workflow: Strictly only narenkvp302@gmail.com can access Admin Portal!
    final isAdminAttempt = _selectedRole == 2 || emailLower == 'narenkvp302@gmail.com' || emailLower.startsWith('admin');

    if (isAdminAttempt) {
      if (emailLower != 'narenkvp302@gmail.com') {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_person_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text('Admin Access Denied'),
              ],
            ),
            content: Text(
              'Only "narenkvp302@gmail.com" is authorized to access the Admin Portal. The email "${profile.email}" is not allowed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final adminProfile = UserProfile(
        name: 'Naren (System Admin)',
        email: 'narenkvp302@gmail.com',
        provider: profile.provider,
        photoUrl: profile.photoUrl,
      );

      AdminPortalService().logActivity(
        action: 'Admin Login',
        details: 'System Admin Naren logged into system governance portal.',
        userEmail: 'narenkvp302@gmail.com',
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminDashboardPage(
            adminProfile: adminProfile,
            onSignOut: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    // Doctor workflow: Strictly only sathyaa7755@gmail.com can access Doctor Portal!
    final isDocAttempt = _selectedRole == 1 || emailLower == 'sathyaa7755@gmail.com';

    if (isDocAttempt) {
      if (emailLower != 'sathyaa7755@gmail.com') {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_person_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text('Doctor Access Denied'),
              ],
            ),
            content: Text(
              'Only "sathyaa7755@gmail.com" is authorized to access the Doctor Portal. The email "${profile.email}" is not allowed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final docProfile = UserProfile(
        name: 'Dr. Sathya',
        email: 'sathyaa7755@gmail.com',
        provider: profile.provider,
        photoUrl: profile.photoUrl,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorDashboardPage(
            doctorProfile: docProfile,
            onSignOut: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    // Patient workflow: Clear old session if new signup
    if (isNewSignup) {
      PatientService().clearSessionForNewSignup(profile.email);
    }

    final firestoreDetails = isNewSignup
        ? null
        : await PatientService().fetchPatientDetailsFromFirestore(profile.email);

    if (!mounted) return;

    if (!isNewSignup && firestoreDetails != null) {
      PatientService().initialize(profile, firestoreDetails);

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DashboardPage(
            profile: profile,
            patientDetails: firestoreDetails,
            onSignOut: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      // First-time signup / login without patient details: Prompt for patient details, then save to Firestore patients collection!
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PatientDetailsPage(
            profile: profile,
            onCompleted: (details) {
              PatientService().saveAndInitializePatientDetails(profile, details);
              return DashboardPage(
                profile: profile,
                patientDetails: details,
                onSignOut: () => Navigator.of(context).pop(),
              );
            },
          ),
        ),
      );
    }
  }

  void _switchMode(bool login) {
    if (_isLogin == login) return;
    setState(() {
      _isLogin = login;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth >= 820;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: EdgeInsets.all(wide ? 28 : 20),
              child: wide
                  ? Row(
                      children: [
                        const Expanded(child: WelcomePanel()),
                        const SizedBox(width: 52),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _authCard(),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(child: _authCard(showIntro: true)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authCard({bool showIntro = false}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16001F1D),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIntro) ...[
              const MobileBrand(),
              const SizedBox(height: 30),
            ],
            Text(
              _isLogin ? 'Welcome back' : 'Create your account',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123230),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _isLogin
                  ? 'Sign in to access your health prediction tools.'
                  : 'Start your guided Chagas risk assessment today.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF68807E),
              ),
            ),
            const SizedBox(height: 20),

            // Role Selection: Patient vs Doctor vs Admin Portal
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedRole == 0
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 15, color: _selectedRole == 0 ? const Color(0xFF006B67) : const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              'Patient',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedRole == 0 ? const Color(0xFF006B67) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedRole == 1
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 15, color: _selectedRole == 1 ? const Color(0xFF006B67) : const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              'Doctor',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedRole == 1 ? const Color(0xFF006B67) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 2),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 2 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedRole == 2
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_outlined,
                                size: 15, color: _selectedRole == 2 ? const Color(0xFF0284C7) : const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedRole == 2 ? const Color(0xFF0284C7) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SegmentedAuth(
              isLogin: _isLogin,
              onChanged: _switchMode,
            ),
            const SizedBox(height: 24),
            if (!_isLogin) ...[
              _label('Full name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            _label('Email address'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email address'
                  : null,
            ),
            const SizedBox(height: 16),
            _label('Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                hintText:
                    _isLogin ? 'Enter your password' : 'At least 8 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            if (_isLogin) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(color: Color(0xFF4E6866)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006B67),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isLogin ? 'Sign in securely' : 'Create account',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(color: Color(0xFF839895)),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            _googleSignInButton(),
            if (_googleError != null) ...[
              const SizedBox(height: 8),
              Text(
                _googleError!,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            Center(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(color: Color(0xFF68807E)),
                  text: _isLogin
                      ? 'New to Chagas Predict? '
                      : 'Already have an account? ',
                  children: [
                    WidgetSpan(
                      child: InkWell(
                        onTap: () => _switchMode(!_isLogin),
                        child: Text(
                          _isLogin ? 'Create account' : 'Sign in',
                          style: const TextStyle(
                            color: Color(0xFF006B67),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'For informational support only — not a medical diagnosis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF8AA09D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF294846),
          ),
        ),
      );

  Widget _googleSignInButton() {
    if (!_googleReady) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (kIsWeb) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: buildGoogleWebButton(isSignup: !_isLogin),
      );
    }
    return OutlinedButton.icon(
      onPressed: _signInWithGoogle,
      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
      label: Text(
        _isLogin ? 'Sign in with Google' : 'Sign up with Google',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: const Color(0xFF294846),
        side: const BorderSide(color: Color(0xFFDDE8E7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
