import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/language_service.dart';
import '../data/services/tracker_service.dart';
import '../data/services/api_service.dart';
import 'employee_duty_screen.dart';
import 'supervisor_monitor_screen.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final tracker = TrackerService();
  String _selectedRole = 'employee'; // 'employee' or 'admin'
  bool _rememberMe = true;

  final _loginIdCtrl = TextEditingController(text: '');
  final _passwordCtrl = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    LanguageService().addListener(_onLangChange);
    tracker.loadSavedCredentials();
    _loadRememberedId();
  }

  Future<void> _loadRememberedId() async {
    final savedId = await tracker.getSavedLoginId();
    if (savedId != null && savedId.isNotEmpty && mounted) {
      setState(() {
        _loginIdCtrl.text = savedId;
      });
    }
  }

  @override
  void dispose() {
    LanguageService().removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  void _handleLogin() async {
    final id = _loginIdCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (id.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == 'admin'
                ? 'Please enter Admin ID/Email and Master Password.'
                : 'Please enter Employee ID/Mobile/Email and Password.',
          ),
        ),
      );
      return;
    }

    if (_selectedRole == 'admin') {
      // Secure Admin Authentication
      final adminUser = tracker.findEmployeeByLogin(id, pass);
      final isAdminMatch = (adminUser != null && adminUser.employeeId == 'ADMIN-01') ||
          ((id.toLowerCase() == 'admin@kvm.com' || id.toLowerCase() == 'admin-01' || id.toLowerCase() == 'admin') &&
              pass == 'Password123');

      if (isAdminMatch) {
        if (_rememberMe) {
          await tracker.saveLoginSession(
            role: 'supervisor',
            userId: 'ADMIN-01',
            userName: 'System Administrator',
            rememberId: true,
          );
        } else {
          tracker.currentRole = 'supervisor';
          tracker.activeEmployeeName = 'System Administrator';
          tracker.activeEmployeeId = 'ADMIN-01';
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SupervisorMonitorScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Admin credentials. Access denied.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // Secure Employee Authentication
      final emp = tracker.findEmployeeByLogin(id, pass);
      if (emp != null) {
        if (emp.employeeId == 'ADMIN-01') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This is an Admin account. Please switch to "Admin / Supervisor" tab to log in.'),
              backgroundColor: Colors.amber,
            ),
          );
          return;
        }

        // Check 1: Mandatory first-time password change
        if (emp.isTemporaryPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(employeeId: emp.employeeId, isForcedFirstTime: true),
            ),
          );
          return;
        }

        // Check 2: 90-day password expiry rule
        if (emp.isPasswordExpired) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Password Expired (90-Day Policy)'),
              content: const Text('Your corporate password has expired (3-month policy). Please set a new password to proceed.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordScreen(employeeId: emp.employeeId, isForcedFirstTime: false),
                      ),
                    );
                  },
                  child: const Text('Change Password Now'),
                ),
              ],
            ),
          );
          return;
        }

        // Successful employee login
        // Match station by ID first, then by name
        String targetStationId = 'STN-001';
        if (emp.assignedStationId != null && emp.assignedStationId!.isNotEmpty) {
          final idMatch = tracker.stations.where((s) => s.stationId == emp.assignedStationId);
          if (idMatch.isNotEmpty) {
            targetStationId = idMatch.first.stationId;
          } else if (emp.assignedStationName != null && emp.assignedStationName!.isNotEmpty) {
            final nameMatch = tracker.stations.where(
              (s) => s.stationName.toLowerCase().contains(emp.assignedStationName!.toLowerCase()) ||
                     emp.assignedStationName!.toLowerCase().contains(s.stationName.toLowerCase()),
            );
            if (nameMatch.isNotEmpty) {
              targetStationId = nameMatch.first.stationId;
            }
          }
        } else if (emp.assignedStationName != null && emp.assignedStationName!.isNotEmpty) {
          final matchedStn = tracker.stations.firstWhere(
            (s) => s.stationName.toLowerCase().contains(emp.assignedStationName!.toLowerCase()) ||
                   emp.assignedStationName!.toLowerCase().contains(s.stationName.toLowerCase()),
            orElse: () => tracker.stations.first,
          );
          targetStationId = matchedStn.stationId;
        } else if (tracker.stations.isNotEmpty) {
          targetStationId = tracker.stations.first.stationId;
        }

        if (_rememberMe) {
          await tracker.saveLoginSession(
            role: 'employee',
            userId: emp.employeeId,
            userName: emp.fullName,
            stationId: targetStationId,
            rememberId: true,
          );
        } else {
          tracker.currentRole = 'employee';
          tracker.activeEmployeeName = emp.fullName;
          tracker.activeEmployeeId = emp.employeeId;
        }

        tracker.assignEmployeeToStation(
          empId: emp.employeeId,
          empName: emp.fullName,
          stationId: targetStationId,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDutyScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Employee credentials. Please check your ID and Password.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'admin';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: LanguageToggleButton(),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.blueGrey.shade800 : AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (isAdmin ? Colors.blueGrey : AppColors.primary).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.badge_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tr('app_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.blueGrey.shade900 : AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin ? 'Administrator & Supervisor Portal' : tr('login_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (isAdmin ? Colors.blueGrey : AppColors.primary).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings : Icons.badge_outlined,
                                color: isAdmin ? Colors.blueGrey.shade900 : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isAdmin ? 'Admin Authentication' : 'Employee Operator Login',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAdmin
                              ? 'Enter Administrator Username / Email and Master Password'
                              : 'Enter your assigned Employee ID, Mobile, or Email',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: _loginIdCtrl,
                          decoration: InputDecoration(
                            labelText: isAdmin ? 'Admin ID / Email' : tr('employee_id'),
                            hintText: isAdmin ? 'e.g. admin@kvm.com' : tr('employee_id_hint'),
                            prefixIcon: Icon(isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: isAdmin ? 'Admin Master Password' : tr('password'),
                            hintText: tr('password_hint'),
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),

                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: isAdmin ? Colors.blueGrey.shade900 : AppColors.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: const Text(
                                'Remember Me',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Spacer(),
                            if (!isAdmin)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdmin ? Colors.blueGrey.shade900 : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleLogin,
                          child: Text(isAdmin ? 'Authenticate as Admin' : tr('sign_in')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dedicated Role Switch-Over at the bottom
                Container(
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAdmin ? Colors.blue.shade200 : Colors.grey.shade300,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRole = isAdmin ? 'employee' : 'admin';
                        _loginIdCtrl.clear();
                        _passwordCtrl.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            isAdmin ? Icons.badge_outlined : Icons.admin_panel_settings,
                            color: isAdmin ? AppColors.primary : Colors.blueGrey.shade900,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdmin ? 'Sign in as Field Employee' : 'Sign in as Admin / Supervisor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isAdmin ? AppColors.primary : Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAdmin
                                      ? 'Switch to station operator shift login'
                                      : 'Switch to fleet management & admin controls',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isAdmin ? AppColors.primary : Colors.blueGrey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    icon: const Icon(Icons.cloud_sync_outlined, size: 16),
                    label: Text(
                      'Cloud Server: ${ApiService.baseUrl}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: _showServerConfigDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  void _showServerConfigDialog() {
    final serverUrlCtrl = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cloud Server Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your live Hostinger API subdomain or backend URL so this phone syncs with your Hostinger database:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: serverUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend API URL',
                hintText: 'e.g. https://api.yourdomain.com/api',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Default Localhost: http://10.0.2.2:5000/api (Emulator) or http://localhost:5000/api (Web)',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = serverUrlCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  ApiService.setServerUrl(newUrl);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server endpoint updated to: $newUrl'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}
