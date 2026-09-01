import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class LuckyDrawScreen extends StatefulWidget {
  const LuckyDrawScreen({super.key});

  @override
  State<LuckyDrawScreen> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends State<LuckyDrawScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDay = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _potTickets = [];
  Map<String, dynamic>? _drawnTicket;
  bool _isPotShaking = false;
  bool _isRevealed = false;
  bool _isDrawing = false;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _initDay();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _initDay() async {
    _days = await DatabaseHelper.getNavratriDays();
    final activeDay = await DatabaseHelper.getCurrentActiveDay();
    if (activeDay != null) _selectedDay = activeDay;
    _loadTickets();
  }

  bool _isDayCompleted(int dayNumber) {
    final day = _days.firstWhere(
      (d) => d['day_number'] == dayNumber,
      orElse: () => {},
    );
    return day.isNotEmpty && day['is_completed'] == true;
  }

  bool _isDayBookable(int dayNumber) {
    final day = _days.firstWhere(
      (d) => d['day_number'] == dayNumber,
      orElse: () => {},
    );
    if (day.isEmpty) return false;
    if (day['is_completed'] == true) return false;
    if (day['is_active'] == true) return true;
    final activeDay = _days.firstWhere(
      (d) => d['is_active'] == true,
      orElse: () => {},
    );
    if (activeDay.isEmpty) return false;
    return dayNumber > (activeDay['day_number'] as int);
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _drawnTicket = null;
      _isRevealed = false;
    });
    try {
      final tickets = await DatabaseHelper.getDrawTicketsForDay(_selectedDay);
      if (mounted) {
        setState(() {
          _potTickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _drawTicket() async {
    if (_isDrawing || _potTickets.isEmpty || !_isDayBookable(_selectedDay)) return;

    setState(() => _isDrawing = true);

    // Shake the pot
    _shakeController.forward(from: 0);
    setState(() => _isPotShaking = true);

    await Future.delayed(const Duration(milliseconds: 800));

    // Pick a random ticket
    final random = Random();
    final index = random.nextInt(_potTickets.length);
    final ticket = _potTickets[index];

    setState(() {
      _drawnTicket = ticket;
      _potTickets.removeAt(index);
      _isPotShaking = false;
      _isRevealed = false;
      _isDrawing = false;
    });

    _shakeController.reverse();
  }

  void _revealTicket() {
    if (_drawnTicket == null || _isRevealed) return;
    setState(() => _isRevealed = true);
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('lucky_draw')),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildPotZone(),
                        const SizedBox(height: 20),
                        _buildDrawnTicket(),
                        const SizedBox(height: 20),
                        _buildDrawHistory(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final completed = _isDayCompleted(day);
          final bookable = _isDayBookable(day);
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: bookable
                  ? () {
                      setState(() => _selectedDay = day);
                      _loadTickets();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.goldPrimary
                      : (completed ? Colors.red.withOpacity(0.15) : AppTheme.purpleCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: completed
                        ? Colors.red.withOpacity(0.6)
                        : (isSelected ? AppTheme.goldPrimary : Colors.transparent),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day $day',
                      style: TextStyle(
                        color: completed
                            ? Colors.red.withOpacity(0.7)
                            : (isSelected ? AppTheme.purpleDark : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock, size: 12, color: Colors.red.withOpacity(0.7)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPotZone() {
    final bookable = _isDayBookable(_selectedDay);
    final completed = _isDayCompleted(_selectedDay);
    final ticketCount = _potTickets.length;

    return Column(
      children: [
        // Pot with tickets
        GestureDetector(
          onTap: bookable ? _drawTicket : null,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shake = _isPotShaking
                  ? sin(_shakeController.value * pi * 4) * 8 * (1 - _shakeController.value)
                  : 0.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Container(
              width: 280,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pot body (glass effect)
                  Positioned(
                    top: 30,
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                          bottomLeft: Radius.circular(48),
                          bottomRight: Radius.circular(48),
                        ),
                        child: Stack(
                          children: [
                            // Glass highlight
                            Positioned(
                              top: 10,
                              left: 15,
                              width: 30,
                              child: Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Tickets pile inside pot
                            _buildTicketsPile(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pot neck
                  Positioned(
                    top: 20,
                    left: 10,
                    right: 10,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pot rim
                  Positioned(
                    top: 15,
                    left: 5,
                    right: 5,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.6),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status text
        if (completed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.red.withOpacity(0.7), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Day Completed - Draw Closed',
                  style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else if (_potTickets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Text(
              'No tickets available - Assign tickets first',
              style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 13),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number, color: AppTheme.goldPrimary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$ticketCount ticket${ticketCount != 1 ? 's' : ''} in pot',
                  style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (bookable && _potTickets.isNotEmpty && !_isDrawing)
          Text(
            'Tap the pot to draw a ticket',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        if (_isDrawing)
          const Text(
            'Drawing...',
            style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildTicketsPile() {
    if (_potTickets.isEmpty) {
      return const Center(
        child: Icon(Icons.inbox, size: 50, color: Colors.white24),
      );
    }

    final random = Random(42); // Fixed seed for consistent layout
    final count = min(_potTickets.length, 30);

    return Stack(
      children: List.generate(count, (i) {
        final left = 15 + random.nextDouble() * 180;
        final top = 20 + random.nextDouble() * 150;
        final rotation = -30 + random.nextDouble() * 60;

        return Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: rotation * pi / 180,
            child: Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7A1839), Color(0xFF3A0B1E)],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '🎫',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDrawnTicket() {
    if (_drawnTicket == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Draw a ticket from the pot',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
        ),
      );
    }

    final ticketCode = _drawnTicket!['ticket_code'] ?? '';
    final userName = _drawnTicket!['user_name'] ?? '';
    final houseNumber = _drawnTicket!['house_number'] ?? '';

    return Column(
      children: [
        if (!_isRevealed)
          Text(
            'Double-click the ticket to reveal',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        if (_isRevealed)
          Text(
            'Winner Revealed!',
            style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 10),
        GestureDetector(
          onDoubleTap: _revealTicket,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 300,
            height: 180,
            child: _isRevealed ? _buildRevealedSide(ticketCode, userName, houseNumber) : _buildCoverSide(),
          ),
        ),
        if (_isRevealed) ...[
          const SizedBox(height: 16),
          Text(
            'Congratulations, $userName!',
            style: const TextStyle(
              color: AppTheme.goldPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'House: $houseNumber',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red, Colors.green, Colors.blue, Colors.yellow,
              Colors.purple, Colors.orange, Colors.white, AppTheme.goldPrimary,
            ],
            numberOfParticles: 30,
            gravity: 0.1,
            emissionFrequency: 0.05,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverSide() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A1839), Color(0xFF3A0B1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎫', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            'DOUBLE-CLICK TO REVEAL',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedSide(String ticketCode, String userName, String houseNumber) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD99A1C), Color(0xFF7A1839)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Star
          const Positioned(
            top: 10,
            right: 14,
            child: Text('🌟', style: TextStyle(fontSize: 22)),
          ),
          // Content overlay
          Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'COUPON CODE',
                    style: TextStyle(
                      color: AppTheme.goldPrimary,
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTicketCode(ticketCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'HOLDER / ASSIGNEE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'House: $houseNumber',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTicketCode(String code) {
    if (code.length >= 10) {
      return '${code.substring(0, 3)} ${code.substring(3, 6)} ${code.substring(6)}';
    }
    return code;
  }

  Widget _buildDrawHistory() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getDailyDrawHistory(dayNumber: _selectedDay),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final history = snapshot.data!;
        if (history.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Winners',
              style: TextStyle(
                color: AppTheme.goldPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...history.take(6).map((draw) {
              final isPrize = draw['prize_level'] != null;
              final prizeLabel = isPrize
                  ? ['🏆 1st', '🥈 2nd', '🥉 3rd'][draw['prize_level'] - 1]
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (isPrize)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(prizeLabel, style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary)),
                      )
                    else
                      const Icon(Icons.confirmation_number, size: 16, color: Colors.white54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draw['ticket_code'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                          ),
                          Text(
                            '${draw['user_name'] ?? ''} • ${draw['house_number'] ?? ''}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
