import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../widgets/auth/brand_lockup.dart';
import '../widgets/chat_box.dart';
import '../widgets/dashboard/profile_card.dart';
import '../widgets/dashboard/quick_action_card.dart';
import '../widgets/dashboard/risk_summary_card.dart';
import 'prediction_page.dart';
import 'realtime_ecg_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.profile,
    required this.patientDetails,
    required this.onSignOut,
    super.key,
  });

  final UserProfile profile;
  final PatientDetails patientDetails;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final firstName =
        patientDetails.fullName.trim().split(RegExp(r'\s+')).first;
    return Scaffold(
      appBar: AppBar(
        title: const BrandLockup(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Sign out',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $firstName',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123230),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Here is your Chagas health assessment overview.',
                    style: TextStyle(color: Color(0xFF68807E), fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  RiskSummaryCard(onStart: () => _openRealtimeEcgPage(context)),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 620;
                      final cards = [
                        QuickActionCard(
                          icon: Icons.fact_check_outlined,
                          title: 'Risk assessment',
                          subtitle: 'Answer a few guided questions',
                          color: const Color(0xFF006B67),
                          onTap: () => _openPredictionPage(context),
                        ),
                        QuickActionCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Care plan',
                          subtitle: 'Prepare for your next visit',
                          color: const Color(0xFFE46A4A),
                          onTap: () => _showComingSoon(context),
                        ),
                      ];
                      return wide
                          ? Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            )
                          : Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 14),
                                cards[1],
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Your profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Color(0xFF123230),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ProfileCard(
                    profile: profile,
                    patientDetails: patientDetails,
                  ),
                  const SizedBox(height: 24),
                  const ChatBox(),
                  const SizedBox(height: 20),
                  const Text(
                    'Chagas Predict provides informational support and is not a medical diagnosis.',
                    style: TextStyle(color: Color(0xFF829794), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRealtimeEcgPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RealtimeEcgPage(),
      ),
    );
  }

  void _openPredictionPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PredictionPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This dashboard feature will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
