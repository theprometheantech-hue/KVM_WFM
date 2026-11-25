import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/localization/language_service.dart';
import 'data/services/tracker_service.dart';
import 'screens/login_screen.dart';
import 'screens/supervisor_monitor_screen.dart';
import 'screens/employee_duty_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleTrackerApp());
}

class SimpleTrackerApp extends StatelessWidget {
  const SimpleTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) {
        return MaterialApp(
          title: tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SessionGate(),
        );
      },
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<Map<String, dynamic>?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = TrackerService().getActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('app_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Restoring secure session...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          );
        }

        final session = snapshot.data;
        if (session != null) {
          final role = session['role'];
          if (role == 'supervisor') {
            return const SupervisorMonitorScreen();
          } else if (role == 'employee') {
            return const EmployeeDutyScreen();
          }
        }

        return const SimpleLoginScreen();
      },
    );
  }
}
