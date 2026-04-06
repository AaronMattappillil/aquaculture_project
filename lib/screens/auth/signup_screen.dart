import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pondLengthController = TextEditingController();
  final _pondWidthController = TextEditingController();
  final _pondDepthController = TextEditingController();
  final _fishSpeciesController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pondLengthController.dispose();
    _pondWidthController.dispose();
    _pondDepthController.dispose();
    _fishSpeciesController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double? _parsePositiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'pond_length': _parsePositiveDouble(_pondLengthController.text) ?? 10.0,
        'pond_width': _parsePositiveDouble(_pondWidthController.text) ?? 10.0,
        'pond_height': _parsePositiveDouble(_pondDepthController.text) ?? 2.0,
        'fish_species': _fishSpeciesController.text.trim().isEmpty ? 'Tilapia' : _fishSpeciesController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      };

      await ref.read(authServiceProvider).signup(payload);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully! Please login.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader('Owner Information'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _firstNameController, label: 'First Name')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _lastNameController, label: 'Last Name')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined),
                const SizedBox(height: 16),
                _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined),
                
                const SizedBox(height: 32),
                _buildHeader('Initial Pond Configuration'),
                const SizedBox(height: 16),
                _buildTextField(controller: _fishSpeciesController, label: 'Fish Species', icon: Icons.set_meal_outlined),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _pondLengthController, label: 'Length (m)', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _pondWidthController, label: 'Width (m)', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _pondDepthController, label: 'Depth (m)', keyboardType: TextInputType.number)),
                  ],
                ),
                
                const SizedBox(height: 32),
                _buildHeader('Account Security'),
                const SizedBox(height: 16),
                _buildTextField(controller: _usernameController, label: 'Username', icon: Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, obscure: true),
                const SizedBox(height: 16),
                _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_outline, obscure: true),
                
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account & Initialize Pond', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: accentTeal,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryText),
        prefixIcon: icon != null ? Icon(icon, color: accentTeal.withValues(alpha: 0.5), size: 20) : null,
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentTeal)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}
