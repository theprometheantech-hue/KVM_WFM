/// Central Bilingual Translation Dictionary for KVM Workforce Tracker
/// Supports English ('en') and Tamil ('ta')
class AppStrings {
  static const Map<String, Map<String, String>> _translations = {
    // App & Navigation
    'app_title': {
      'en': 'KVM Workforce Tracker',
      'ta': 'கேவிஎம் பணிப்பாய்வு டிராக்கர்',
    },
    'admin_monitor_title': {
      'en': 'Admin / Supervisor Fleet Monitor',
      'ta': 'நிர்வாகி / மேற்பார்வையாளர் கண்காணிப்பு',
    },
    'employee_duty_title': {
      'en': 'KVM Machine Station Operator',
      'ta': 'கேவிஎம் மெஷின் நிலைய பணியாளர்',
    },
    'staff_management_title': {
      'en': 'Staff Management & Provisioning',
      'ta': 'பணியாளர்கள் மேலாண்மை மற்றும் நியமனம்',
    },
    'cash_audit_title': {
      'en': 'Manual Cash vs Machine Float Audit',
      'ta': 'ரொக்கப் பணம் & மெஷின் இருப்பு தணிக்கை',
    },
    'gate_pass_title': {
      'en': 'Vendor Truck Gate Passes',
      'ta': 'லாரி சரக்கு அனுமதி பாஸ்கள் (Gate Pass)',
    },

    // Login Screen
    'welcome_back': {
      'en': 'Welcome Back',
      'ta': 'மீண்டும் வருக',
    },
    'login_subtitle': {
      'en': 'KVM Smart Reverse Vending Fleet Management',
      'ta': 'கேவிஎம் ஸ்மார்ட் பாட்டில் மெஷின் மேலாண்மை',
    },
    'employee_id': {
      'en': 'Employee ID / Login ID',
      'ta': 'பணியாளர் ஐடி / உள்நுழைவு எண்',
    },
    'employee_id_hint': {
      'en': 'e.g. EMP-101 or ADMIN-01',
      'ta': 'உதா. EMP-101 அல்லது ADMIN-01',
    },
    'password': {
      'en': 'Password',
      'ta': 'கடவுச்சொல் (Password)',
    },
    'password_hint': {
      'en': 'Enter your password',
      'ta': 'கடவுச்சொல்லை உள்ளிடவும்',
    },
    'sign_in': {
      'en': 'Sign In',
      'ta': 'உள்நுழைக (Sign In)',
    },
    'quick_admin_login': {
      'en': 'Quick Login as Admin / Supervisor',
      'ta': 'நிர்வாகியாக விரைவு உள்நுழைவு',
    },
    'quick_emp_login': {
      'en': 'Quick Login as Staff Operator',
      'ta': 'பணியாளராக விரைவு உள்நுழைவு',
    },
    'invalid_credentials': {
      'en': 'Invalid Employee ID or Password.',
      'ta': 'தவறான பணியாளர் ஐடி அல்லது கடவுச்சொல்.',
    },
    'empty_credentials': {
      'en': 'Please enter both Employee ID and Password.',
      'ta': 'பணியாளர் ஐடி மற்றும் கடவுச்சொல்லை உள்ளிடவும்.',
    },
    'logout': {
      'en': 'Logout',
      'ta': 'வெளியேறு (Logout)',
    },

    // Attendance & Shift
    'shift_check_in': {
      'en': 'Shift Check-in',
      'ta': 'பணி தொடக்கம் (Check-in)',
    },
    'shift_check_out': {
      'en': 'Shift Check-out',
      'ta': 'பணி நிறைவு (Check-out)',
    },
    'on_duty': {
      'en': 'ON DUTY',
      'ta': 'பணியில் உள்ளார்',
    },
    'checked_out': {
      'en': 'CHECKED OUT',
      'ta': 'பணி நிறைவுற்றது',
    },
    'unattended': {
      'en': 'UNATTENDED',
      'ta': 'பணியாளர் இல்லை',
    },
    'staff_present': {
      'en': 'STAFF PRESENT',
      'ta': 'பணியாளர் உள்ளார்',
    },
    'shift_started_at': {
      'en': 'Shift Started: ',
      'ta': 'பணி தொடங்கிய நேரம்: ',
    },
    'not_checked_in': {
      'en': 'Shift not started yet today',
      'ta': 'இன்று பணி இன்னும் தொடங்கப்படவில்லை',
    },
    'gps_verified': {
      'en': 'GPS Location Verified',
      'ta': 'ஜிபிஎஸ் இருப்பிடம் உறுதிசெய்யப்பட்டது',
    },
    'view_on_maps': {
      'en': 'View on Google Maps',
      'ta': 'கூகிள் மேப்ஸில் பார்க்க',
    },

    // Metrics & Counts
    'customer_deposits': {
      'en': 'Customer Deposits',
      'ta': 'பெறப்பட்ட பாட்டில்கள்',
    },
    'bottles_received': {
      'en': 'Bottles Received',
      'ta': 'பெறப்பட்ட பாட்டில்கள்',
    },
    'bottles_packed': {
      'en': 'Bottles Packed',
      'ta': 'பேக் செய்த பாட்டில்கள்',
    },
    'crates_ready': {
      'en': 'Crates Ready',
      'ta': 'தயாரான கிரேட்டுகள்',
    },
    'cash_handed_out': {
      'en': 'Cash Handed to Customers',
      'ta': 'வாடிக்கையாளருக்கு வழங்கிய பணம்',
    },
    'bin_capacity': {
      'en': 'Bin Capacity / Fill',
      'ta': 'தொட்டி கொள்ளளவு நிலை',
    },
    'locations': {
      'en': 'Locations',
      'ta': 'நிலையங்கள்',
    },
    'staff_on_duty': {
      'en': 'Staff On Duty',
      'ta': 'பணியில் உள்ள ஊழியர்கள்',
    },
    'total_received': {
      'en': 'Total Received',
      'ta': 'மொத்தம் பெறப்பட்டவை',
    },
    'total_packed': {
      'en': 'Total Packed',
      'ta': 'மொத்தம் பேக் செய்தவை',
    },

    // Actions & Buttons
    'add_employee': {
      'en': '+ Add Employee',
      'ta': '+ பணியாளர் சேர்க்க',
    },
    'add_location': {
      'en': '+ Add Location',
      'ta': '+ புதிய நிலையம் சேர்க்க',
    },
    'edit_rename': {
      'en': 'Edit',
      'ta': 'திருத்து',
    },
    'delete_station': {
      'en': 'Delete Station',
      'ta': 'நிலையத்தை நீக்கு',
    },
    'save_rename_station': {
      'en': 'Save Changes',
      'ta': 'சேமிக்கவும்',
    },
    'reassign_staff': {
      'en': 'Reassign Staff',
      'ta': 'பணியாளரை மாற்றவும்',
    },
    'assign_staff': {
      'en': '+ Assign Staff',
      'ta': '+ பணியாளர் நியமி',
    },
    'search_hint': {
      'en': 'Search any location, machine code or employee name...',
      'ta': 'நிலையம், மெஷின் எண் அல்லது பணியாளர் பெயரைத் தேடவும்...',
    },
    'all_stations': {
      'en': 'All Stations',
      'ta': 'அனைத்து நிலையங்கள்',
    },
    'present': {
      'en': 'Staff Present',
      'ta': 'பணியில் உள்ளவர்கள்',
    },
    'absent': {
      'en': 'Absent / Unattended',
      'ta': 'பணியாளர் இல்லாதவை',
    },
    'view_all_staff': {
      'en': 'View All Staff',
      'ta': 'அனைத்து ஊழியர்களையும் பார்க்க',
    },
    'cancel': {
      'en': 'Cancel',
      'ta': 'ரத்து செய்',
    },
    'save': {
      'en': 'Save',
      'ta': 'சேமிக்க',
    },
    'done': {
      'en': 'Done',
      'ta': 'முடிந்தது',
    },
    'close': {
      'en': 'Close',
      'ta': 'மூடு',
    },
    'confirm': {
      'en': 'Confirm',
      'ta': 'உறுதி செய்',
    },
    'yes_delete': {
      'en': 'Yes, Delete',
      'ta': 'ஆம், நீக்கவும்',
    },
    'yes_remove': {
      'en': 'Yes, Remove',
      'ta': 'ஆம், நீக்குக',
    },

    // Modals & Labels
    'station_name_label': {
      'en': 'Location / Station Name *',
      'ta': 'நிலையம் / இருப்பிடம் பெயர் *',
    },
    'machine_code_label': {
      'en': 'Machine Hardware Code *',
      'ta': 'மெஷின் குறியீட்டு எண் *',
    },
    'address_label': {
      'en': 'Landmark / Area Physical Address',
      'ta': 'முகவரி / அடையாள இடம் (Landmark)',
    },
    'assigned_operator_label': {
      'en': 'Assigned Operator',
      'ta': 'நியமிக்கப்பட்ட பணியாளர்',
    },
    'unassigned_vacant': {
      'en': 'Unassigned (Vacant)',
      'ta': 'பணியாளர் இல்லை (காலியிடம்)',
    },
    'fleet_management_actions': {
      'en': 'Fleet Management Actions',
      'ta': 'நிலையங்கள் மேலாண்மை நடவடிக்கைகள்',
    },
    'audit_float': {
      'en': 'Audit Float',
      'ta': 'ரொக்கம் தணிக்கை',
    },
    'sync_cloud': {
      'en': 'Sync with Hostinger Cloud',
      'ta': 'ஹோஸ்டிங்கர் கிளவுட் உடன் ஒத்திசை',
    },
    'cloud_sync_complete': {
      'en': 'Cloud Sync Complete!',
      'ta': 'கிளவுட் ஒத்திசைவு முடிந்தது!',
    },
    'employee_created_title': {
      'en': 'Employee Created & Assigned!',
      'ta': 'பணியாளர் உருவாக்கப்பட்டு நியமிக்கப்பட்டார்!',
    },
    'delete_station_confirm': {
      'en': 'Are you sure you want to delete this station from your fleet?',
      'ta': 'இந்த நிலையத்தை உங்கள் பட்டியலில் இருந்து நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
    },
    'remove_employee_confirm': {
      'en': 'Are you sure you want to remove this employee?',
      'ta': 'இந்த பணியாளரை நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
    },
    'record_cash_exchange': {
      'en': 'Record Cash Given to Customer',
      'ta': 'வாடிக்கையாளருக்கு பணம் வழங்கியதை பதிவு செய்',
    },
    'dispatch_truck': {
      'en': 'Dispatch Truck / Gate Pass',
      'ta': 'லாரி அனுப்புதல் / கேட் பாஸ் பதிவு',
    },
    'log_hourly_deposit': {
      'en': 'Log Hourly Machine Reading',
      'ta': 'மணிநேர மெஷின் அளவீடு பதிவு செய்',
    },
    'view_manage': {
      'en': '(Manage)',
      'ta': '(மேலாண்மை)',
    },
  };

  static String get(String key, {required bool isTamil}) {
    final langKey = isTamil ? 'ta' : 'en';
    if (_translations.containsKey(key)) {
      return _translations[key]![langKey] ?? _translations[key]!['en'] ?? key;
    }
    return key;
  }
}
