import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/language_service.dart';
import '../../data/services/tracker_service.dart';
import '../../data/models/onboarding_model.dart';
import '../../data/models/cash_exchange_model.dart';
import 'supervisor_monitor_screen.dart';
import 'login_screen.dart';
import 'truck_gate_pass_dialog.dart';

class EmployeeDutyScreen extends StatefulWidget {
  const EmployeeDutyScreen({super.key});

  @override
  State<EmployeeDutyScreen> createState() => _EmployeeDutyScreenState();
}

class _EmployeeDutyScreenState extends State<EmployeeDutyScreen> {
  final tracker = TrackerService();
  final _receivedCtrl = TextEditingController();
  final _packedBottlesCtrl = TextEditingController();
  final _packedCratesCtrl = TextEditingController(text: '4');
  final _driverCtrl = TextEditingController();
  String _selectedVendor = 'EcoRecycle Solutions Ltd.';

  // Truck Loading Controllers
  final _truckPackagesCtrl = TextEditingController(text: '10');
  final _truckBottlesCtrl = TextEditingController(text: '240');
  final _truckPlateCtrl = TextEditingController();
  final _truckDriverNameCtrl = TextEditingController();
  final _truckDriverMobileCtrl = TextEditingController();
  String _selectedTruckVendor = 'EcoRecycle Solutions Ltd.';

  final List<String> _vendorOptions = [
    'EcoRecycle Solutions Ltd.',
    'Distributor Bottle Reclamation Hub',
    'Pacific Glass & Metal Logistics',
    'Direct Brewery Return Depot',
  ];

  bool _isLocating = false;

  Future<void> _handleCheckIn() async {
    setState(() => _isLocating = true);
    double? lat;
    double? lng;
    String? locationNote;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationNote = 'GPS Hardware Disabled';
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
          lat = position.latitude;
          lng = position.longitude;
          locationNote = 'GPS Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}';
        } else {
          locationNote = 'GPS Permission Denied';
        }
      }
    } catch (e) {
      locationNote = 'Location Fetch Error';
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }

    await tracker.checkInEmployeeWithLocation(
      isPresent: true,
      latitude: lat,
      longitude: lng,
      address: locationNote,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lat != null
              ? 'Shift Check-In verified with GPS ($lat, $lng)! Updated to Admin.'
              : 'Shift Check-In recorded! Updated to Admin.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    await tracker.checkInEmployeeWithLocation(
      isPresent: false,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift completed. Successfully checked out.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    tracker.addListener(_onTrackerUpdate);
    LanguageService().addListener(_onTrackerUpdate);
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    tracker.removeListener(_onTrackerUpdate);
    LanguageService().removeListener(_onTrackerUpdate);
    _receivedCtrl.dispose();
    _packedBottlesCtrl.dispose();
    _packedCratesCtrl.dispose();
    _driverCtrl.dispose();
    _truckPackagesCtrl.dispose();
    _truckBottlesCtrl.dispose();
    _truckPlateCtrl.dispose();
    _truckDriverNameCtrl.dispose();
    _truckDriverMobileCtrl.dispose();
    super.dispose();
  }

  void _submitReceived() {
    final count = int.tryParse(_receivedCtrl.text) ?? 0;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bottle count received.')),
      );
      return;
    }
    tracker.addBottlesReceived(count);
    _receivedCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated: +$count customer bottles received! Admin can see this now.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _submitPacked() {
    final bottles = int.tryParse(_packedBottlesCtrl.text) ?? 0;
    final crates = int.tryParse(_packedCratesCtrl.text) ?? 1;
    if (bottles <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid collected bottle count.')),
      );
      return;
    }
    tracker.addBottlesPacked(
      bottles,
      crates,
      vendor: _selectedVendor,
      driver: _driverCtrl.text.isEmpty ? 'Scheduled Vendor Truck' : _driverCtrl.text,
    );
    _packedBottlesCtrl.clear();
    _packedCratesCtrl.text = '4';
    _driverCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated: Collected $bottles bottles packed in $crates crates for $_selectedVendor!'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _submitTruckLoading() {
    if (_truckPlateCtrl.text.isEmpty || _truckDriverNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Truck Plate Number and Driver Name.')),
      );
      return;
    }

    final packages = int.tryParse(_truckPackagesCtrl.text) ?? 1;
    final bottles = int.tryParse(_truckBottlesCtrl.text) ?? 24;
    final stn = tracker.activeStation;

    final record = TruckLoadingRecord(
      loadingId: 'TRK-LOAD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      stationId: stn.stationId,
      machineCode: stn.machineCode,
      employeeName: stn.employeeName,
      employeeId: stn.employeeId,
      vendorName: _selectedTruckVendor,
      packagesCount: packages,
      totalBottlesLoaded: bottles,
      truckVehicleNumber: _truckPlateCtrl.text.trim(),
      driverName: _truckDriverNameCtrl.text.trim(),
      driverMobile: _truckDriverMobileCtrl.text.trim(),
      timestamp: TimeOfDay.now().format(context),
    );

    tracker.recordTruckLoading(record);

    _truckPlateCtrl.clear();
    _truckDriverNameCtrl.clear();
    _truckDriverMobileCtrl.clear();

    // Show Printable / Shareable Digital Gate Pass
    showDialog(
      context: context,
      builder: (ctx) => TruckGatePassDialog(record: record),
    );
  }

  void _showCashPayoutModal() {
    final bottlesCtrl = TextEditingController(text: '5');
    final cashCtrl = TextEditingController(text: '50');
    final noteCtrl = TextEditingController();
    bool isDepositedInMachine = true;
    bool isReimbursed = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.currency_rupee, color: Colors.green)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Cash Payout & Machine Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Customer asked cash • You feed bottles to get digital payout', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bottlesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bottles from Customer *', prefixIcon: Icon(Icons.liquor)),
                      onChanged: (val) {
                        final b = int.tryParse(val) ?? 0;
                        setModalState(() {
                          cashCtrl.text = (b * 10).toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cashCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Manual Cash Handed Over (₹) *', prefixText: '₹ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isDepositedInMachine,
                activeColor: Colors.green.shade700,
                title: const Text('Bottles Fed into Reverse Vending Machine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Adds bottles to machine stock & inventory', style: TextStyle(fontSize: 11)),
                onChanged: (val) => setModalState(() => isDepositedInMachine = val ?? true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isReimbursed,
                activeColor: Colors.green.shade700,
                title: const Text('Digital Money Received from Machine (UPI/Wallet)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Replenishes your physical cash float', style: TextStyle(fontSize: 11)),
                onChanged: (val) => setModalState(() => isReimbursed = val ?? true),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Transaction Note (Optional)',
                  hintText: 'e.g. Customer demanded cash, UPI credited to my GPay',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Payout & Machine Deposit'),
                onPressed: () {
                  final b = int.tryParse(bottlesCtrl.text) ?? 1;
                  final a = double.tryParse(cashCtrl.text) ?? 10.0;
                  final stn = tracker.activeStation;

                  final record = ManualCashExchangeRecord(
                    id: 'EXC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    stationId: stn.stationId,
                    stationName: stn.stationName,
                    machineCode: stn.machineCode,
                    employeeName: stn.employeeName,
                    employeeId: stn.employeeId,
                    bottlesCollected: b,
                    cashPaidToCustomer: a,
                    isDepositedIntoMachine: isDepositedInMachine,
                    isDigitallyReimbursed: isReimbursed,
                    note: noteCtrl.text.trim(),
                    timestamp: TimeOfDay.now().format(context),
                    createdAt: DateTime.now(),
                  );

                  tracker.recordCashExchange(record);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recorded: Paid ₹${a.toStringAsFixed(0)} cash for $b bottle(s). Fed to ${stn.machineCode}. Supervisor notified.'),
                      backgroundColor: Colors.green.shade800,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stn = tracker.activeStation;
    final inCratesHolding = (stn.todayBottlesReceived - stn.todayBottlesPacked).clamp(0, 9999);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(tr('employee_duty_title')),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10, right: 8),
              child: LanguageToggleButton(isCompact: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: tr('logout'),
            onPressed: () {
              tracker.clearLoginSession();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SimpleLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: PRESENCE & LOCATION ATTENDANCE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stn.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Builder(builder: (_) {
                                final displayName = tracker.activeEmployeeName.isNotEmpty
                                    ? tracker.activeEmployeeName
                                    : (stn.employeeName.isNotEmpty ? stn.employeeName : 'Operator');
                                final displayId = tracker.activeEmployeeId.isNotEmpty
                                    ? tracker.activeEmployeeId
                                    : (stn.employeeId.isNotEmpty ? stn.employeeId : 'EMP');
                                return Text(
                                  'Machine: ${stn.machineCode} • Worker: $displayName (🪪 $displayId)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                );
                              }),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stn.isPresent ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            stn.isPresent ? tr('on_duty') : tr('checked_out'),
                            style: TextStyle(
                              color: stn.isPresent ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (stn.isPresent && stn.checkinLatitude != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${tr('gps_verified')}: ${stn.checkinLatitude!.toStringAsFixed(4)}, ${stn.checkinLongitude!.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: stn.isPresent ? Colors.grey.shade400 : AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isLocating
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.location_searching),
                            label: Text(_isLocating ? 'Verifying GPS...' : tr('shift_check_in')),
                            onPressed: (stn.isPresent || _isLocating) ? null : _handleCheckIn,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !stn.isPresent ? Colors.grey.shade400 : AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.logout),
                            label: Text(tr('shift_check_out')),
                            onPressed: !stn.isPresent ? null : _handleCheckOut,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SUMMARY CARDS STRIP
            Row(
              children: [
                Expanded(
                  child: _metricBox(tr('bottles_received'), '${stn.todayBottlesReceived} Bottles', AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox(tr('bottles_packed'), '${stn.todayBottlesPacked} Bottles', AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox(tr('crates_ready'), '$inCratesHolding Bottles', Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SECTION 2: UPDATE CUSTOMER BOTTLES RECEIVED
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1. Bottles Received',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Customer deposit counter',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Check the reverse vending machine counter and update count.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _receivedCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 50 bottles',
                              prefixIcon: Icon(Icons.liquor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                          onPressed: _submitReceived,
                          child: const Text('Save Count'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Action: Customer asks cash button (full width with wrapping)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        icon: const Icon(Icons.currency_rupee, size: 18),
                        label: Text(
                          tr('record_cash_exchange'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showCashPayoutModal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 3: COLLECTED & PACKED INTO CRATES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.warning, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2. Bin Clearance & Packing',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Empty machine & pack into crates',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('When compartment is full, empty it, pack into crates and record below.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _selectedVendor,
                      decoration: const InputDecoration(labelText: 'Target Recycling / Vendor Hub'),
                      items: _vendorOptions.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedVendor = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _packedBottlesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Bottles Collected (Units)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _packedCratesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Crates Packed'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Packed Crate Details'),
                      onPressed: _submitPacked,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 4: PACKAGES LOADED INTO TRUCK FOR VENDOR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.local_shipping, color: Colors.deepPurple, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '3. Truck Loading & Dispatch',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Vendor transport pickup',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('When pickup truck arrives, record loaded package count and truck details.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _selectedTruckVendor,
                      decoration: const InputDecoration(labelText: 'Select Vendor Transport'),
                      items: _vendorOptions.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedTruckVendor = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _truckPackagesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Packages / Crates Loaded'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _truckBottlesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total Bottles in Load'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _truckPlateCtrl,
                            decoration: const InputDecoration(labelText: 'Truck Registration No. *', prefixIcon: Icon(Icons.pin, size: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _truckDriverNameCtrl,
                            decoration: const InputDecoration(labelText: 'Driver Name *', prefixIcon: Icon(Icons.person, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _truckDriverMobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Driver Contact Mobile', prefixIcon: Icon(Icons.phone, size: 18)),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Truck Loading & Issue Gate Pass'),
                      onPressed: _submitTruckLoading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 5: TODAY'S LIVE DUTY LOG TIMELINE
            const Text('Today\'s Live Duty & Truck Loading Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracker.recentDutyLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final log = tracker.recentDutyLogs[idx];
                final isReceived = log.entryType == 'RECEIVED';
                final isTruck = log.entryType == 'TRUCK_LOADED';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTruck
                          ? Colors.deepPurple.withOpacity(0.12)
                          : (isReceived ? AppColors.primary : AppColors.warning).withOpacity(0.12),
                      child: Icon(
                        isTruck ? Icons.local_shipping : (isReceived ? Icons.arrow_downward : Icons.inventory_2),
                        color: isTruck ? Colors.deepPurple : (isReceived ? AppColors.primary : AppColors.warning),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isTruck
                          ? 'Truck Loaded: ${log.crateCount} Packages (${log.bottleCount} btls)'
                          : (isReceived ? 'Received: +${log.bottleCount} Bottles' : 'Packed: ${log.bottleCount} Bottles (${log.crateCount} crates)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      isTruck
                          ? '${log.vendorName} • Driver: ${log.vehicleOrDriver} (${log.timestamp})'
                          : (isReceived ? 'Machine counter update at ${log.timestamp}' : '${log.vendorName} (${log.timestamp})'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      isTruck ? 'DISPATCHED' : (isReceived ? '+${log.bottleCount}' : '-${log.bottleCount}'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isTruck ? Colors.deepPurple : (isReceived ? AppColors.primary : AppColors.warning),
                        fontSize: isTruck ? 11 : 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
