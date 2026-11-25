import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/tracker_service.dart';
import 'employee_duty_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String employeeId;
  final bool isForcedFirstTime;

  const ChangePasswordScreen({
    super.key,
    required this.employeeId,
    this.isForcedFirstTime = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final tracker = TrackerService();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isSaving = false;

  Future<void> _updatePassword() async {
    if (_newPassCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields.')),
      );
      return;
    }

    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await tracker.updatePasswordForEmployee(widget.employeeId, _newPassCtrl.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permanent password saved! Stored in database & valid for next 90 days.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeDutyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isForcedFirstTime ? 'Create Permanent Password' : 'Change Password'),
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
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isForcedFirstTime ? 'Security Setup: Set New Password' : 'Password Management',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Per corporate security policy, passwords expire every 3 months (90 days). Please choose a password you will remember.',
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
                        if (!widget.isForcedFirstTime) ...[
                          TextField(
                            controller: _oldPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextField(
                          controller: _newPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'New Password (Min 6 chars)', prefixIcon: Icon(Icons.lock)),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _confirmPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock)),
                        ),
                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _updatePassword,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save Password & Enter App'),
                        ),
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

