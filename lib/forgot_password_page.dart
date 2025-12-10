import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'dart:math';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailOrPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false, _otpSent = false, _otpVerified = false;
  String? _generatedOTP, _userEmail, _userPhone;
  Map<String, dynamic>? _foundUser;

  static const Color kPrimaryColor = Color(0xFF2E9D8A);
  static const Color kBackgroundColor = Color(0xFFF5F5DC);

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email.trim());
  bool _isValidPhone(String phone) =>
      RegExp(r"^[\+]?[1-9][\d]{0,15}$").hasMatch(phone.trim());
  bool _isValidPassword(String password) => RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])(?!.*\s).{8,}$',
  ).hasMatch(password);
  String _generateOTP() => (100000 + Random().nextInt(900000)).toString();

  Future<void> _findUserAndSendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final input = _emailOrPhoneController.text.trim();
      Map<String, dynamic>? user;
      if (_isValidEmail(input)) {
        user = await DatabaseHelper().getUserByEmail(input);
      } else if (_isValidPhone(input)) {
        user = await DatabaseHelper().getUserByPhone(input);
      }

      if (user == null) {
        _setLoading(false);
        return _showMessage(
          'No account found with this email or phone number.',
          isError: true,
        );
      }

      _generatedOTP = _generateOTP();
      _foundUser = user;
      _userEmail = user['email'];
      _userPhone = user['phone_number'];

      // Simulate OTP sending with proper feedback
      await _simulateOTPSending();

      _setLoading(false);
      setState(() => _otpSent = true);
      _showOTPSentDialog();
    } catch (e) {
      _setLoading(false);
      _showMessage('An error occurred. Please try again.', isError: true);
    }
  }

  void _verifyOTP() {
    final enteredOTP = _otpController.text.trim();
    if (enteredOTP.isEmpty) {
      return _showMessage('Please enter the OTP.', isError: true);
    }

    if (enteredOTP == _generatedOTP) {
      setState(() => _otpVerified = true);
      _showMessage('OTP verified successfully! Now set your new password.');
    } else {
      _showMessage('Invalid OTP. Please try again.', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      return _showMessage('Passwords do not match.', isError: true);
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper().updateUserPassword(
        _foundUser!['id'],
        _newPasswordController.text,
      );
      _setLoading(false);
      _showDialog(
        'Success',
        'Password reset successfully! You can now login with your new password.',
        Icons.check_circle,
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      _setLoading(false);
      _showMessage(
        'Failed to update password. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _simulateOTPSending() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  void _showOTPSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('OTP Sent Successfully'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OTP has been sent to:'),
            const SizedBox(height: 8),
            if (_userPhone != null) Text('📱 Phone: $_userPhone'),
            if (_userEmail != null) Text('📧 Email: $_userEmail'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Testing Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OTP: $_generatedOTP',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check console for details',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _setLoading(bool loading) => setState(() => _isLoading = loading);
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : kPrimaryColor,
      ),
    );
  }

  void _showDialog(
    String title,
    String content,
    IconData icon, {
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(key: _formKey, child: _buildCurrentStep()),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() => !_otpSent
      ? _buildEmailPhoneStep()
      : !_otpVerified
      ? _buildOTPStep()
      : _buildPasswordResetStep();

  Widget _buildEmailPhoneStep() => _buildStepColumn(
    Icons.lock_reset,
    'Reset Your Password',
    'Enter your email or phone number and we\'ll send you an OTP to reset your password.',
    [
      _buildTextField(
        _emailOrPhoneController,
        'Email or Phone Number',
        Icons.person,
        validator: (v) => v?.trim().isEmpty == true
            ? 'Please enter your email or phone number'
            : !_isValidEmail(v!) && !_isValidPhone(v)
            ? 'Please enter a valid email or phone number'
            : null,
      ),
      const SizedBox(height: 32),
      _buildButton('Send OTP', _isLoading ? null : _findUserAndSendOTP),
      const SizedBox(height: 24),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Back to Login',
          style: TextStyle(
            color: kPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

  Widget _buildOTPStep() => _buildStepColumn(
    Icons.verified_user,
    'Enter OTP',
    'Enter the 6-digit OTP sent to your phone and email.\n(Check console for testing OTP)',
    [
      TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
        decoration: _inputDecoration('OTP', '000000', Icons.lock_outline),
        validator: (v) => v?.trim().isEmpty == true
            ? 'Please enter the OTP'
            : v!.length != 6
            ? 'OTP must be 6 digits'
            : null,
      ),
      const SizedBox(height: 32),
      _buildButton('Verify OTP', _verifyOTP),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() {
          _otpSent = false;
          _otpController.clear();
        }),
        child: Text('Resend OTP', style: TextStyle(color: kPrimaryColor)),
      ),
    ],
  );

  Widget _buildPasswordResetStep() => _buildStepColumn(
    Icons.lock_outline,
    'Set New Password',
    'Enter your new password below.',
    [
      _buildTextField(
        _newPasswordController,
        'New Password',
        Icons.lock,
        obscure: true,
        validator: (v) => v?.isEmpty == true
            ? 'Please enter a password'
            : !_isValidPassword(v!)
            ? 'Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special'
            : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        _confirmPasswordController,
        'Confirm Password',
        Icons.lock_outline,
        obscure: true,
        validator: (v) => v?.isEmpty == true
            ? 'Please confirm your password'
            : v != _newPasswordController.text
            ? 'Passwords do not match'
            : null,
      ),
      const SizedBox(height: 32),
      _buildButton('Reset Password', _isLoading ? null : _resetPassword),
    ],
  );

  Widget _buildStepColumn(
    IconData icon,
    String title,
    String subtitle,
    List<Widget> children,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 40),
      Icon(icon, size: 80, color: kPrimaryColor),
      const SizedBox(height: 24),
      Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Text(
        subtitle,
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 40),
      ...children,
    ],
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: _inputDecoration(label, 'Enter $label', icon),
    validator: validator,
  );

  InputDecoration _inputDecoration(String label, String hint, IconData icon) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
      );

  Widget _buildButton(String text, VoidCallback? onPressed) => SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
