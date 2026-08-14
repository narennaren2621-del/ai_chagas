import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/patient_service.dart';

class EditPatientInfoPage extends StatefulWidget {
  const EditPatientInfoPage({
    required this.profile,
    required this.patientDetails,
    required this.onSave,
    super.key,
  });

  final UserProfile profile;
  final PatientDetails patientDetails;
  final Function(PatientDetails) onSave;

  @override
  State<EditPatientInfoPage> createState() => _EditPatientInfoPageState();
}

class _EditPatientInfoPageState extends State<EditPatientInfoPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _cityController;
  late TextEditingController _gmailController;
  late TextEditingController _ageController;
  late String _selectedGender;
  late DateTime _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.patientDetails.fullName);
    _cityController = TextEditingController(text: widget.patientDetails.city);
    _gmailController =
        TextEditingController(text: widget.patientDetails.gmailId);
    _ageController =
        TextEditingController(text: widget.patientDetails.age.toString());
    _selectedGender = widget.patientDetails.gender;
    _selectedDateOfBirth = widget.patientDetails.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cityController.dispose();
    _gmailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _ageController.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  void _saveChanges() {
    if (_fullNameController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _gmailController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedDetails = PatientDetails(
      fullName: _fullNameController.text,
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth,
      age: int.parse(_ageController.text),
      city: _cityController.text,
      gmailId: _gmailController.text,
    );

    widget.onSave(updatedDetails);
    PatientService().updatePatientDetails(
      fullName: updatedDetails.fullName,
      gender: updatedDetails.gender,
      dateOfBirth: updatedDetails.dateOfBirth,
      age: updatedDetails.age,
      city: updatedDetails.city,
      gmailId: updatedDetails.gmailId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient information updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(updatedDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient Information'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF123230),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              _buildTextField(
                label: 'Full Name',
                controller: _fullNameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 18),

              // Email
              _buildTextField(
                label: 'Email Address',
                controller: TextEditingController(text: widget.profile.email),
                hint: widget.profile.email,
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 18),

              // Gender
              _buildGenderSelector(),
              const SizedBox(height: 18),

              // Date of Birth
              _buildDateField(),
              const SizedBox(height: 18),

              // Age
              _buildTextField(
                label: 'Age',
                controller: _ageController,
                hint: 'Age will auto-calculate',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 18),

              // City
              _buildTextField(
                label: 'City',
                controller: _cityController,
                hint: 'Enter your city',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 18),

              // Gmail ID
              _buildTextField(
                label: 'Gmail ID',
                controller: _gmailController,
                hint: 'Enter your Gmail ID',
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B67),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF006B67),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF006B67),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF123230),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF006B67),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF006B67),
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF123230),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF123230),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedGender,
            isExpanded: true,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF123230),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF123230),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF006B67),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDateOfBirth.day}/${_selectedDateOfBirth.month}/${_selectedDateOfBirth.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF123230),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
