import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Login Screen
      'welcome_back': 'Welcome Back',
      'sign_in_to_account': 'Sign in to your account',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'forgot_password_not_implemented': 'Forgot Password functionality not implemented yet.',
      'login': 'Login',
      'please_enter_email': 'Please enter your email',
      'please_enter_password': 'Please enter your password',
      
      // Home Screen
      'home': 'Home',
      'logout': 'Logout',
      'logout_confirmation': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'welcome_home': 'Welcome Home!',
      
      // Main Screen / Bottom Navigation
      'attendance': 'Attendance',
      'for_you': 'For You',
      'my_account': 'My Account',
      'for_you_screen': 'For You Screen',
      
      // Profile Screen
      'my_profile': 'My Profile',
      'no_user_data': 'No user data',
      'nik': 'NIK',
      'department': 'Department',
      'joined': 'Joined',
      'attendance_history': 'Attendance History',
      'change_password': 'Change Password',
      
      // Change Password Screen
      'old_password': 'Old Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'required': 'Required',
      'new_passwords_do_not_match': 'New passwords do not match',
      'password_changed_successfully': 'Password changed successfully',
      
      // Operations
      'operations': 'Operations',
      'equipment_operations': 'Equipment Operations',
      'filter_equipment': 'Filter Equipment',
      'date': 'Date',
      'failed_to_load_operations': 'Failed to load operations',
      'retry': 'Retry',
      'no_operations_found': 'No operations found',
      'start_new_operation': 'Start New Operation',
      'unknown_equipment': 'Unknown Equipment',
      'unknown': 'Unknown',
      'total': 'Total',
      'approved': 'Approved',
      'finished_pending': 'Finished (Pending)',
      'in_progress': 'In Progress',
      
      // Operation Details
      'operation_details': 'Operation Details',
      'ongoing': 'Ongoing',
      'finished': 'Finished',
      'day': 'Day',
      'task_timeline': 'Task Timeline',
      'add_task': 'Add Task',
      'no_tasks_yet': 'No Tasks Yet',
      'finish_operation': 'Finish Operation',
      
      // Create Operation
      'equipment': 'Equipment',
      'hour_meter_start': 'Hour Meter Start',
      'start_photo': 'Start Photo',
      'start_operation': 'Start Operation',
      'day_shift': 'Day (6 AM - 6 PM)',
      'night_shift': 'Night (6 PM - 6 AM)',
      'please_select_equipment': 'Please select equipment',
      'please_enter_hm_start': 'Please enter HM start',
      'operator': 'Operator',
      'hm_start': 'HM Start',
      'hm_end': 'HM End',
      'total_hours': 'Total Hours',
      'photos': 'Photos',
      
      // Add Task
      'task_start': 'Task Start',
      'task_end': 'Task End',
      'activity': 'Activity',
      'location': 'Location',
      'instructed_by': 'Instructed By',
      'code': 'Code',
      'result': 'Result',
      'remarks': 'Remarks',
      'save': 'Save',
      'optional': 'Optional',
      
      // Attendance
      'history': 'History',
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'late_minutes': 'Late Minutes',
      'work_hours_real': 'Work Hours (Real)',
      'work_hours_calc': 'Work Hours (Calc)',
      'rest': 'Rest',
      'work_hour_final': 'Work Hour Final',
      'info': 'Info',
      'hours': 'hours',
      'mins': 'mins',
      'hour': 'hour',
      'error_loading_attendance': 'Error loading attendance',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'update': 'Update',
      'create': 'Create',
      'search': 'Search',
      'filter': 'Filter',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'submit': 'Submit',
      'back': 'Back',
    },
    'id': {
      // Login Screen
      'welcome_back': 'Selamat Datang Kembali',
      'sign_in_to_account': 'Masuk ke akun Anda',
      'email': 'Email',
      'password': 'Kata Sandi',
      'forgot_password': 'Lupa Kata Sandi?',
      'forgot_password_not_implemented': 'Fitur Lupa Kata Sandi belum tersedia.',
      'login': 'Masuk',
      'please_enter_email': 'Silakan masukkan email Anda',
      'please_enter_password': 'Silakan masukkan kata sandi Anda',
      
      // Home Screen
      'home': 'Beranda',
      'logout': 'Keluar',
      'logout_confirmation': 'Apakah Anda yakin ingin keluar?',
      'cancel': 'Batal',
      'welcome_home': 'Selamat Datang!',
      
      // Main Screen / Bottom Navigation
      'attendance': 'Kehadiran',
      'for_you': 'Untuk Anda',
      'my_account': 'Akun Saya',
      'for_you_screen': 'Halaman Untuk Anda',
      
      // Profile Screen
      'my_profile': 'Profil Saya',
      'no_user_data': 'Tidak ada data pengguna',
      'nik': 'NIK',
      'department': 'Departemen',
      'joined': 'Bergabung',
      'attendance_history': 'Riwayat Kehadiran',
      'change_password': 'Ubah Kata Sandi',
      
      // Change Password Screen
      'old_password': 'Kata Sandi Lama',
      'new_password': 'Kata Sandi Baru',
      'confirm_new_password': 'Konfirmasi Kata Sandi Baru',
      'required': 'Wajib diisi',
      'new_passwords_do_not_match': 'Kata sandi baru tidak cocok',
      'password_changed_successfully': 'Kata sandi berhasil diubah',
      
      // Operations
      'operations': 'Operasi',
      'equipment_operations': 'Shift Peralatan',
      'filter_equipment': 'Filter Peralatan',
      'date': 'Tanggal',
      'failed_to_load_operations': 'Gagal Memuat',
      'retry': 'Coba Lagi',
      'no_operations_found': 'Tidak Ada Aktifitas Peralatan',
      'start_new_operation': 'Mulai Shift Baru',
      'unknown_equipment': 'Peralatan Tidak Dikenal',
      'unknown': 'Tidak Dikenal',
      'total': 'Total',
      'approved': 'Disetujui',
      'finished_pending': 'Selesai (Menunggu)',
      'in_progress': 'Sedang Berlangsung',
      
      // Operation Details
      'operation_details': 'Detail Pekerjaan',
      'ongoing': 'Sedang Berlangsung',
      'finished': 'Selesai',
      'day': 'Siang',
      'task_timeline': 'Aktifitas',
      'add_task': 'Tambah',
      'no_tasks_yet': 'Belum ada aktivitas',
      'finish_operation': 'Shift Selesai',
      
      // Create Operation
      'equipment': 'Peralatan',
      'hour_meter_start': 'Meter Awal',
      'start_photo': 'Foto Meter Awal',
      'start_operation': 'Start Shift',
      'day_shift': 'Siang (06:00-18:00)',
      'night_shift': 'Malam (18:00-06:00)',
      'please_select_equipment': 'Mohon pilih peralatan',
      'please_enter_hm_start': 'Mohon input meter awal',
      'operator': 'Operator',
      'hm_start': 'HM Awal',
      'hm_end': 'HM Akhir',
      'total_hours': 'Total Jam',
      'photos': 'Foto',
      
      // Add Task
      'task_start': 'Mulai',
      'task_end': 'Berakhir',
      'activity': 'Aktivitas Alat',
      'location': 'Lokasi',
      'instructed_by': 'Perintah dari',
      'code': 'Kode',
      'result': 'Hasil Kerja',
      'remarks': 'Catatan Hasil Kerja',
      'save': 'Simpan',
      'optional': 'Opsional',
      
      // Attendance
      'history': 'Riwayat',
      'check_in': 'Masuk',
      'check_out': 'Keluar',
      'late_minutes': 'Menit Terlambat',
      'work_hours_real': 'Jam Kerja (Real)',
      'work_hours_calc': 'Jam Kerja (Kalkulasi)',
      'rest': 'Istirahat',
      'work_hour_final': 'Jam Kerja Akhir',
      'info': 'Info',
      'hours': 'jam',
      'mins': 'menit',
      'hour': 'jam',
      'error_loading_attendance': 'Gagal memuat kehadiran',
      
      // Common
      'loading': 'Memuat...',
      'error': 'Kesalahan',
      'success': 'Berhasil',
      'confirm': 'Konfirmasi',
      'delete': 'Hapus',
      'edit': 'Ubah',
      'save': 'Simpan',
      'update': 'Perbarui',
      'create': 'Buat',
      'search': 'Cari',
      'filter': 'Filter',
      'close': 'Tutup',
      'yes': 'Ya',
      'no': 'Tidak',
      'ok': 'OK',
      'submit': 'Kirim',
      'back': 'Kembali',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common strings
  String get welcomeBack => translate('welcome_back');
  String get signInToAccount => translate('sign_in_to_account');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get forgotPasswordNotImplemented => translate('forgot_password_not_implemented');
  String get login => translate('login');
  String get pleaseEnterEmail => translate('please_enter_email');
  String get pleaseEnterPassword => translate('please_enter_password');
  
  String get home => translate('home');
  String get logout => translate('logout');
  String get logoutConfirmation => translate('logout_confirmation');
  String get cancel => translate('cancel');
  String get welcomeHome => translate('welcome_home');
  
  String get attendance => translate('attendance');
  String get forYou => translate('for_you');
  String get myAccount => translate('my_account');
  String get forYouScreen => translate('for_you_screen');
  
  String get myProfile => translate('my_profile');
  String get noUserData => translate('no_user_data');
  String get nik => translate('nik');
  String get department => translate('department');
  String get joined => translate('joined');
  String get attendanceHistory => translate('attendance_history');
  String get changePassword => translate('change_password');
  
  String get oldPassword => translate('old_password');
  String get newPassword => translate('new_password');
  String get confirmNewPassword => translate('confirm_new_password');
  String get required => translate('required');
  String get newPasswordsDoNotMatch => translate('new_passwords_do_not_match');
  String get passwordChangedSuccessfully => translate('password_changed_successfully');
  
  String get operations => translate('operations');
  String get equipmentOperations => translate('equipment_operations');
  String get filterEquipment => translate('filter_equipment');
  String get date => translate('date');
  String get failedToLoadOperations => translate('failed_to_load_operations');
  String get retry => translate('retry');
  String get noOperationsFound => translate('no_operations_found');
  String get startNewOperation => translate('start_new_operation');
  String get unknownEquipment => translate('unknown_equipment');
  String get unknown => translate('unknown');
  String get total => translate('total');
  String get approved => translate('approved');
  String get finishedPending => translate('finished_pending');
  String get inProgress => translate('in_progress');
  
  // Operation Details getters
  String get operationDetails => translate('operation_details');
  String get ongoing => translate('ongoing');
  String get finished => translate('finished');
  String get day => translate('day');
  String get taskTimeline => translate('task_timeline');
  String get addTask => translate('add_task');
  String get noTasksYet => translate('no_tasks_yet');
  String get finishOperation => translate('finish_operation');
  
  // Create Operation getters
  String get equipment => translate('equipment');
  String get hourMeterStart => translate('hour_meter_start');
  String get startPhoto => translate('start_photo');
  String get startOperation => translate('start_operation');
  String get dayShift => translate('day_shift');
  String get nightShift => translate('night_shift');
  String get pleaseSelectEquipment => translate('please_select_equipment');
  String get pleaseEnterHmStart => translate('please_enter_hm_start');
  String get operator => translate('operator');
  String get hmStart => translate('hm_start');
  String get hmEnd => translate('hm_end');
  String get totalHours => translate('total_hours');
  String get photos => translate('photos');
  
  // Add Task getters
  String get taskStart => translate('task_start');
  String get taskEnd => translate('task_end');
  String get activity => translate('activity');
  String get location => translate('location');
  String get instructedBy => translate('instructed_by');
  String get code => translate('code');
  String get result => translate('result');
  String get remarks => translate('remarks');
  String get save => translate('save');
  String get optional => translate('optional');
  
  // Attendance getters
  String get history => translate('history');
  String get checkIn => translate('check_in');
  String get checkOut => translate('check_out');
  String get lateMinutes => translate('late_minutes');
  String get workHoursReal => translate('work_hours_real');
  String get workHoursCalc => translate('work_hours_calc');
  String get rest => translate('rest');
  String get workHourFinal => translate('work_hour_final');
  String get info => translate('info');
  String get hours => translate('hours');
  String get mins => translate('mins');
  String get hour => translate('hour');
  String get errorLoadingAttendance => translate('error_loading_attendance');
  
  // Common getters
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get update => translate('update');
  String get create => translate('create');
  String get search => translate('search');
  String get filter => translate('filter');
  String get close => translate('close');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get submit => translate('submit');
  String get back => translate('back');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
