import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'edit_patient_info_page.dart';

class PatientInformationPage extends StatefulWidget {
  const PatientInformationPage({
    required this.profile,
    required this.patientDetails,
    super.key,
  });

  final UserProfile profile;
  final PatientDetails patientDetails;

  @override
  State<PatientInformationPage> createState() =>
      _PatientInformationPageState();
}

class _PatientInformationPageState extends State<PatientInformationPage> {
  late PatientDetails _patientDetails;

  @override
  void initState() {
    super.initState();
    _patientDetails = widget.patientDetails;
  }

  void _openEditPage() async {
    final result = await Navigator.of(context).push<PatientDetails>(
      MaterialPageRoute(
        builder: (_) => EditPatientInfoPage(
          profile: widget.profile,
          patientDetails: _patientDetails,
          onSave: (updatedDetails) {
            setState(() {
              _patientDetails = updatedDetails;
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _patientDetails = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Information'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF123230),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Edit',
              onPressed: _openEditPage,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C001F1D),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFDDF0ED),
                      backgroundImage: widget.profile.photoUrl == null
                          ? null
                          : NetworkImage(widget.profile.photoUrl!),
                      child: widget.profile.photoUrl == null
                          ? Text(
                              _patientDetails.fullName.isEmpty
                                  ? '?'
                                  : _patientDetails.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF006B67),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _patientDetails.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123230),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Patient ID: ${_patientDetails.gmailId.split('@')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF68807E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123230),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      'Full Name',
                      _patientDetails.fullName,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Email Address',
                      widget.profile.email,
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Account Type',
                      widget.profile.provider,
                      Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Medical Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123230),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Gender',
                            _patientDetails.gender,
                            Icons.wc_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Age',
                            '${_patientDetails.age} yrs',
                            Icons.cake_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      'Date of Birth',
                      _formatDate(_patientDetails.dateOfBirth),
                      Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      'City',
                      _patientDetails.city,
                      Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      'Gmail ID',
                      _patientDetails.gmailId,
                      Icons.mail_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123230),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openEditPage,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Information'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006B67),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Info Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep your patient information up to date for accurate health assessments.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C001F1D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF006B67),
            size: 18,
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
                    color: Color(0xFF68807E),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF123230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C001F1D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF006B67),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF68807E),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF123230),
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
