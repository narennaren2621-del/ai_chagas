import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/doctor_patient_record.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/patient/doctor_portal_service.dart';
import 'package:chagas_predictor/services/pdf/pdf_report_service.dart';
import 'package:chagas_predictor/models/doctor_patient_message.dart';
import 'package:chagas_predictor/services/chat/doctor_patient_messaging_service.dart';
import 'package:chagas_predictor/widgets/auth/brand_lockup.dart';
import 'package:chagas_predictor/widgets/chat/doctor_patient_chat_modal.dart';

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
  int _selectedIndex = 0; // 0: Dashboard, 1: My Patients, 2: Patient Records, 3: ECG Analysis, 4: LSTM Predictions, 5: Risk Monitoring, 6: Prediction History, 7: Notifications, 8: Doctor Profile, 9: Settings
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';
  DoctorPatientRecord? _selectedRecordForDetail;

  @override
  void initState() {
    super.initState();
    final docService = DoctorPortalService();
    docService.doctorEmail = widget.doctorProfile.email;
    docService.doctorName = widget.doctorProfile.name;

    docService.fetchDoctorProfileFromFirestore(widget.doctorProfile.email).then((_) {
      if (mounted) setState(() {});
    });

    docService.fetchPatientsFromFirestore().then((_) {
      if (mounted) setState(() {});
    });
  }

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final doctorService = DoctorPortalService();
    final patientList = doctorService.patientRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF004D4A),
              foregroundColor: Colors.white,
              title: Row(
                children: [
                  const BrandLockup(),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => setState(() => _selectedIndex = 7),
                    ),
                    if (doctorService.unreadNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${doctorService.unreadNotificationCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              color: const Color(0xFF003835),
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopHeader(doctorService),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: _buildMainContent(patientList),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header for desktop
  Widget _buildDesktopHeader(DoctorPortalService doctorService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_rounded, color: Color(0xFF006B67), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _navTitles[_selectedIndex],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    'CHAGAS PREDICT • Clinical Decision Support Portal',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              StreamBuilder<int>(
                stream: DoctorPatientMessagingService().getDoctorUnreadMessageCountStream(widget.doctorProfile.email),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        tooltip: 'Patient Consultation Messages',
                        icon: const Icon(Icons.forum_outlined, color: Color(0xFF006B67)),
                        onPressed: () => setState(() => _selectedIndex = 3),
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
              const SizedBox(width: 12),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                    onPressed: () => setState(() => _selectedIndex = 7),
                  ),
                  if (doctorService.unreadNotificationCount > 0)
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
                          '${doctorService.unreadNotificationCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 8),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 8 ? const Color(0xFFE6F4F1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedIndex == 8 ? const Color(0xFF006B67) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF006B67),
                        child: Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorService.doctorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            doctorService.doctorTitle,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sidebar navigation contents
  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const BrandLockup(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Cardiology Specialist v2.4',
                  style: TextStyle(color: Color(0xFF99F6E4), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Divider(color: Color(0xFF0D5C58), height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final selected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF006B67) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? Colors.white : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFFCBD5E1),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(color: Color(0xFF0D5C58), height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: widget.onSignOut,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Switch between 10 requested views
  Widget _buildMainContent(List<DoctorPatientRecord> patientList) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView(patientList);
      case 1:
        return _buildMyPatientsView(patientList);
      case 2:
        return _buildPatientRecordsView(patientList);
      case 3:
        return _buildPatientMessagesView();
      case 4:
        return _buildEcgAnalysisView(patientList);
      case 5:
        return _buildLstmPredictionsView(patientList);
      case 6:
        return _buildRiskMonitoringView(patientList);
      case 7:
        return _buildPredictionHistoryView(patientList);
      case 8:
        return _buildNotificationsView();
      case 9:
        return _buildDoctorProfileView();
      case 10:
        return _buildSettingsView();
      default:
        return _buildDashboardView(patientList);
    }
  }

  // 1. Dashboard View
  Widget _buildDashboardView(List<DoctorPatientRecord> patientList) {
    final totalCount = patientList.length;
    final highRiskCount = patientList.where((p) => p.lstmRiskScore >= 0.75).length;
    final pendingCount = patientList.where((p) => p.doctorVerificationStatus == 'Pending Review').length;
    final clearedCount = patientList.where((p) => p.doctorVerificationStatus == 'Cleared').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard('Total Active Patients', '$totalCount', Icons.people_outline, const Color(0xFF006B67), wide),
                  _kpiCard('High Chagas Risk Alerts', '$highRiskCount', Icons.warning_amber_rounded, const Color(0xFFEF4444), wide),
                  _kpiCard('Pending Clinical Review', '$pendingCount', Icons.rate_review_outlined, const Color(0xFFF59E0B), wide),
                  _kpiCard('Cleared Patients', '$clearedCount', Icons.check_circle_outline_rounded, const Color(0xFF10B981), wide),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Urgent Risk Alert Banner
          if (highRiskCount > 0)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$highRiskCount Patient(s) Require Urgent Clinical Attention',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B)),
                        ),
                        const Text(
                          'LSTM model detected Chagas risk >= 75.0% with electrocardiographic abnormalities (RBBB / HRV depression).',
                          style: TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedIndex = 5),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Triage Board'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),

          // Recent Patient Stream
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Patient Risk Assessments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('View All Patients →', style: TextStyle(color: Color(0xFF006B67))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (patientList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.folder_open_rounded, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text(
                    'No patient records registered yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real ECG assessments and patient sign-ins from the Patient Portal will appear here automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patientList.take(4).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final record = patientList[idx];
                return _patientListTile(record);
              },
            ),
        ],
      ),
    );
  }

  // 2. My Patients View
  Widget _buildMyPatientsView(List<DoctorPatientRecord> patientList) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = patientList.where((p) {
      final matchesSearch = search.isEmpty ||
          p.patientDetails.fullName.toLowerCase().contains(search) ||
          p.patientDetails.city.toLowerCase().contains(search) ||
          p.patientDetails.gmailId.toLowerCase().contains(search);
      final matchesCat = _selectedCategoryFilter == 'All' || p.riskCategory.toLowerCase() == _selectedCategoryFilter.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search patients by name, email, or city...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ),
            const SizedBox(width: 14),
            DropdownButton<String>(
              value: _selectedCategoryFilter,
              onChanged: (val) => setState(() => _selectedCategoryFilter = val!),
              items: ['All', 'Critical High Risk', 'Elevated Risk', 'Moderate Risk', 'Low Risk']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        filtered.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Center(child: Text('No patient records found.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final record = filtered[idx];
                  return _patientListTile(record);
                },
              ),
      ],
    );
  }

  // 3. Patient Records View
  Widget _buildPatientRecordsView(List<DoctorPatientRecord> patientList) {
    final activeRecord = _selectedRecordForDetail ?? (patientList.isNotEmpty ? patientList.first : null);

    if (activeRecord == null) {
      return const Center(child: Text('No patient records available.'));
    }

    final notesController = TextEditingController(text: activeRecord.doctorNotes ?? '');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select patient dropdown bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Text('Select Patient Record: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: activeRecord.id,
                    onChanged: (id) {
                      setState(() {
                        _selectedRecordForDetail = patientList.firstWhere((p) => p.id == id);
                      });
                    },
                    items: patientList
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.patientDetails.fullName} (${p.riskCategory} • ${(p.lstmRiskScore * 100).toStringAsFixed(1)}%)'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Clinical Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activeRecord.patientDetails.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('${activeRecord.patientDetails.gender} • ${activeRecord.patientDetails.age} y/o • ${activeRecord.patientDetails.city}', style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: _getRiskColor(activeRecord.lstmRiskScore).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(activeRecord.riskCategory, style: TextStyle(color: _getRiskColor(activeRecord.lstmRiskScore), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Biomarker Readout Table
                const Text('Extracted Electrocardiographic Biomarkers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: activeRecord.numericalBiomarkers.entries.map((e) {
                    return Container(
                      width: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('${e.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Doctor Clinical Review Notes Form
                const Text('Doctor Clinical Review & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter clinical verification observations, prescribed Holter monitor status, or diagnostic notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        DoctorPortalService().updatePatientReview(
                          patientId: activeRecord.id,
                          notes: notesController.text.trim(),
                          status: 'Reviewed',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor clinical review saved successfully.')));
                        setState(() {});
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Review Notes'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006B67), foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Dedicated Patient Messages View
  Widget _buildPatientMessagesView() {
    final doctorEmail = widget.doctorProfile.email;

    return StreamBuilder<List<DoctorPatientMessage>>(
      stream: DoctorPatientMessagingService().getDoctorAllMessagesStream(doctorEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF006B67)));
        }

        final allMessages = snapshot.data ?? [];

        // Group messages by patient email
        final Map<String, List<DoctorPatientMessage>> patientConversations = {};
        for (final msg in allMessages) {
          patientConversations.putIfAbsent(msg.patientEmail, () => []).add(msg);
        }

        final patientServiceRecords = DoctorPortalService().patientRecords;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.forum_rounded, color: Color(0xFF006B67), size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Consultation Message Hub',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Real-time bi-directional messaging with registered patients across your clinical roster.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B67).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${patientConversations.length} Active Conversations',
                        style: const TextStyle(color: Color(0xFF006B67), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (patientConversations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Patient Messages Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'When patients send messages from their portal, your clinical consultation channels will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patientConversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final email = patientConversations.keys.elementAt(index);
                    final msgs = patientConversations[email]!;
                    final lastMsg = msgs.first;

                    // Match patient details
                    final matchedRecord = patientServiceRecords.firstWhere(
                      (p) => p.patientDetails.gmailId.trim().toLowerCase() == email.trim().toLowerCase(),
                      orElse: () => DoctorPatientRecord(
                        id: email,
                        profile: UserProfile(
                          name: lastMsg.senderRole == 'Patient' ? lastMsg.senderName : 'Patient',
                          email: email,
                          provider: 'Patient Portal',
                        ),
                        patientDetails: PatientDetails(
                          fullName: lastMsg.senderRole == 'Patient' ? lastMsg.senderName : 'Registered Patient',
                          gender: 'Unspecified',
                          dateOfBirth: DateTime(1980, 1, 1),
                          age: 40,
                          city: 'Online',
                          gmailId: email,
                        ),
                        lstmRiskScore: 0.2,
                        riskCategory: 'Low Risk',
                        modelConfidence: 0.9,
                        lastAssessed: lastMsg.timestamp,
                        numericalBiomarkers: {},
                        clinicalRecommendations: [],
                        topBiomarkerNotes: [],
                        doctorVerificationStatus: 'Active',
                      ),
                    );

                    final unreadCount = msgs.where((m) => m.senderRole == 'Patient' && !m.isRead).length;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: unreadCount > 0 ? const Color(0xFF006B67) : const Color(0xFFE2E8F0), width: unreadCount > 0 ? 1.5 : 1.0),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF006B67).withValues(alpha: 0.15),
                            child: const Icon(Icons.person, color: Color(0xFF006B67)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      matchedRecord.patientDetails.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                    ),
                                    if (unreadCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$unreadCount New',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last message: "${lastMsg.content}"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openPatientChat(matchedRecord),
                            icon: const Icon(Icons.chat_rounded, size: 16),
                            label: const Text('Open Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006B67),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // 4. ECG Analysis View
  Widget _buildEcgAnalysisView(List<DoctorPatientRecord> patientList) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('12-Lead ECG Signal Waveform & Biomarker Extractor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Real-time feature extraction pipeline for P-wave, QRS duration, and Heart Rate Variability (HRV).', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          // Simulated Lead Visualizer Container
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0A192F), borderRadius: BorderRadius.circular(16)),
            child: CustomPaint(
              painter: _EcgWavePainter(),
            ),
          ),
          const SizedBox(height: 24),

          // Lead Parameter Range Reference
          const Text('Extracted Parameter Reference Ranges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0)),
            children: const [
              TableRow(decoration: BoxDecoration(color: Color(0xFFF1F5F9)), children: [
                Padding(padding: EdgeInsets.all(10), child: Text('ECG Parameter', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(10), child: Text('Normal Baseline', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(10), child: Text('Chagas Cardiomyopathy Sign', style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              TableRow(children: [
                Padding(padding: EdgeInsets.all(10), child: Text('QRS Duration')),
                Padding(padding: EdgeInsets.all(10), child: Text('< 100 ms')),
                Padding(padding: EdgeInsets.all(10), child: Text('> 110 ms (RBBB widening)')),
              ]),
              TableRow(children: [
                Padding(padding: EdgeInsets.all(10), child: Text('PR Interval')),
                Padding(padding: EdgeInsets.all(10), child: Text('120 - 200 ms')),
                Padding(padding: EdgeInsets.all(10), child: Text('> 200 ms (1st Degree AV Block)')),
              ]),
              TableRow(children: [
                Padding(padding: EdgeInsets.all(10), child: Text('HRV SDNN')),
                Padding(padding: EdgeInsets.all(10), child: Text('> 50 ms')),
                Padding(padding: EdgeInsets.all(10), child: Text('< 35 ms (Depressed Autonomic Tone)')),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // 5. LSTM Predictions View
  Widget _buildLstmPredictionsView(List<DoctorPatientRecord> patientList) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LSTM Deep Neural Network Risk Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Sequence-to-vector recurrent neural network trained on multi-center 12-lead ECG signals.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          // Model Performance Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _modelStat('Model AUC-ROC', '0.942'),
                _modelStat('Sensitivity', '91.8%'),
                _modelStat('Specificity', '95.4%'),
                _modelStat('Sequence Length', '1,000 pts'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Top Predictive Feature Impact Weights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _featureBar('QRS Duration & RBBB Pattern', 0.88, const Color(0xFF006B67)),
          _featureBar('HRV SDNN Autonomic Tone', 0.76, const Color(0xFF0D9488)),
          _featureBar('PR Interval AV Conduction', 0.64, const Color(0xFF2DD4BF)),
          _featureBar('P-Wave Dispersion', 0.52, const Color(0xFF5EEAD4)),
        ],
      ),
    );
  }

  // 6. Risk Monitoring View
  Widget _buildRiskMonitoringView(List<DoctorPatientRecord> patientList) {
    final critical = patientList.where((p) => p.lstmRiskScore >= 0.80).toList();
    final elevated = patientList.where((p) => p.lstmRiskScore >= 0.60 && p.lstmRiskScore < 0.80).toList();
    final moderate = patientList.where((p) => p.lstmRiskScore >= 0.30 && p.lstmRiskScore < 0.60).toList();
    final low = patientList.where((p) => p.lstmRiskScore < 0.30).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-Time Patient Risk Triage Board', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _triageColumn('Critical (>80%)', critical, const Color(0xFFEF4444))),
                        const SizedBox(width: 12),
                        Expanded(child: _triageColumn('Elevated (60-79%)', elevated, const Color(0xFFF97316))),
                        const SizedBox(width: 12),
                        Expanded(child: _triageColumn('Moderate (30-59%)', moderate, const Color(0xFFEAB308))),
                        const SizedBox(width: 12),
                        Expanded(child: _triageColumn('Low (<30%)', low, const Color(0xFF10B981))),
                      ],
                    )
                  : Column(
                      children: [
                        _triageColumn('Critical (>80%)', critical, const Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        _triageColumn('Elevated (60-79%)', elevated, const Color(0xFFF97316)),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // 7. Prediction History View
  Widget _buildPredictionHistoryView(List<DoctorPatientRecord> patientList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Complete Prediction Audit Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Patient Name')),
                DataColumn(label: Text('Assessment Date')),
                DataColumn(label: Text('Risk Score')),
                DataColumn(label: Text('Risk Tier')),
                DataColumn(label: Text('Status')),
              ],
              rows: patientList.map((p) {
                return DataRow(cells: [
                  DataCell(Text(p.patientDetails.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${p.lastAssessed.year}-${p.lastAssessed.month.toString().padLeft(2, '0')}-${p.lastAssessed.day.toString().padLeft(2, '0')}')),
                  DataCell(Text('${(p.lstmRiskScore * 100).toStringAsFixed(1)}%')),
                  DataCell(Text(p.riskCategory, style: TextStyle(color: _getRiskColor(p.lstmRiskScore), fontWeight: FontWeight.bold))),
                  DataCell(Text(p.doctorVerificationStatus)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 8. Notifications View
  Widget _buildNotificationsView() {
    final doctorService = DoctorPortalService();
    final notifs = doctorService.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Clinical Notifications & Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                setState(() => doctorService.markAllNotificationsAsRead());
              },
              child: const Text('Mark All Read'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        notifs.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Center(child: Text('No active notifications.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final n = notifs[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.isRead ? Colors.white : const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: n.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF2DD4BF)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            n.type == 'alert' ? Icons.warning_rounded : Icons.info_outline,
                            color: n.type == 'alert' ? const Color(0xFFEF4444) : const Color(0xFF006B67),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(n.message, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ],
    );
  }

  // 9. Doctor Profile View
  Widget _buildDoctorProfileView() {
    final doc = DoctorPortalService();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFF006B67),
                  child: Icon(Icons.medical_services_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.doctorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(doc.doctorTitle, style: const TextStyle(color: Color(0xFF64748B))),
                      Text(doc.hospital, style: const TextStyle(color: Color(0xFF006B67), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showEditDoctorProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B67),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(height: 36),
            _profileDetailRow('Medical License', doc.medicalLicense),
            _profileDetailRow('Specialization', doc.specialization),
            _profileDetailRow('Email Address', doc.doctorEmail),
            _profileDetailRow('Direct Phone', doc.doctorPhone),
          ],
        ),
      ),
    );
  }

  void _showEditDoctorProfileDialog() {
    final doc = DoctorPortalService();
    final nameCtrl = TextEditingController(text: doc.doctorName);
    final titleCtrl = TextEditingController(text: doc.doctorTitle);
    final hospitalCtrl = TextEditingController(text: doc.hospital);
    final licenseCtrl = TextEditingController(text: doc.medicalLicense);
    final phoneCtrl = TextEditingController(text: doc.doctorPhone);
    final specCtrl = TextEditingController(text: doc.specialization);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF006B67)),
            SizedBox(width: 10),
            Text('Edit Doctor Profile'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Professional Title')),
              const SizedBox(height: 12),
              TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: 'Hospital / Institution')),
              const SizedBox(height: 12),
              TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'Medical License Number')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Clinical Specialization')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              setState(() {
                doc.doctorName = nameCtrl.text.trim();
                doc.doctorTitle = titleCtrl.text.trim();
                doc.hospital = hospitalCtrl.text.trim();
                doc.medicalLicense = licenseCtrl.text.trim();
                doc.doctorPhone = phoneCtrl.text.trim();
                doc.specialization = specCtrl.text.trim();
              });
              await doc.saveDoctorProfileToFirestore(doc.doctorEmail);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save to Database'),
          ),
        ],
      ),
    );
  }

  // 10. Settings View
  Widget _buildSettingsView() {
    final doc = DoctorPortalService();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Portal Configurations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('High Risk Instant Email Alerts'),
              subtitle: const Text('Send notification whenever patient risk score exceeds 75%'),
              value: doc.enableEmailAlerts,
              onChanged: (val) => setState(() => doc.enableEmailAlerts = val),
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Enable browser/mobile alert notifications'),
              value: doc.enablePushNotifications,
              onChanged: (val) => setState(() => doc.enablePushNotifications = val),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Widget _kpiCard(String title, String value, IconData icon, Color color, bool wide) {
    return Container(
      width: wide ? 210 : double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _patientListTile(DoctorPatientRecord record) {
    final riskColor = _getRiskColor(record.lstmRiskScore);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: riskColor.withValues(alpha: 0.15),
            child: Icon(Icons.person, color: riskColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.patientDetails.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${record.patientDetails.gender} • ${record.patientDetails.age} y/o • ${record.patientDetails.city}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(record.lstmRiskScore * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: riskColor)),
              Text(record.riskCategory, style: TextStyle(fontSize: 11, color: riskColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF006B67), size: 20),
            tooltip: 'Message Patient',
            onPressed: () => _openPatientChat(record),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: () {
              setState(() {
                _selectedRecordForDetail = record;
                _selectedIndex = 2; // Jump to Patient Records tab
              });
            },
          ),
        ],
      ),
    );
  }

  void _openPatientChat(DoctorPatientRecord record) {
    showDialog<void>(
      context: context,
      builder: (_) => DoctorPatientChatModal(
        patientEmail: record.patientDetails.gmailId,
        patientName: record.patientDetails.fullName,
        doctorEmail: widget.doctorProfile.email,
        doctorName: DoctorPortalService().doctorName,
        currentUserEmail: widget.doctorProfile.email,
        currentUserName: DoctorPortalService().doctorName,
        currentUserRole: 'Doctor',
      ),
    );
  }

  Widget _triageColumn(String title, List<DoctorPatientRecord> list, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${list.length})', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          const SizedBox(height: 12),
          ...list.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(p.patientDetails.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _modelStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006B67))),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _featureBar(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(val * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: val, color: color, backgroundColor: const Color(0xFFE2E8F0)),
        ],
      ),
    );
  }

  Widget _profileDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
          Expanded(child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  const _NavItem(this.title, this.icon);
}

const _navItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined),
  _NavItem('My Patients', Icons.people_outline),
  _NavItem('Patient Records', Icons.folder_open_outlined),
  _NavItem('Patient Messages', Icons.forum_rounded),
  _NavItem('ECG Analysis', Icons.show_chart_rounded),
  _NavItem('LSTM Predictions', Icons.psychology_outlined),
  _NavItem('Risk Monitoring', Icons.warning_amber_rounded),
  _NavItem('Prediction History', Icons.history_rounded),
  _NavItem('Notifications', Icons.notifications_none_rounded),
  _NavItem('Doctor Profile', Icons.person_outline_rounded),
  _NavItem('Settings', Icons.settings_outlined),
];

const _navTitles = [
  'Doctor Clinical Dashboard',
  'My Patient Roster',
  'Patient Medical Records',
  'Direct Patient Consultations & Messages',
  'ECG Signal Waveform Analysis',
  'LSTM Deep Learning Risk Engine',
  'Real-Time Patient Risk Triage Board',
  'Prediction Audit History Log',
  'Clinical Notifications & Alerts',
  'Doctor Professional Profile',
  'Doctor Portal Settings',
];

class _EcgWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;
    path.moveTo(0, midY);

    double x = 0;
    while (x < size.width) {
      path.lineTo(x + 20, midY);
      path.lineTo(x + 25, midY - 10); // P wave
      path.lineTo(x + 30, midY);
      path.lineTo(x + 35, midY + 15); // Q wave
      path.lineTo(x + 40, midY - 60); // R wave spike
      path.lineTo(x + 45, midY + 25); // S wave
      path.lineTo(x + 50, midY);
      path.lineTo(x + 65, midY - 18); // T wave
      path.lineTo(x + 80, midY);
      x += 100;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
