import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _houseController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _mobileController = TextEditingController(text: user?['mobile_number'] ?? '');
    _houseController = TextEditingController(text: user?['house_number'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldPrimary))
                  : const Text('Save', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatar(user),
            const SizedBox(height: 24),
            _buildField('House Number', _houseController, Icons.home, enabled: false),
            const SizedBox(height: 16),
            _buildField('Full Name', _nameController, Icons.person, enabled: _isEditing),
            const SizedBox(height: 16),
            _buildField('Mobile Number', _mobileController, Icons.phone, enabled: _isEditing, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTypeBadge(user),
            const SizedBox(height: 32),
            if (_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = user?['name'] ?? '';
                      _mobileController.text = user?['mobile_number'] ?? '';
                    });
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic>? user) {
    final name = user?['name'] ?? 'U';
    return Container(
      width: 100, height: 100,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.goldGradient),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.purpleDark),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.white : Colors.white70),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: enabled ? AppTheme.goldPrimary : Colors.white38),
        filled: true,
        fillColor: enabled ? AppTheme.purpleCard : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      ),
    );
  }

  Widget _buildTypeBadge(Map<String, dynamic>? user) {
    final userType = user?['user_type'] ?? 'user';
    final color = userType == 'organizer' ? Colors.purple : userType == 'sponsor' ? Colors.blue : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(userType.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and mobile are required'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?['id'];
      final result = await DatabaseHelper.updateProfile(
        userId,
        name: _nameController.text,
        mobile: _mobileController.text,
      );
      if (result != null) {
        authProvider.updateUser(result);
        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }
}
