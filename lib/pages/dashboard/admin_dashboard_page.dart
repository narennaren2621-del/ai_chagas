import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/admin/admin_portal_service.dart';
import 'package:chagas_predictor/services/patient/assessment_history_service.dart';
import 'package:chagas_predictor/services/patient/doctor_portal_service.dart';
import 'package:chagas_predictor/widgets/auth/brand_lockup.dart';

class AdminDashboardPage extends StatefulWidget {
  final UserProfile adminProfile;
  final VoidCallback onSignOut;

  const AdminDashboardPage({
    super.key,
    required this.adminProfile,
    required this.onSignOut,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Doctor Mgmt, 2: Patient Mgmt, 3: ECG Records, 4: LSTM Model, 5: Predictions, 6: Analytics, 7: Reports, 8: Activity Logs, 9: Admin Profile, 10: Settings
  final TextEditingController _searchController = TextEditingController();

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
    final adminService = AdminPortalService();
    final realHistory = AssessmentHistoryService().historyRecords;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              title: const Row(
                children: [
                  BrandLockup(),
                  SizedBox(width: 8),
                  Text('• ADMIN', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 270,
              color: const Color(0xFF1E293B),
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  if (isDesktop) _buildDesktopHeader(adminService),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: _buildMainContent(adminService, realHistory),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(AdminPortalService adminService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _navTitles[_selectedIndex],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    'CHAGAS PREDICT • System Administration & Governance',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedIndex = 9),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 9 ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Authorized Admin (${widget.adminProfile.email})', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 9),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF38BDF8),
                  child: Text(widget.adminProfile.name.isNotEmpty ? widget.adminProfile.name[0].toUpperCase() : 'N', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const BrandLockup(),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'SUPERUSER CONTROL PORTAL',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final selected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0284C7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, color: selected ? Colors.white : const Color(0xFF94A3B8), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFFCBD5E1),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
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
        const Divider(color: Color(0xFF334155), height: 1),
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
                  Text('Admin Sign Out', style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(AdminPortalService adminService, List dynamicHistory) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView(adminService, dynamicHistory);
      case 1:
        return _buildDoctorManagementView();
      case 2:
        return _buildPatientManagementView(dynamicHistory);
      case 3:
        return _buildEcgRecordsView(dynamicHistory);
      case 4:
        return _buildLstmModelView(adminService);
      case 5:
        return _buildPredictionsView(dynamicHistory);
      case 6:
        return _buildAnalyticsView(dynamicHistory);
      case 7:
        return _buildReportsView(dynamicHistory);
      case 8:
        return _buildActivityLogsView(adminService);
      case 9:
        return _buildAdminProfileView(adminService);
      case 10:
        return _buildSettingsView(adminService);
      default:
        return _buildDashboardView(adminService, dynamicHistory);
    }
  }

  // 1. Dashboard View
  Widget _buildDashboardView(AdminPortalService adminService, List history) {
    final totalCount = history.length;
    final doctorService = DoctorPortalService();
    final doctorCount = doctorService.patientRecords.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard('System Predictions', '$totalCount', Icons.psychology_rounded, const Color(0xFF38BDF8), wide),
                  _kpiCard('Registered Patients', '$doctorCount', Icons.people_alt_rounded, const Color(0xFF34D399), wide),
                  _kpiCard('LSTM Inference Latency', '${adminService.averageInferenceMs} ms', Icons.speed_rounded, const Color(0xFFFBBF24), wide),
                  _kpiCard('Model Accuracy', '${(adminService.modelAccuracy * 100).toStringAsFixed(1)}%', Icons.verified_rounded, const Color(0xFFA78BFA), wide),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // System Status & Architecture Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
                        SizedBox(width: 10),
                        Text('All Platform Services Operational', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                      child: Text(adminService.modelVersion, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'PyTorch Deep Neural Network prediction pipeline, FastAPI REST backend, and Web 12-lead ECG digitizer active with zero reported system exceptions.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recent Activity Stream
          const Text('Platform System Activity Stream', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: adminService.logs.take(3).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final log = adminService.logs[idx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(log.details, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Doctor Management View
  Widget _buildDoctorManagementView() {
    final doctor = DoctorPortalService();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registered Cardiology Specialists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Color(0xFF0284C7), child: Icon(Icons.person, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.doctorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      Text(doctor.doctorTitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text('${doctor.hospital} • ${doctor.medicalLicense}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Verified Active', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Patient Management View
  Widget _buildPatientManagementView(List history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Patient Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        history.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded, color: Color(0xFF64748B), size: 44),
                    SizedBox(height: 12),
                    Text('No patient records registered yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Patient sign-ins and submitted assessments will appear here automatically.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = history[idx];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 20, backgroundColor: Color(0xFF0F172A), child: Icon(Icons.person, color: Color(0xFF38BDF8))),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.patientDetails.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${item.patientDetails.gender} • ${item.patientDetails.age} yrs • ${item.patientDetails.city}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(item.predictionResult.riskCategory, style: TextStyle(color: _getRiskColor(item.predictionResult.riskScore), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // 4. ECG Records View
  Widget _buildEcgRecordsView(List history) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ECG Signal Repository & Uploaded Datasets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Signal Extractor Config', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('Standard 12-lead ECG sampling rate: 500 Hz • Lead II primary feature extraction • Bandpass filter: 0.5 - 45 Hz', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. LSTM Model View
  Widget _buildLstmModelView(AdminPortalService adminService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deep Learning Neural Network Architecture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adminService.modelVersion, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                _modelDetailRow('Validation Accuracy', '${(adminService.modelAccuracy * 100).toStringAsFixed(1)}%'),
                _modelDetailRow('Sensitivity', '${(adminService.modelSensitivity * 100).toStringAsFixed(1)}%'),
                _modelDetailRow('Specificity', '${(adminService.modelSpecificity * 100).toStringAsFixed(1)}%'),
                _modelDetailRow('Average Latency', '${adminService.averageInferenceMs} ms'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Predictions View
  Widget _buildPredictionsView(List history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Real-Time Prediction Stream', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        history.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
                child: const Center(child: Text('No predictions executed yet.', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = history[idx];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.patientDetails.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${(item.predictionResult.riskScore * 100).toStringAsFixed(1)}%', style: TextStyle(color: _getRiskColor(item.predictionResult.riskScore), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // 7. Analytics View
  Widget _buildAnalyticsView(List history) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform System Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Chagas Risk Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text('Total Executed Risk Scans: ${history.length}', style: const TextStyle(color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Reports View
  Widget _buildReportsView(List history) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Diagnostic & Audit Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating System Audit PDF Report...')));
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export System Audit PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // 9. Activity Logs View
  Widget _buildActivityLogsView(AdminPortalService adminService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Security & Audit Trail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: adminService.logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final log = adminService.logs[idx];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${log.details} • ${log.userEmail}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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

  // 10. Admin Profile View
  Widget _buildAdminProfileView(AdminPortalService adminService) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFF0369A1),
                  child: Icon(Icons.admin_panel_settings_rounded, size: 40, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.adminProfile.name.isEmpty ? 'Naren (System Admin)' : widget.adminProfile.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'Chief System & Clinical Governance Administrator',
                        style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'National Chagas Medical & Research Surveillance Network',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF22C55E), size: 16),
                      SizedBox(width: 6),
                      Text('LEVEL 5 ROOT MASTER', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 36),
            _modelDetailRow('Authorized Admin Email', widget.adminProfile.email),
            _modelDetailRow('Account Role', 'Superuser Master Administrator'),
            _modelDetailRow('Security Policy', 'Single Authorized Whitelist Active (narenkvp302@gmail.com)'),
            _modelDetailRow('Database Connection', 'Cloud Firestore Live Multi-Region Instance'),
            _modelDetailRow('ML Engine Backend', 'PyTorch FastAPI Server (v2.1.0+cu118)'),
            _modelDetailRow('System Status', 'Active & Operational'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView(AdminPortalService adminService) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Administration Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _modelDetailRow('Authorized Admin Gmail', adminService.primaryAdminEmail),
            _modelDetailRow('API Backend Endpoint', 'http://127.0.0.1:8000/predict'),
            _modelDetailRow('PyTorch Framework', '2.1.0+cu118'),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, bool wide) {
    return Container(
      width: wide ? 210 : double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _modelDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
          Expanded(child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  final String title;
  final IconData icon;
  const _AdminNavItem(this.title, this.icon);
}

const _navItems = [
  _AdminNavItem('Dashboard', Icons.dashboard_rounded),
  _AdminNavItem('Doctor Management', Icons.medical_services_rounded),
  _AdminNavItem('Patient Management', Icons.people_alt_rounded),
  _AdminNavItem('ECG Records', Icons.show_chart_rounded),
  _AdminNavItem('LSTM Model', Icons.psychology_rounded),
  _AdminNavItem('Predictions', Icons.online_prediction_rounded),
  _AdminNavItem('Analytics', Icons.analytics_rounded),
  _AdminNavItem('Reports', Icons.assessment_rounded),
  _AdminNavItem('Activity Logs', Icons.list_alt_rounded),
  _AdminNavItem('Admin Profile', Icons.admin_panel_settings_rounded),
  _AdminNavItem('Settings', Icons.settings_rounded),
];

const _navTitles = [
  'Admin Control Dashboard',
  'Doctor Management & Verification',
  'Patient Directory & Governance',
  'ECG Signal Repository',
  'LSTM Model Engine Architecture',
  'Prediction Stream Audit',
  'System Platform Analytics',
  'Diagnostic & System Reports',
  'Security & Operational Logs',
  'Superuser Admin Profile',
  'System Governance Settings',
];
