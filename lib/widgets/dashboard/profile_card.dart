import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/pages/profile/profile_page.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.patientDetails,
    super.key,
  });

  final UserProfile profile;
  final PatientDetails patientDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfilePage(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C001F1D),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFDDF0ED),
              backgroundImage: profile.photoUrl == null
                  ? null
                  : NetworkImage(profile.photoUrl!),
              child: profile.photoUrl == null
                  ? Text(
                      patientDetails.fullName.isEmpty
                          ? '?'
                          : patientDetails.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF006B67),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientDetails.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Color(0xFF123230),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    patientDetails.gmailId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF68807E),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${patientDetails.gender} • ${patientDetails.age} years • ${patientDetails.city}',
                    style: const TextStyle(
                      color: Color(0xFF006B67),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfilePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(
          profile: profile,
          patientDetails: patientDetails,
        ),
      ),
    );
  }
}
