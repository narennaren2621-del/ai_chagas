import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/patient_service.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({
    required this.profile,
    required this.onCompleted,
    super.key,
  });

  final UserProfile profile;
  final Widget Function(PatientDetails details) onCompleted;

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _gmailController;
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.name);
    _gmailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _gmailController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  int _ageFromDateOfBirth(DateTime dateOfBirth) {
    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    if (DateTime(today.year, dateOfBirth.month, dateOfBirth.day).isAfter(today)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDateOfBirth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(DateTime.now().year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateOfBirth = selected;
      _ageController.text = _ageFromDateOfBirth(selected).toString();
    });
  }

  void _continueToDashboard() {
    if (!_formKey.currentState!.validate() || _dateOfBirth == null) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select the patient\'s date of birth.'),
        ));
      }
      return;
    }
    final details = PatientDetails(
      gender: _gender!,
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gmailId: _gmailController.text.trim(),
      city: _cityController.text.trim(),
      age: int.parse(_ageController.text),
    );
    PatientService().initialize(widget.profile, details);
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => widget.onCompleted(details),
    ));
  }

  String _formattedDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF294846))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7FAFA),
          surfaceTintColor: Colors.transparent,
          title: const Text('Patient details'),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Patient details',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF123230))),
                        const SizedBox(height: 8),
                        const Text(
                            'Please complete these details before accessing the dashboard.',
                            style: TextStyle(color: Color(0xFF68807E))),
                        const SizedBox(height: 26),
                        _label('Gender'),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              hintText: 'Select gender'),
                          items: const [
                            'Female',
                            'Male',
                            'Non-binary',
                            'Prefer not to say'
                          ]
                              .map((gender) => DropdownMenuItem(
                                  value: gender, child: Text(gender)))
                              .toList(),
                          onChanged: (value) => setState(() => _gender = value),
                          validator: (value) =>
                              value == null ? 'Please select a gender' : null,
                        ),
                        const SizedBox(height: 16),
                        _label('Full name'),
                        TextFormField(
                            controller: _fullNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                                hintText: 'Enter the patient\'s full name'),
                            validator: (value) =>
                                value == null || value.trim().length < 2
                                    ? 'Please enter a full name'
                                    : null),
                        const SizedBox(height: 16),
                        _label('Date of birth'),
                        InkWell(
                            onTap: _selectDateOfBirth,
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                                decoration: const InputDecoration(
                                    prefixIcon:
                                        Icon(Icons.calendar_today_outlined)),
                                child: Text(_dateOfBirth == null
                                    ? 'Select date of birth'
                                    : _formattedDate(_dateOfBirth!)))),
                        const SizedBox(height: 16),
                        _label('Gmail ID'),
                        TextFormField(
                            controller: _gmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                                hintText: 'patient@gmail.com'),
                            validator: (value) => value == null ||
                                    !value.trim().contains('@')
                                ? 'Enter a valid email / Gmail address'
                                : null),
                        const SizedBox(height: 16),
                        _label('City'),
                        TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.location_city_outlined),
                                hintText: 'Enter city'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter a city'
                                    : null),
                        const SizedBox(height: 16),
                        _label('Age'),
                        TextFormField(
                            controller: _ageController,
                            readOnly: true,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.cake_outlined),
                                hintText: 'Calculated from date of birth'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Select a date of birth to calculate age'
                                : null),
                        const SizedBox(height: 26),
                        SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                                onPressed: _continueToDashboard,
                                child: const Text('Continue to dashboard'))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
