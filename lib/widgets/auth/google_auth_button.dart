import 'package:flutter/widgets.dart';

import 'google_auth_button_stub.dart'
    if (dart.library.js_interop) 'google_auth_button_web.dart';

export 'google_auth_button_stub.dart'
    if (dart.library.js_interop) 'google_auth_button_web.dart';

Widget buildGoogleWebButton({required bool isSignup}) {
  return GoogleWebSignInButton(isSignup: isSignup);
}
