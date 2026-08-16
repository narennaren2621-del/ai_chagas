import 'package:flutter/material.dart';

import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/widgets/auth/brand_lockup.dart';
import 'package:chagas_predictor/widgets/chat/chat_box.dart';
import 'package:chagas_predictor/widgets/dashboard/profile_card.dart';
import 'package:chagas_predictor/widgets/dashboard/quick_action_card.dart';
import 'package:chagas_predictor/widgets/dashboard/risk_summary_card.dart';
import 'package:chagas_predictor/pages/care_plan/care_plan_page.dart';
import 'package:chagas_predictor/pages/patient/history_page.dart';
import 'package:chagas_predictor/pages/prediction/prediction_page.dart';
import 'package:chagas_predictor/pages/ecg/realtime_ecg_page.dart';
import 'package:chagas_predictor/services/patient/doctor_portal_service.dart';
import 'package:chagas_predictor/services/chat/doctor_patient_messaging_service.dart';
import 'package:chagas_predictor/widgets/chat/doctor_patient_chat_modal.dart';

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

    return StreamBuilder<Map<String, dynamic>>(
      stream: DoctorPortalService().streamDoctorProfile('sathyaa7755@gmail.com'),
      builder: (context, docSnap) {
        final docName = (docSnap.data?['doctorName'] as String?) ?? DoctorPortalService().doctorName;

        return Scaffold(
          appBar: AppBar(
            title: const BrandLockup(),
            actions: [
              StreamBuilder<int>(
                stream: DoctorPatientMessagingService().getPatientUnreadMessageCountStream(profile.email),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        tooltip: 'Message $docName',
                        onPressed: () => _openDoctorChat(context, docName),
                        icon: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF006B67)),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                tooltip: 'Assessment History',
                onPressed: () => _openHistoryPage(context),
                icon: const Icon(Icons.history_rounded),
              ),
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
                              icon: Icons.mark_chat_unread_rounded,
                              title: 'Message $docName',
                              subtitle: 'Direct clinical chat & consultation',
                              color: const Color(0xFF006B67),
                              onTap: () => _openDoctorChat(context, docName),
                            ),
                            QuickActionCard(
                              icon: Icons.fact_check_outlined,
                              title: 'Risk assessment',
                              subtitle: 'Answer a few guided questions',
                              color: const Color(0xFF0D9488),
                              onTap: () => _openPredictionPage(context),
                            ),
                            QuickActionCard(
                              icon: Icons.calendar_month_outlined,
                              title: 'Care plan',
                              subtitle: 'Monthly food, meditation & health plan',
                              color: const Color(0xFFE46A4A),
                              onTap: () => _openCarePlanPage(context),
                            ),
                            QuickActionCard(
                              icon: Icons.history_rounded,
                              title: 'Assessment history',
                              subtitle: 'View saved user risk reports',
                              color: const Color(0xFF0284C7),
                              onTap: () => _openHistoryPage(context),
                            ),
                          ];
                          return wide
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: cards[0]),
                                        const SizedBox(width: 12),
                                        Expanded(child: cards[1]),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: cards[2]),
                                        const SizedBox(width: 12),
                                        Expanded(child: cards[3]),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    cards[0],
                                    const SizedBox(height: 14),
                                    cards[1],
                                    const SizedBox(height: 14),
                                    cards[2],
                                    const SizedBox(height: 14),
                                    cards[3],
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
      },
    );
  }

  void _openDoctorChat(BuildContext context, String currentDoctorName) {
    showDialog<void>(
      context: context,
      builder: (_) => DoctorPatientChatModal(
        patientEmail: profile.email,
        patientName: patientDetails.fullName,
        doctorEmail: 'sathyaa7755@gmail.com',
        doctorName: currentDoctorName,
        currentUserEmail: profile.email,
        currentUserName: patientDetails.fullName,
        currentUserRole: 'Patient',
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

  void _openCarePlanPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarePlanPage(
          profile: profile,
          patientDetails: patientDetails,
        ),
      ),
    );
  }

  void _openHistoryPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HistoryPage(),
      ),
    );
  }
}
