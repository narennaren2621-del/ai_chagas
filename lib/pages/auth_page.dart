import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../widgets/auth/brand_lockup.dart';
import '../widgets/auth/google_auth_button.dart';
import '../widgets/auth/segmented_auth.dart';
import '../widgets/auth/welcome_panel.dart';
import '../services/patient_service.dart';
import 'dashboard_page.dart';
import 'doctor_dashboard_page.dart';
import 'patient_details_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isDoctorRole = false; // Toggle for Patient vs Doctor login
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

  void _handleGoogleAuthentication(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn || !mounted) return;
    _goToDashboard(
      UserProfile(
        name: event.user.displayName ?? event.user.email.split('@').first,
        email: event.user.email,
        photoUrl: event.user.photoUrl,
        provider: 'Google account',
      ),
    );
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    _goToDashboard(
      UserProfile(
        name: _isLogin ? email.split('@').first : _nameController.text.trim(),
        email: email,
        provider: 'Email account',
      ),
    );
    final action = _isLogin ? 'Welcome back' : 'Account created';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — your prediction dashboard is ready.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToDashboard(UserProfile profile) {
    final emailLower = profile.email.toLowerCase();
    final isDoc = _isDoctorRole || emailLower.startsWith('doctor') || emailLower.startsWith('dr.');

    if (isDoc) {
      final docName = profile.name.startsWith('Dr.') ? profile.name : profile.name.replaceAll('doctor', '').trim();
      final docProfile = UserProfile(
        name: docName.isEmpty ? 'Smith' : docName,
        email: profile.email,
        provider: profile.provider,
        photoUrl: profile.photoUrl,
      );

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

    // Patient workflow
    if (PatientService().hasPatientDetails(profile.email)) {
      final existingDetails = PatientService().getPatientDetails(profile.email)!;
      PatientService().initialize(profile, existingDetails);

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DashboardPage(
            profile: profile,
            patientDetails: existingDetails,
            onSignOut: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      // First time login: Prompt user to fill patient details one time only
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PatientDetailsPage(
            profile: profile,
            onCompleted: (details) {
              PatientService().initialize(profile, details);
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

            // Role Selection: Patient vs Doctor Portal
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
                      onTap: () => setState(() => _isDoctorRole = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isDoctorRole ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isDoctorRole
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 16, color: !_isDoctorRole ? const Color(0xFF006B67) : const Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              'Patient Access',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_isDoctorRole ? const Color(0xFF006B67) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isDoctorRole = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isDoctorRole ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isDoctorRole
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 16, color: _isDoctorRole ? const Color(0xFF006B67) : const Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              'Doctor Portal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isDoctorRole ? const Color(0xFF006B67) : const Color(0xFF6B7280),
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
