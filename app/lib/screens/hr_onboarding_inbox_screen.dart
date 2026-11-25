import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/onboarding_model.dart';
import '../../data/services/tracker_service.dart';
import '../../data/services/api_service.dart';

class HrOnboardingInboxScreen extends StatefulWidget {
  const HrOnboardingInboxScreen({super.key});

  @override
  State<HrOnboardingInboxScreen> createState() => _HrOnboardingInboxScreenState();
}

class _HrOnboardingInboxScreenState extends State<HrOnboardingInboxScreen> {
  final tracker = TrackerService();
  String _search = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncFromBackend();
  }

  Future<void> _syncFromBackend() async {
    setState(() => _isLoading = true);
    final apps = await ApiService.fetchOnboardingApplications();
    if (apps != null && mounted) {
      for (final app in apps) {
        final empId = app['employeeId'] ?? '';
        final exists = tracker.registeredEmployees.any((e) => e.employeeId == empId);
        if (!exists) {
          tracker.registerNewEmployee(
            RegisteredEmployee(
              employeeId: empId,
              fullName: app['fullName'] ?? 'Applicant',
              mobileNumber: app['mobileNumber'] ?? '',
              email: app['email'] ?? '',
              assignedStationName: app['residentialAddress'] ?? 'Pending',
              password: app['temporaryPassword'] ?? 'TempPass@2026',
              isTemporaryPassword: true,
              passwordSetDate: DateTime.now(),
              submittedDocuments: List<String>.from(app['documents'] ?? []),
              onboardingStatus: app['onboardingStatus'] ?? 'SUBMITTED',
              registeredAt: DateTime.tryParse(app['submittedAt'] ?? '') ?? DateTime.now(),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = tracker.registeredEmployees.where((emp) {
      final q = _search.toLowerCase();
      return emp.fullName.toLowerCase().contains(q) ||
          emp.employeeId.toLowerCase().contains(q) ||
          emp.mobileNumber.contains(q) ||
          emp.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Onboarding Inbox & Verification'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Applications',
            onPressed: _syncFromBackend,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Company HR Recipient: kamarajvs31@gmail.com\nAll registrations, uploaded documents & temporary passwords appear here directly.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search applicant name, Employee ID, mobile or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),

          // List of applicants
          Expanded(
            child: employees.isEmpty
                ? const Center(child: Text('No employee registrations found.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final emp = employees[idx];
                      final isPending = emp.onboardingStatus == 'SUBMITTED';

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isPending ? Colors.amber.shade100 : Colors.green.shade100,
                            child: Icon(
                              isPending ? Icons.pending_actions : Icons.verified_user,
                              color: isPending ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.amber.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  emp.onboardingStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPending ? Colors.amber.shade900 : Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('ID: ${emp.employeeId} | Mobile: ${emp.mobileNumber}\nEmail: ${emp.email}'),
                          childrenPadding: const EdgeInsets.all(16),
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Temporary Password: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                SelectableText(
                                  emp.password,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                                const SizedBox(width: 8),
                                const Text('(Share with applicant for first login)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Assigned Location: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(emp.assignedStationName ?? 'Pending Assignment'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Submitted Proof Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            if (emp.submittedDocuments.isEmpty)
                              const Text('No documents attached.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: emp.submittedDocuments.map((doc) {
                                  return Chip(
                                    avatar: const Icon(Icons.attach_file, size: 16),
                                    label: Text(doc, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.grey.shade100,
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPending)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve & Activate Employee'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await ApiService.verifyEmployee(emp.employeeId);
                                      setState(() {
                                        final updated = emp.copyWith(onboardingStatus: 'VERIFIED');
                                        final i = tracker.registeredEmployees.indexWhere((e) => e.employeeId == emp.employeeId);
                                        if (i != -1) tracker.registeredEmployees[i] = updated;
                                        tracker.notifyListeners();
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${emp.fullName} approved and activated!'),
                                            backgroundColor: Colors.green.shade700,
                                          ),
                                        );
                                      }
                                    },
                                  )
                                else
                                  const Text('Status: Active & Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
