import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/onboarding_model.dart';
import '../../data/services/tracker_service.dart';
import '../../data/services/api_service.dart';

class SignupOnboardingScreen extends StatefulWidget {
  const SignupOnboardingScreen({super.key});

  @override
  State<SignupOnboardingScreen> createState() => _SignupOnboardingScreenState();
}

class _SignupOnboardingScreenState extends State<SignupOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedStationLocation = 'Kannamangalam';

  final List<String> _attachedDocs = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickRealDocument(String categoryPrefix) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        final displayName = '${categoryPrefix}_${file.name}';
        setState(() {
          _attachedDocs.add(displayName);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attached: $displayName'), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitOnboarding() async {
    if (_nameCtrl.text.isEmpty || _mobileCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Full Name, Mobile Number and Email.')),
      );
      return;
    }

    if (_attachedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach at least one ID proof document for onboarding.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Call backend API to trigger email delivery to kamarajvs31@gmail.com and employee
    final backendResult = await ApiService.submitEmployeeOnboarding(
      fullName: _nameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      residentialAddress: _addressCtrl.text.trim(),
      documents: _attachedDocs,
    );

    // Generate unique EMP ID and temporary password (or use backend response)
    final empId = backendResult?['employeeId'] ?? 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final tempPass = backendResult?['temporaryPassword'] ?? 'TempPass@2026';

    final tracker = TrackerService();
    final newEmp = RegisteredEmployee(
      employeeId: empId,
      fullName: _nameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      assignedStationName: _selectedStationLocation,
      password: tempPass,
      isTemporaryPassword: true,
      passwordSetDate: DateTime.now(),
      submittedDocuments: List.from(_attachedDocs),
      onboardingStatus: 'SUBMITTED',
      registeredAt: DateTime.now(),
    );

    tracker.registerNewEmployee(newEmp);

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Onboarding Submitted!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${_nameCtrl.text.trim()}!', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('1. Your Employee ID: $empId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('2. Temporary Password: $tempPass', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 8),
              const Text('3. Your profile & uploaded documents have been sent to the In-App HR Inbox for company verification.'),
              const SizedBox(height: 12),
              const Text(
                'Note: Please copy your Employee ID and Temporary Password above. You will be asked to choose a permanent password on first login (valid for 3 months).',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Back to login
              },
              child: const Text('Proceed to Login'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Signup & Onboarding'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete this form to register. Your Employee ID & Temporary Password will be generated and emailed to you. Uploaded documents will be sent to the company HR email.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Legal Name *', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (To receive EMP ID & Pass) *',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home)),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedStationLocation,
                      decoration: const InputDecoration(labelText: 'Assigned Working Location / Station', prefixIcon: Icon(Icons.location_on)),
                      items: TrackerService().operationalLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStationLocation = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document Upload Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Onboarding Documents *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${_attachedDocs.length} Attached', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Attach Govt ID proof, address proof, or photo for company records.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Choose File (PDF/Image)'),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          onPressed: () => _pickRealDocument('Doc'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.badge, size: 16),
                          label: const Text('+ Aadhaar / National ID'),
                          onPressed: () => _pickRealDocument('Aadhaar'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.account_balance, size: 16),
                          label: const Text('+ Bank Proof / Cheque'),
                          onPressed: () => _pickRealDocument('BankProof'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.directions_car, size: 16),
                          label: const Text('+ Driving License'),
                          onPressed: () => _pickRealDocument('License'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_attachedDocs.isNotEmpty) ...[
                      const Divider(),
                      ..._attachedDocs.map(
                        (doc) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(doc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => setState(() => _attachedDocs.remove(doc)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOnboarding,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Application & Register to In-App HR Inbox'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

