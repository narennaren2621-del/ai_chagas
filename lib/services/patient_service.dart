import '../models/patient_record.dart';
import '../models/user_profile.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();

  factory PatientService() {
    return _instance;
  }

  PatientService._internal();

  // Storage for patient details & doctor database
  final Map<String, PatientDetails> _patientDatabaseByEmail = {};
  final Map<String, UserProfile> _userProfilesByEmail = {};
  List<PatientRecordData>? _allDoctorPatientRecords;

  List<PatientRecordData> get _safeDoctorRecords {
    _allDoctorPatientRecords ??= <PatientRecordData>[];
    if (_allDoctorPatientRecords!.isEmpty) {
      _seedDefaultPatientDatabase();
    }
    return _allDoctorPatientRecords!;
  }

  PatientDetails _patientDetails = PatientDetails(
    fullName: 'Maria Santos',
    gender: 'Female',
    dateOfBirth: DateTime(1968, 4, 12),
    age: 58,
    city: 'São Paulo',
    gmailId: 'maria.santos@gmail.com',
  );

  UserProfile _userProfile = const UserProfile(
    name: 'Maria Santos',
    email: 'maria.santos@gmail.com',
    provider: 'Google account',
  );

  // Getters
  PatientDetails get patientDetails => _patientDetails;
  UserProfile get userProfile => _userProfile;

  /// Fetch all patient records for the Doctor Portal
  List<PatientRecordData> getAllPatientRecords() {
    return List.unmodifiable(_safeDoctorRecords);
  }

  /// Update doctor clinical notes and verification status
  void updateDoctorReview({
    required String patientId,
    required String notes,
    required String status,
  }) {
    final list = _safeDoctorRecords;
    final index = list.indexWhere((r) => r.id == patientId);
    if (index != -1) {
      final rec = list[index];
      rec.doctorNotes = notes;
      rec.doctorVerificationStatus = status;
      rec.doctorReviewedAt = DateTime.now();
    }
  }

  /// Check if patient details have already been submitted one-time for a specific email/gmail
  bool hasPatientDetails(String email) {
    final key = email.trim().toLowerCase();
    return _patientDatabaseByEmail.containsKey(key);
  }

  /// Retrieve saved patient details for an email
  PatientDetails? getPatientDetails(String email) {
    final key = email.trim().toLowerCase();
    return _patientDatabaseByEmail[key];
  }

  /// Initialize and activate session data for user profile & patient details
  void initialize(UserProfile profile, PatientDetails details) {
    _userProfile = profile;
    _patientDetails = details;

    final key = profile.email.trim().toLowerCase();
    _patientDatabaseByEmail[key] = details;
    _userProfilesByEmail[key] = profile;

    if (details.gmailId.isNotEmpty) {
      _patientDatabaseByEmail[details.gmailId.trim().toLowerCase()] = details;
    }

    // Add/update to doctor registry
    _registerPatientToDoctorRegistry(profile, details);
  }

  /// Update active patient details
  void updatePatientDetails({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    int? age,
    String? city,
    String? gmailId,
  }) {
    _patientDetails = PatientDetails(
      fullName: fullName ?? _patientDetails.fullName,
      gender: gender ?? _patientDetails.gender,
      dateOfBirth: dateOfBirth ?? _patientDetails.dateOfBirth,
      age: age ?? _patientDetails.age,
      city: city ?? _patientDetails.city,
      gmailId: gmailId ?? _patientDetails.gmailId,
    );

    final key = _userProfile.email.trim().toLowerCase();
    _patientDatabaseByEmail[key] = _patientDetails;
  }

  /// Update active user profile
  void updateUserProfile({
    String? name,
    String? email,
    String? provider,
    String? photoUrl,
  }) {
    _userProfile = UserProfile(
      name: name ?? _userProfile.name,
      email: email ?? _userProfile.email,
      provider: provider ?? _userProfile.provider,
      photoUrl: photoUrl ?? _userProfile.photoUrl,
    );

    final key = _userProfile.email.trim().toLowerCase();
    _userProfilesByEmail[key] = _userProfile;
  }

  void _registerPatientToDoctorRegistry(UserProfile profile, PatientDetails details) {
    final list = _safeDoctorRecords;
    final gmail = details.gmailId.trim().toLowerCase();

    final existingIndex = list.indexWhere((r) {
      final g = r.patientDetails.gmailId.trim().toLowerCase();
      return gmail.isNotEmpty && g == gmail;
    });

    if (existingIndex == -1) {
      list.insert(
        0,
        PatientRecordData(
          id: 'PAT-${1000 + list.length + 1}',
          profile: profile,
          patientDetails: details,
          lstmRiskScore: 0.74,
          riskCategory: 'Elevated Risk',
          modelConfidence: 0.91,
          lastAssessed: DateTime.now(),
          numericalBiomarkers: {
            'P_wave_duration': 64.5,
            'PR_interval': 185.0,
            'QRS_duration': 108.0,
            'QT_interval': 405.0,
            'HRV_SDNN': 32.0,
            'HRV_RMSSD': 24.5,
            'Heart_Rate': 82.0,
          },
          clinicalRecommendations: [
            'Schedule 24-hour Holter monitoring for ventricular arrhythmias.',
            'Perform 2D Echocardiogram to evaluate apical aneurysm.',
            'Order confirmatory Chagas IgG ELISA assay.',
          ],
          topBiomarkerNotes: [
            'QRS Widening (108 ms) suggesting RBBB pattern.',
            'Low HRV SDNN (32 ms) indicating depressed autonomic tone.',
            'Prolonged P-Wave duration (64.5 ms) indicating atrial conduction delay.',
          ],
          doctorVerificationStatus: 'Pending Review',
        ),
      );
    }
  }

  void _seedDefaultPatientDatabase() {
    _allDoctorPatientRecords ??= <PatientRecordData>[];
    if (_allDoctorPatientRecords!.isNotEmpty) return;

    final seedPatients = [
      PatientRecordData(
        id: 'PAT-1001',
        profile: const UserProfile(
          name: 'Carlos Oliveira',
          email: 'carlos.oliveira@gmail.com',
          provider: 'Google account',
        ),
        patientDetails: PatientDetails(
          fullName: 'Carlos Oliveira',
          gender: 'Male',
          dateOfBirth: DateTime(1964, 8, 22),
          age: 62,
          city: 'Belo Horizonte',
          gmailId: 'carlos.oliveira@gmail.com',
        ),
        lstmRiskScore: 0.88,
        riskCategory: 'Critical High Risk',
        modelConfidence: 0.94,
        lastAssessed: DateTime.now().subtract(const Duration(hours: 3)),
        numericalBiomarkers: {
          'P_wave_duration': 72.0,
          'PR_interval': 202.0,
          'QRS_duration': 118.0,
          'QT_interval': 420.0,
          'HRV_SDNN': 21.0,
          'HRV_RMSSD': 16.0,
          'Heart_Rate': 88.0,
        },
        clinicalRecommendations: [
          'Urgent Cardiology referral for Chagasic cardiomyopathy.',
          'Order urgent 48h Holter monitoring.',
          '2D Echo to assess left ventricular ejection fraction.',
        ],
        topBiomarkerNotes: [
          'Significant QRS widening (118 ms) with Right Bundle Branch Block (RBBB).',
          'Severely depressed HRV SDNN (21 ms) indicating cardiac autonomic denervation.',
          'PR Interval prolongation (202 ms) indicating 1st Degree AV Block.',
        ],
        doctorVerificationStatus: 'Action Required',
        doctorNotes: 'Patient scheduled for Holter monitor. High risk of apical aneurysm.',
      ),
      PatientRecordData(
        id: 'PAT-1002',
        profile: const UserProfile(
          name: 'Maria Santos',
          email: 'maria.santos@gmail.com',
          provider: 'Google account',
        ),
        patientDetails: PatientDetails(
          fullName: 'Maria Santos',
          gender: 'Female',
          dateOfBirth: DateTime(1968, 4, 12),
          age: 58,
          city: 'São Paulo',
          gmailId: 'maria.santos@gmail.com',
        ),
        lstmRiskScore: 0.74,
        riskCategory: 'Elevated Risk',
        modelConfidence: 0.91,
        lastAssessed: DateTime.now().subtract(const Duration(hours: 6)),
        numericalBiomarkers: {
          'P_wave_duration': 64.5,
          'PR_interval': 185.0,
          'QRS_duration': 108.0,
          'QT_interval': 405.0,
          'HRV_SDNN': 32.0,
          'HRV_RMSSD': 24.5,
          'Heart_Rate': 82.0,
        },
        clinicalRecommendations: [
          'Cardiology consultation recommended within 2 weeks.',
          'Order confirmatory Chagas IgG ELISA assay.',
          '24-hour ambulatory ECG monitoring.',
        ],
        topBiomarkerNotes: [
          'QRS Widening (108 ms) suggesting RBBB pattern.',
          'Low HRV SDNN (32 ms) indicating depressed autonomic tone.',
          'Prolonged P-Wave duration (64.5 ms).',
        ],
        doctorVerificationStatus: 'Pending Review',
      ),
      PatientRecordData(
        id: 'PAT-1003',
        profile: const UserProfile(
          name: 'Ana Rodrigues',
          email: 'ana.rodrigues@gmail.com',
          provider: 'Google account',
        ),
        patientDetails: PatientDetails(
          fullName: 'Ana Rodrigues',
          gender: 'Female',
          dateOfBirth: DateTime(1989, 11, 5),
          age: 36,
          city: 'Campinas',
          gmailId: 'ana.rodrigues@gmail.com',
        ),
        lstmRiskScore: 0.18,
        riskCategory: 'Low Risk',
        modelConfidence: 0.96,
        lastAssessed: DateTime.now().subtract(const Duration(days: 1)),
        numericalBiomarkers: {
          'P_wave_duration': 48.0,
          'PR_interval': 138.0,
          'QRS_duration': 84.0,
          'QT_interval': 370.0,
          'HRV_SDNN': 62.0,
          'HRV_RMSSD': 45.0,
          'Heart_Rate': 71.0,
        },
        clinicalRecommendations: [
          'Low probability of Chagas cardiomyopathy based on normal ECG.',
          'Routine annual checkup.',
        ],
        topBiomarkerNotes: [
          'Normal QRS duration (84 ms).',
          'Healthy HRV SDNN (62 ms) within baseline.',
        ],
        doctorVerificationStatus: 'Cleared',
        doctorNotes: 'Normal baseline sinus rhythm. Retest in 12 months.',
      ),
      PatientRecordData(
        id: 'PAT-1004',
        profile: const UserProfile(
          name: 'Lucas Ferreira',
          email: 'lucas.ferreira@gmail.com',
          provider: 'Google account',
        ),
        patientDetails: PatientDetails(
          fullName: 'Lucas Ferreira',
          gender: 'Male',
          dateOfBirth: DateTime(1976, 2, 18),
          age: 50,
          city: 'Goiânia',
          gmailId: 'lucas.ferreira@gmail.com',
        ),
        lstmRiskScore: 0.45,
        riskCategory: 'Moderate Risk',
        modelConfidence: 0.89,
        lastAssessed: DateTime.now().subtract(const Duration(days: 2)),
        numericalBiomarkers: {
          'P_wave_duration': 58.0,
          'PR_interval': 168.0,
          'QRS_duration': 96.0,
          'QT_interval': 390.0,
          'HRV_SDNN': 44.0,
          'HRV_RMSSD': 32.0,
          'Heart_Rate': 76.0,
        },
        clinicalRecommendations: [
          'Follow-up ECG in 6 months.',
          'Perform standard Chagas screening ELISA if travel history to endemic regions.',
        ],
        topBiomarkerNotes: [
          'Borderline QRS duration (96 ms).',
          'Moderate HRV SDNN (44 ms).',
        ],
        doctorVerificationStatus: 'Pending Review',
      ),
    ];

    for (final p in seedPatients) {
      _allDoctorPatientRecords!.add(p);
      final key = p.profile.email.trim().toLowerCase();
      _patientDatabaseByEmail[key] = p.patientDetails;
      _userProfilesByEmail[key] = p.profile;
    }
  }
}
