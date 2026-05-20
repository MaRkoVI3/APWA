import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart' hide NetworkType;
import 'package:geolocator/geolocator.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _usagePermissionGranted = false;
  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isRequestingPermissions = false;

  String _userName = '';
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _leaveTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  double _dailyGoalHours = 2.0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestAllPermissions() async {
    if (_isRequestingPermissions) return;
    setState(() => _isRequestingPermissions = true);

    // Usage Stats
    final usageGranted = await UsageStats.checkUsagePermission() ?? false;
    if (!usageGranted) {
      await _showExplanationDialog(
        title: 'Usage Access Required',
        message:
            'On the next screen, find "Apwais" and toggle it ON.\n\n'
            'This lets Apwais see how long you\'ve used each app.',
        onContinue: () => UsageStats.grantUsagePermission(),
      );
    }
    final usageNowGranted =
        await UsageStats.checkUsagePermission() ?? false;
    setState(() => _usagePermissionGranted = usageNowGranted);

    // Location
    var locationStatus = await Permission.locationWhenInUse.request();
    if (locationStatus.isGranted) {
      await Permission.locationAlways.request();
    }
    final locationGranted = await Permission.locationAlways.isGranted;
    setState(() => _locationPermissionGranted = locationGranted);

    // Notifications
    final notifStatus = await Permission.notification.request();
    setState(() => _notificationPermissionGranted = notifStatus.isGranted);

    // Battery optimization
    await Permission.ignoreBatteryOptimizations.request();

    setState(() => _isRequestingPermissions = false);
  }

  Future<void> _showExplanationDialog({
    required String title,
    required String message,
    required VoidCallback onContinue,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onContinue();
            },
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.keyUserName, _userName.trim());
    await prefs.setString(
      AppConstants.keyWakeTime,
      '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}',
    );
    await prefs.setString(
      AppConstants.keyLeaveTime,
      '${_leaveTime.hour.toString().padLeft(2, '0')}:${_leaveTime.minute.toString().padLeft(2, '0')}',
    );
    await prefs.setStringList(
        AppConstants.keySchoolDays, _selectedDays.toList());
    await prefs.setInt(
      AppConstants.keyDailyGoalMinutes,
      (_dailyGoalHours * 60).round(),
    );
    await prefs.setInt(
        AppConstants.keyQuietStart, AppConstants.defaultQuietHourStart);
    await prefs.setInt(
        AppConstants.keyQuietEnd, AppConstants.defaultQuietHourEnd);

    // Save home location
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await prefs.setDouble(AppConstants.keyHomeLat, position.latitude);
      await prefs.setDouble(AppConstants.keyHomeLng, position.longitude);
    } catch (e) {
      debugPrint('[Onboarding] Could not get location: $e');
    }

    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildPermissionsPage(),
                  _buildSchedulePage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PAGE 1: WELCOME ──
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  size: 64, color: AppTheme.primary),
            ),
          ),
          const Spacer(),
          Text('Apwais',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primary,
                    fontSize: 36,
                  )),
          const SizedBox(height: 12),
          Text('Your digital wellbeing companion.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            'Apwais tracks how you spend time on your phone and reminds you to take breaks — especially at school or work.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 12),
          _bullet(Icons.bar_chart_rounded,
              'Tracks time on TikTok, Instagram, and more'),
          _bullet(Icons.location_on_rounded,
              'Knows when you\'re at school or work'),
          _bullet(Icons.notifications_active_rounded,
              'Sends smart reminders before you go overboard'),
          const Spacer(flex: 2),
          ElevatedButton(
              onPressed: _nextPage, child: const Text('Get Started')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  // ── PAGE 2: PERMISSIONS ──
  Widget _buildPermissionsPage() {
    final allGranted =
        _usagePermissionGranted && _locationPermissionGranted;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Permissions Needed',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Apwais needs a few permissions to work. Your data never leaves your phone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _permissionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Usage Access',
            description: 'See how long you\'ve spent on each app',
            isGranted: _usagePermissionGranted,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _permissionCard(
            icon: Icons.location_on_rounded,
            title: 'Location (Always)',
            description: 'Detect when you\'re at school or work',
            isGranted: _locationPermissionGranted,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _permissionCard(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            description: 'Send reminders and daily summaries',
            isGranted: _notificationPermissionGranted,
            isRequired: false,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed:
                _isRequestingPermissions ? null : _requestAllPermissions,
            child: _isRequestingPermissions
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Grant Permissions'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: allGranted ? _nextPage : null,
            child: Text(allGranted
                ? 'Continue →'
                : 'Grant required permissions first'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _permissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? AppTheme.secondary.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppTheme.secondary : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color:
                  isGranted ? AppTheme.secondary : AppTheme.textSecondary,
              size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Required',
                            style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isGranted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color:
                isGranted ? AppTheme.secondary : AppTheme.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── PAGE 3: SCHEDULE ──
  Widget _buildSchedulePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Your Schedule',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Tell us your routine so Apwais can give smarter reminders.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          // Name
          Text('Your name',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'e.g. Alex',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => setState(() => _userName = val),
          ),
          const SizedBox(height: 24),

          // Wake time
          Text('I usually wake up at',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _timePicker(
            icon: Icons.wb_sunny_outlined,
            label: _formatTime(_wakeTime),
            onTap: () async {
              final p = await showTimePicker(
                  context: context, initialTime: _wakeTime);
              if (p != null) setState(() => _wakeTime = p);
            },
          ),
          const SizedBox(height: 20),

          // Leave time
          Text('I leave home for school/work at',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _timePicker(
            icon: Icons.directions_walk_rounded,
            label: _formatTime(_leaveTime),
            onTap: () async {
              final p = await showTimePicker(
                  context: context, initialTime: _leaveTime);
              if (p != null) setState(() => _leaveTime = p);
            },
          ),
          const SizedBox(height: 24),

          // School days
          Text('I go to school/work on',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.daysOfWeek.map((day) {
              final isSelected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() => isSelected
                    ? _selectedDays.remove(day)
                    : _selectedDays.add(day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Daily goal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily screen time goal',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${_dailyGoalHours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('We\'ll warn you when you\'re close to this limit',
              style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: _dailyGoalHours,
            min: 0.5,
            max: 6.0,
            divisions: 11,
            activeColor: AppTheme.primary,
            label: '${_dailyGoalHours.toStringAsFixed(1)} hrs',
            onChanged: (val) => setState(() => _dailyGoalHours = val),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _finishOnboarding,
            child: const Text('Start Using Apwais 🎉'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _timePicker({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            const Icon(Icons.edit_rounded,
                size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}