class AppConstants {
  // Shared Preferences Keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserName = 'user_name';
  static const String keyWakeTime = 'wake_time';
  static const String keyLeaveTime = 'leave_time';
  static const String keySchoolDays = 'school_days';
  static const String keyDailyGoalMinutes = 'daily_goal_minutes';
  static const String keyHomeLat = 'home_lat';
  static const String keyHomeLng = 'home_lng';
  static const String keyWorkLat = 'work_lat';
  static const String keyWorkLng = 'work_lng';
  static const String keyLastLimitAlertMs = 'last_limit_alert_ms';
  static const String keyLastFocusAlertMs = 'last_focus_alert_ms';
  static const String keyQuietStart = 'quiet_start';
  static const String keyQuietEnd = 'quiet_end';

  // Social Media Package Names
  static const String pkgTikTok = 'com.zhiliaoapp.musically';
  static const String pkgInstagram = 'com.instagram.android';
  static const String pkgSnapchat = 'com.snapchat.android';
  static const String pkgYouTube = 'com.google.android.youtube';
  static const String pkgTwitter = 'com.twitter.android';
  static const String pkgFacebook = 'com.facebook.katana';
  static const String pkgWhatsApp = 'com.whatsapp';

  // Default App Time Limits (minutes per day)
  static const Map<String, int> defaultLimits = {
    pkgTikTok: 60,
    pkgInstagram: 60,
    pkgSnapchat: 45,
    pkgYouTube: 90,
    pkgTwitter: 45,
    pkgFacebook: 45,
    pkgWhatsApp: 60,
  };

  // Location
  static const double locationRadiusMeters = 300.0;

  // Notification Cooldowns
  static const int limitAlertCooldownMs = 30 * 60 * 1000;
  static const int focusAlertCooldownMs = 60 * 60 * 1000;

  // WorkManager Task Names
  static const String taskUsageCheck = 'usage_check';
  static const String taskUsageCheckUnique = 'usage_check_unique';

  // Default Settings
  static const int defaultDailyGoalMinutes = 120;
  static const int defaultQuietHourStart = 22;
  static const int defaultQuietHourEnd = 7;
  static const String defaultWakeTime = '07:00';
  static const String defaultLeaveTime = '08:00';
  static const List<String> defaultSchoolDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri'
  ];

  // Days of the week
  static const List<String> daysOfWeek = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
}