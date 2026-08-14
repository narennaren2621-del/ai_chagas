import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isSignup, super.key});

  final bool isSignup;

  @override
  Widget build(BuildContext context) {
    return google_web.renderButton(
      configuration: google_web.GSIButtonConfiguration(
        text: isSignup
            ? google_web.GSIButtonText.signupWith
            : google_web.GSIButtonText.signinWith,
        theme: google_web.GSIButtonTheme.outline,
        size: google_web.GSIButtonSize.large,
        shape: google_web.GSIButtonShape.rectangular,
        minimumWidth: 360,
      ),
    );
  }
}
