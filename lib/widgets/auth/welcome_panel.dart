import 'package:flutter/material.dart';
import 'brand_lockup.dart';
import 'trust_point.dart';

class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandLockup(),
            SizedBox(height: 42),
            Text(
              'Clarity for\nyour health journey.',
              style: TextStyle(
                fontSize: 45,
                height: 1.08,
                letterSpacing: -1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123230),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'A simple, guided way to understand potential Chagas disease risk factors and prepare for an informed conversation with a healthcare professional.',
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: Color(0xFF59716E),
              ),
            ),
            SizedBox(height: 34),
            TrustPoint(
              icon: Icons.verified_user_outlined,
              text: 'Private and secure by design',
            ),
            SizedBox(height: 16),
            TrustPoint(
              icon: Icons.auto_graph_rounded,
              text: 'Evidence-informed risk insights',
            ),
            SizedBox(height: 16),
            TrustPoint(
              icon: Icons.volunteer_activism_outlined,
              text: 'Built to support, never replace, care',
            ),
          ],
        ),
      );
}
