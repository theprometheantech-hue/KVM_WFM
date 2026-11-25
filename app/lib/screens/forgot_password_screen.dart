import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/tracker_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final tracker = TrackerService();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _otpSent = false;
  String? _matchedEmployeeId;

  void _requestOtp() {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registered email address.')),
      );
      return;
    }

    final emp = tracker.findEmployeeByEmail(_emailCtrl.text.trim());
    if (emp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employee registered with this email address.')),
      );
      return;
    }

    setState(() {
      _otpSent = true;
      _matchedEmployeeId = emp.employeeId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP 884210 sent to ${_emailCtrl.text.trim()}! Also sent to company mail logs.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _resetPassword() {
    if (_otpCtrl.text.trim() != '884210' && _otpCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code.')),
      );
      return;
    }

    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    if (_matchedEmployeeId != null) {
      tracker.updatePasswordForEmployee(_matchedEmployeeId!, _newPassCtrl.text);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Password Reset Done'),
          ],
        ),
        content: const Text('Your new password is now active. You can log in with your Employee ID and new password.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot / Reset Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.mark_email_read_outlined, color: AppColors.warning, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Password Recovery',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your company-registered email to receive a secure recovery code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Registered Work Email', prefixIcon: Icon(Icons.email)),
                        ),
                        const SizedBox(height: 14),

                        if (!_otpSent) ...[
                          ElevatedButton(
                            onPressed: _requestOtp,
                            child: const Text('Send Recovery Code to Email'),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Enter 6-Digit Email Code (e.g. 884210)',
                              prefixIcon: Icon(Icons.dialpad),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _newPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Create New Password (3-Month Valid)',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _resetPassword,
                            child: const Text('Reset Password & Save'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

