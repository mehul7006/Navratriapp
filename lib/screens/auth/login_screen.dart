import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/background_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  
  String _selectedUserType = 'user';
  bool _isLoading = false;
  bool _obscurePassword = true;
  Map<String, dynamic>? _dailyInfo;
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _loadDailyInfo();
    _startMarquee();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _marqueeTimer?.cancel();
    super.dispose();
  }

  void _startMarquee() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (current >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            current + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  Future<void> _loadDailyInfo() async {
    final info = await DatabaseHelper.getDailyInfo();
    if (mounted) setState(() => _dailyInfo = info);
  }

  String get _marqueeText {
    if (_dailyInfo == null) return 'Navratri 2026 - Nishitpark Society Mahotsav';
    final dayInfo = _dailyInfo!['day_info'];
    final dayNum = _dailyInfo!['day_number'] ?? 1;
    final goddess = dayInfo?['goddess_name'] ?? '';
    final dressCode = dayInfo?['dress_code'] ?? '';
    
    final parts = <String>[
      'Jai Mata Di! Day $dayNum: $goddess',
      if (dressCode.isNotEmpty) 'Dress: $dressCode',
    ];

    // Aarti bookings
    final aartiBookings = _dailyInfo!['aarti_bookings'] as List? ?? [];
    for (final a in aartiBookings) {
      final name = a['name']?.toString() ?? '';
      final house = a['house_number']?.toString() ?? '';
      final slot = a['slot_label']?.toString() ?? '';
      if (name.isNotEmpty) parts.add('Aarti: $name ($house) - $slot');
    }

    // Gift assignments
    final giftAssignments = _dailyInfo!['gift_assignments'] as List? ?? [];
    for (final g in giftAssignments) {
      final donor = g['donor_name']?.toString() ?? '';
      final gift = g['gift_name']?.toString() ?? '';
      if (donor.isNotEmpty) parts.add('Gift: $donor donated $gift');
    }

    // Yesterday's prize winners
    final yesterdayWinners = _dailyInfo!['yesterday_prize_winners'] as List? ?? [];
    if (yesterdayWinners.isNotEmpty) {
      parts.add('* Yesterday\'s Prize Winners:');
      for (final w in yesterdayWinners) {
        final prizeLevel = w['prize_level'];
        final name = w['user_name']?.toString() ?? '';
        final house = w['house_number']?.toString() ?? '';
        String ordinal(int n) {
          if (n >= 11 && n <= 13) return '${n}th';
          switch (n % 10) {
            case 1: return '${n}st';
            case 2: return '${n}nd';
            case 3: return '${n}rd';
            default: return '${n}th';
          }
        }
        final label = prizeLevel != null ? '${ordinal(prizeLevel as int)} Winner' : '';
        if (name.isNotEmpty) parts.add('$label: $name (House $house)');
      }
    }

    // Prize winners from daily info
    final prizeWinners = _dailyInfo!['prize_winners'] as List? ?? [];
    for (final w in prizeWinners) {
      final place = w['place']?.toString() ?? '';
      final name = w['name']?.toString() ?? '';
      final gift = w['gift_name']?.toString() ?? '';
      if (name.isNotEmpty) parts.add('🏆 $place Prize: $name - $gift');
    }

    // Snack orders
    final snackOrders = _dailyInfo!['snack_orders'] as List? ?? [];
    for (final s in snackOrders) {
      final buyer = s['buyer_name']?.toString() ?? '';
      final snack = s['snack_name']?.toString() ?? '';
      final qty = s['quantity'] ?? 1;
      if (buyer.isNotEmpty) parts.add('🍽 Snack: $buyer ordered $snack x$qty');
    }

    // Sponsors
    final sponsors = _dailyInfo!['sponsors'] as List? ?? [];
    for (final s in sponsors) {
      if (s['company_name']?.toString().isNotEmpty == true) {
        parts.add('🤝 Sponsored by: ${s['company_name']}');
      }
    }

    if (parts.length <= 1) parts.add('🪔 Welcome to Nishitpark Society Mahotsav!');
    return parts.join('  ★  ');
  }

  String get _loginHint {
    switch (_selectedUserType) {
      case 'user': return AppLocalizations.t('hint_enter_house_number');
      case 'organizer': return AppLocalizations.t('hint_enter_organizer_username');
      case 'sponsor': return AppLocalizations.t('hint_enter_house_number');
      default: return AppLocalizations.t('hint_enter_house_number');
    }
  }

  String get _passwordHint {
    switch (_selectedUserType) {
      case 'user': return AppLocalizations.t('hint_enter_mobile');
      case 'organizer': return AppLocalizations.t('hint_enter_password');
      case 'sponsor': return AppLocalizations.t('hint_enter_password');
      default: return AppLocalizations.t('hint_enter_password');
    }
  }

  String get _userIdLabel {
    switch (_selectedUserType) {
      case 'user': return AppLocalizations.t('house_number_user');
      case 'organizer': return AppLocalizations.t('username');
      case 'sponsor': return AppLocalizations.t('house_number_sponsor');
      default: return AppLocalizations.t('username');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      bool success = false;
      switch (_selectedUserType) {
        case 'user':
          success = await authProvider.loginUser(
            houseNumber: _userIdController.text.trim(),
            mobileNumber: _passwordController.text.trim(),
          );
          break;
        case 'organizer':
          success = await authProvider.loginOrganizer(
            username: _userIdController.text.trim(),
            password: _passwordController.text.trim(),
          );
          break;
        case 'sponsor':
          success = await authProvider.loginSponsor(
            houseNumber: _userIdController.text.trim(),
            password: _passwordController.text.trim(),
          );
          break;
      }
      if (success && mounted) {
        final userType = authProvider.currentUser?['user_type'];
        final userId = authProvider.currentUser?['id'];
        // Load user's saved language preference
        if (userId != null) {
          final localeProvider = context.read<LocaleProvider>();
          await localeProvider.loadUserLocale(userId);
        }
        switch (userType) {
          case 'organizer': Navigator.pushReplacementNamed(context, '/organizer/dashboard'); break;
          case 'sponsor': Navigator.pushReplacementNamed(context, '/sponsor/dashboard'); break;
          default: Navigator.pushReplacementNamed(context, '/user/home');
        }
      } else if (mounted) {
        _showError(authProvider.error ?? AppLocalizations.t('invalid_credentials'));
      }
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      backgroundImage: 'assets/images/LOGIN_BG.jpg',
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                  Text(AppLocalizations.t('navratri_2026'), style: TextStyle(fontFamily: 'Cinzel', fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.goldPrimary, letterSpacing: 2)),
                const SizedBox(height: 4),
                  Text(AppLocalizations.t('nishitpark_society'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildMarquee(),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      // Mobile: stack vertically
                      return Column(
                        children: [
                          _buildPrizeWinners(),
                          const SizedBox(height: 12),
                          _buildLoginForm(),
                          const SizedBox(height: 12),
                          _buildTodayBookings(),
                        ],
                      );
                    } else {
                      // Desktop: 3-column layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPrizeWinners()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildLoginForm()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTodayBookings()),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.goldPrimary, width: 3),
        boxShadow: [BoxShadow(color: AppTheme.goldPrimary.withValues(alpha: 0.6), blurRadius: 35, spreadRadius: 5)],
        gradient: const LinearGradient(colors: [AppTheme.purpleDeep, AppTheme.purpleCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: const Center(
            child: Icon(Icons.self_improvement, size: 40, color: AppTheme.purpleDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMarquee() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.purpleCard.withOpacity(0.6), AppTheme.purpleDeep.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.info_outline, color: AppTheme.goldPrimary.withOpacity(0.7), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Text(_marqueeText, style: TextStyle(color: AppTheme.goldPrimary.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildPrizeWinners() {
    if (_dailyInfo == null) return const SizedBox(height: 200);
    final yesterdayWinners = _dailyInfo!['yesterday_prize_winners'] as List? ?? [];
    if (yesterdayWinners.isEmpty) return const SizedBox(height: 200);
    final winnerDay = _dailyInfo!['yesterday_day'] ?? 0;

    String ordinal(int n) {
      if (n >= 11 && n <= 13) return '${n}th';
      switch (n % 10) {
        case 1: return '${n}st';
        case 2: return '${n}nd';
        case 3: return '${n}rd';
        default: return '${n}th';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.goldPrimary.withOpacity(0.1), AppTheme.purpleCard.withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text('Day $winnerDay Winners', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...yesterdayWinners.map((w) {
            final prizeLevel = w['prize_level'];
            final name = w['user_name']?.toString() ?? '';
            final house = w['house_number']?.toString() ?? '';
            final label = prizeLevel != null ? '${ordinal(prizeLevel as int)} Winner' : 'Winner';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: AppTheme.goldPrimary, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 18, color: Colors.white70), overflow: TextOverflow.ellipsis),
                  ),
                  Text('H$house', style: TextStyle(fontSize: 16, color: AppTheme.goldPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTodayBookings() {
    if (_dailyInfo == null) return const SizedBox(height: 200);
    final aartiBookings = _dailyInfo!['aarti_bookings'] as List? ?? [];
    final snackOrders = _dailyInfo!['snack_orders'] as List? ?? [];
    final giftAssignments = _dailyInfo!['gift_assignments'] as List? ?? [];
    if (aartiBookings.isEmpty && snackOrders.isEmpty && giftAssignments.isEmpty) return const SizedBox(height: 200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.purpleCard.withOpacity(0.6), AppTheme.purpleDeep.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (aartiBookings.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.wb_sunny, color: AppTheme.goldPrimary, size: 20),
              const SizedBox(width: 6),
              Text('Aarti:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
            ]),
            const SizedBox(height: 6),
            ...aartiBookings.take(5).map((a) {
              final name = a['name']?.toString() ?? '';
              final house = a['house_number']?.toString() ?? '';
              final status = a['status']?.toString() ?? '';
              final bookingId = a['booking_id']?.toString() ?? '';
              final statusIcon = status == 'approved' ? Icons.check_circle : Icons.pending;
              final statusColor = status == 'approved' ? Colors.green : Colors.orange;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text('$name (H$house)', style: const TextStyle(fontSize: 15, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                    Text('#$bookingId', style: TextStyle(fontSize: 12, color: AppTheme.goldPrimary.withOpacity(0.6))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          if (snackOrders.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.restaurant, color: AppTheme.goldPrimary, size: 20),
              const SizedBox(width: 6),
              Text('Snacks:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
            ]),
            const SizedBox(height: 6),
            ...snackOrders.take(3).map((s) {
              final buyer = s['buyer_name']?.toString() ?? '';
              final snack = s['snack_name']?.toString() ?? '';
              final qty = s['quantity'] ?? 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                child: Text('$buyer - $snack x$qty', style: const TextStyle(fontSize: 16, color: Colors.white70), overflow: TextOverflow.ellipsis),
              );
            }),
            const SizedBox(height: 10),
          ],
          if (giftAssignments.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.card_giftcard, color: AppTheme.goldPrimary, size: 20),
              const SizedBox(width: 6),
              Text('Gifts:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
            ]),
            const SizedBox(height: 6),
            ...giftAssignments.take(3).map((g) {
              final donor = g['donor_name']?.toString() ?? '';
              final gift = g['gift_name']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                child: Text('$donor - $gift', style: const TextStyle(fontSize: 16, color: Colors.white70), overflow: TextOverflow.ellipsis),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.55), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.t('login_as'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            _buildUserTypeSelector(),
            const SizedBox(height: 20),
            _buildTextField(controller: _userIdController, label: _userIdLabel, hint: _loginHint, icon: _selectedUserType == 'organizer' ? Icons.person : Icons.home, textCapitalization: TextCapitalization.characters, onChanged: (v) { final upper = v.toUpperCase(); if (v != upper) { _userIdController.value = _userIdController.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } }),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: _selectedUserType == 'user' ? AppLocalizations.t('mobile_number') : AppLocalizations.t('password'),
              hint: _passwordHint,
              icon: Icons.lock,
              keyboardType: _selectedUserType == 'user' ? TextInputType.phone : TextInputType.visiblePassword,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: AppTheme.textMuted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedUserType == 'user')
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.cyanAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(AppLocalizations.t('use_house_as_id'), style: TextStyle(fontSize: 11, color: AppTheme.cyanAccent))),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.purpleDark)))
                   : Text(AppLocalizations.t('login'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            if (_selectedUserType == 'user')
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(AppLocalizations.t('new_user_register'), style: TextStyle(color: AppTheme.goldPrimary, decoration: TextDecoration.underline)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3))),
      child: Row(
        children: [
          _buildUserTypeOption(AppLocalizations.t('user'), 'user', Icons.person),
          const SizedBox(width: 4),
          _buildUserTypeOption(AppLocalizations.t('organizer'), 'organizer', Icons.admin_panel_settings),
          const SizedBox(width: 4),
          _buildUserTypeOption(AppLocalizations.t('sponsor'), 'sponsor', Icons.business),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(String label, String value, IconData icon) {
    final isSelected = _selectedUserType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _selectedUserType = value; _userIdController.clear(); _passwordController.clear(); }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppTheme.goldPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, bool obscureText = false, Widget? suffixIcon, TextCapitalization textCapitalization = TextCapitalization.none, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2)),
      ),
      validator: (value) { if (value == null || value.isEmpty) return AppLocalizations.t('field_required'); return null; },
    );
  }
}
