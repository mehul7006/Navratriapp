import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class MemberRegistrationScreen extends StatefulWidget {
  const MemberRegistrationScreen({super.key});

  @override
  State<MemberRegistrationScreen> createState() => _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  String _selectedUserType = 'user';
  bool _isLoading = false;
  List<Map<String, dynamic>> _existingMembers = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final membersResult = await DatabaseHelper.query(
        'SELECT id, house_number, name, mobile_number, user_type FROM users WHERE user_type != \'organizer\' ORDER BY house_number'
      );
      setState(() => _existingMembers = membersResult.map((row) => Map<String, dynamic>.from(row)).toList());
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _registerMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if house number already exists
      final existingResult = await DatabaseHelper.query(
        'SELECT id FROM users WHERE house_number = @house',
        substitutionValues: {'house': _houseController.text.trim()},
      );

      if (existingResult.isNotEmpty) {
        _showError('House number already registered!');
        setState(() => _isLoading = false);
        return;
      }

      // Register new member
      final userId = await DatabaseHelper.registerUser(
        houseNumber: _houseController.text.trim(),
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        userType: _selectedUserType,
      );

      if (userId > 0) {
        _showSuccess('Member registered successfully!');
        _formKey.currentState!.reset();
        _loadMembers();
      } else {
        _showError('Registration failed');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Register Member'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Registration Form
            _buildRegistrationForm(),
            const SizedBox(height: 24),
            
            // Existing Members List
            const Text(
              'Registered Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildMembersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New Member Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // User Type Selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Resident', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: 'user',
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value!),
                    activeColor: AppTheme.goldPrimary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Sponsor', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: 'sponsor',
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value!),
                    activeColor: AppTheme.goldPrimary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // House Number
            _buildTextField(
              controller: _houseController,
              label: 'House Number *',
              hint: 'e.g., A-402, B-101, C-303',
              icon: Icons.home,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'Enter member name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Mobile Number
            _buildTextField(
              controller: _mobileController,
              label: 'Mobile Number *',
              hint: '10-digit mobile number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedUserType == 'user' 
                  ? 'This mobile number will be the user password'
                  : 'This will be used for contact',
              style: const TextStyle(fontSize: 11, color: AppTheme.cyanAccent),
            ),
            const SizedBox(height: 20),

            // Register Button
            ElevatedButton(
              onPressed: _isLoading ? null : _registerMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: AppTheme.purpleDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.purpleDark),
                      ),
                    )
                  : const Text(
                      'REGISTER MEMBER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (controller == _mobileController && value.length != 10) {
          return 'Enter valid 10-digit mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildMembersList() {
    if (_existingMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.purpleCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No members registered yet',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _existingMembers.length,
        itemBuilder: (context, index) {
          final member = _existingMembers[index];
          return _buildMemberTile(member);
        },
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final userType = member['user_type'] ?? 'user';
    final typeColor = userType == 'sponsor' ? Colors.orange : AppTheme.goldPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.purpleDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                member['house_number'] ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.purpleDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mobile: ${member['mobile_number'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              userType.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
