import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/patient_service.dart';
import '../widgets/auth/brand_lockup.dart';
import 'doctor_patient_detail_page.dart';

class DoctorDashboardPage extends StatefulWidget {
  final UserProfile doctorProfile;
  final VoidCallback onSignOut;

  const DoctorDashboardPage({
    super.key,
    required this.doctorProfile,
    required this.onSignOut,
  });

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488);
    if (risk < 0.60) return const Color(0xFFEAB308);
    if (risk < 0.80) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final allPatients = PatientService().getAllPatientRecords();

    // Filter patients by search term & category
    final search = _searchController.text.trim().toLowerCase();
    final filtered = allPatients.where((p) {
      final matchesSearch = search.isEmpty ||
          p.patientDetails.fullName.toLowerCase().contains(search) ||
          p.patientDetails.city.toLowerCase().contains(search) ||
          p.patientDetails.gmailId.toLowerCase().contains(search);

      final matchesCategory = _selectedCategoryFilter == 'All' ||
          p.riskCategory.toLowerCase() == _selectedCategoryFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    // Compute KPI metrics
    final totalCount = allPatients.length;
    final highRiskCount = allPatients.where((p) => p.lstmRiskScore >= 0.80).length;
    final pendingCount = allPatients.where((p) => p.doctorVerificationStatus == 'Pending Review').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const BrandLockup(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B67).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_rounded, size: 14, color: Color(0xFF006B67)),
                    const SizedBox(width: 6),
                    Text(
                      'Dr. ${widget.doctorProfile.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006B67),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Welcome Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor Clinical Portal',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome Dr. ${widget.doctorProfile.name} • Review patient risk assessments and ECG predictions.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // KPI Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Patients',
                          value: '$totalCount',
                          icon: Icons.people_outline_rounded,
                          color: const Color(0xFF006B67),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Critical High Risk',
                          value: '$highRiskCount',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Pending Reviews',
                          value: '$pendingCount',
                          icon: Icons.rate_review_outlined,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search & Category Filter Controls Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search patients by name, city, or Gmail ID...',
                              prefixIcon: Icon(Icons.search_rounded),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedCategoryFilter,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF006B67)),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Categories')),
                            DropdownMenuItem(value: 'Critical High Risk', child: Text('Critical High Risk')),
                            DropdownMenuItem(value: 'Elevated Risk', child: Text('Elevated Risk')),
                            DropdownMenuItem(value: 'Moderate Risk', child: Text('Moderate Risk')),
                            DropdownMenuItem(value: 'Low Risk', child: Text('Low Risk')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedCategoryFilter = v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assessed Patients List (${filtered.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Patients List Cards
                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Text(
                          'No patient records match the search filter.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: filtered.map((patientRecord) {
                        final riskColor = _getRiskColor(patientRecord.lstmRiskScore);
                        final riskPercent = (patientRecord.lstmRiskScore * 100).toStringAsFixed(1);
                        final p = patientRecord.patientDetails;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: riskColor.withValues(alpha: 0.12),
                              child: Text(
                                p.fullName[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: riskColor,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  p.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: riskColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    patientRecord.riskCategory,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p.gender} • ${p.age} yrs • City: ${p.city} • Gmail: ${p.gmailId}',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'LSTM Risk: $riskPercent%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: riskColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Status: ${patientRecord.doctorVerificationStatus}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => DoctorPatientDetailPage(
                                      record: patientRecord,
                                      doctorProfile: widget.doctorProfile,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              icon: const Icon(Icons.description_outlined, size: 16),
                              label: const Text('Review Patient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006B67),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
