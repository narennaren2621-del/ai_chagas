import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'patient_information_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.profile,
    required this.patientDetails,
    super.key,
  });

  final UserProfile profile;
  final PatientDetails patientDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Hero Card
                  _buildProfileHeader(context),
                  const SizedBox(height: 24),

                  // Personal Details Section
                  _buildSectionHeader('Personal Information', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 550;
                      if (isWide) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildDetailCard('Full Name', patientDetails.fullName, Icons.badge_outlined)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDetailCard('Email Address', profile.email, Icons.email_outlined)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard('Account Provider', profile.provider, Icons.verified_user_outlined),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildDetailCard('Full Name', patientDetails.fullName, Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _buildDetailCard('Email Address', profile.email, Icons.email_outlined),
                          const SizedBox(height: 12),
                          _buildDetailCard('Account Provider', profile.provider, Icons.verified_user_outlined),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Medical & Demographics Section
                  _buildSectionHeader('Medical & Clinical Information', Icons.medical_services_outlined),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 550;
                      if (isWide) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildDetailCard('Gender', patientDetails.gender, Icons.wc_rounded)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDetailCard('Age', '${patientDetails.age} yrs', Icons.cake_outlined)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildDetailCard('Date of Birth', _formatDate(patientDetails.dateOfBirth), Icons.calendar_month_outlined)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDetailCard('City', patientDetails.city, Icons.location_city_outlined)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard('Gmail / Account ID', patientDetails.gmailId, Icons.alternate_email_rounded),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailCard('Gender', patientDetails.gender, Icons.wc_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDetailCard('Age', '${patientDetails.age} yrs', Icons.cake_outlined)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailCard('Date of Birth', _formatDate(patientDetails.dateOfBirth), Icons.calendar_month_outlined),
                          const SizedBox(height: 12),
                          _buildDetailCard('City', patientDetails.city, Icons.location_city_outlined),
                          const SizedBox(height: 12),
                          _buildDetailCard('Gmail / Account ID', patientDetails.gmailId, Icons.alternate_email_rounded),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Quick Actions & Management
                  _buildSectionHeader('Quick Actions', Icons.bolt_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PatientInformationPage(
                            profile: profile,
                            patientDetails: patientDetails,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text(
                        'View & Edit Patient Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B67),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Clinical Disclaimer Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chagas Predict profile information is used exclusively to assist LSTM model risk evaluation and biomarker analysis. It is for informational support only and is not a standalone diagnosis.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006B67), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B67).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFFE6F4F1),
              backgroundImage: profile.photoUrl == null ? null : NetworkImage(profile.photoUrl!),
              child: profile.photoUrl == null
                  ? Text(
                      patientDetails.fullName.trim().isEmpty
                          ? '?'
                          : patientDetails.fullName.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF006B67),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            patientDetails.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Verified Patient Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF006B67)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF006B67)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
