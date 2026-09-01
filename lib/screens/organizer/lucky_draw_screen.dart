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

class _LuckyDrawScreenState extends State<LuckyDrawScreen> {
  int _selectedDay = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _potTickets = [];
  Map<String, dynamic>? _drawnTicket;
  bool _isRevealed = false;
  bool _isDrawing = false;
  bool _isProcessing = false;
  int? _currentDrawId;
  int? _assignedPrizeLevel;
  bool _isCancelling = false;
  bool _isRedrawing = false;
  String? _cancelledReason;
  int? _cancelledPrizeLevel;
  int _shakeOffset = 0;
  Timer? _shakeTimer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _initDay();
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _confettiController.dispose();
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

  void _startShake() {
    int count = 0;
    _shakeTimer?.cancel();
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      count++;
      setState(() => _shakeOffset = count.isEven ? 8 : -8);
      if (count >= 8) {
        timer.cancel();
        setState(() => _shakeOffset = 0);
      }
    });
  }

  Future<void> _drawTicket() async {
    if (_isDrawing || _potTickets.isEmpty || !_isDayBookable(_selectedDay)) return;

    setState(() => _isDrawing = true);
    _startShake();

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final index = random.nextInt(_potTickets.length);
    final ticket = _potTickets[index];

    setState(() {
      _drawnTicket = ticket;
      _potTickets.removeAt(index);
      _isRevealed = false;
      _isDrawing = false;
    });
  }

  void _revealTicket() {
    if (_drawnTicket == null || _isRevealed) return;
    setState(() => _isRevealed = true);
    _confettiController.play();
    _createDrawRecord();
  }

  Future<void> _createDrawRecord() async {
    if (_drawnTicket == null) return;
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?['id'] ?? 0;
      final result = await DatabaseHelper.createDraw(
        dayNumber: _selectedDay,
        ticketId: _drawnTicket!['id'] ?? 0,
        ticketCode: _drawnTicket!['ticket_code'] ?? '',
        winnerId: _drawnTicket!['user_id'] ?? 0,
        houseNumber: _drawnTicket!['house_number'] ?? '',
        drawnBy: userId,
      );
      if (mounted) {
        setState(() => _currentDrawId = result['id']);
      }
    } catch (e) {
      // Silently handle - draw record creation is best-effort
    }
  }

  void _showAvailabilityDialog() {
    if (_drawnTicket == null || _currentDrawId == null) return;
    final userName = _drawnTicket!['user_name'] ?? '';
    final houseNumber = _drawnTicket!['house_number'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Is person available?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$userName (House: $houseNumber)',
              style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Is this person present at the lucky draw?',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _disqualifyPerson();
            },
            child: const Text('Not Available', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmPerson();
            },
            child: const Text('Available', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPerson() async {
    if (_currentDrawId == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await DatabaseHelper.confirmDraw(_currentDrawId!, _selectedDay);
      if (mounted) {
        setState(() {
          _assignedPrizeLevel = result['prize_level'];
          _isProcessing = false;
        });
        _loadTickets();
        _showPrizeResult(result['prize_level']);
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _disqualifyPerson() async {
    if (_currentDrawId == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await DatabaseHelper.disqualifyDraw(_currentDrawId!, _selectedDay);
      if (mounted) {
        setState(() {
          _drawnTicket = null;
          _isRevealed = false;
          _currentDrawId = null;
          _isProcessing = false;
        });
        _loadTickets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['rescheduled_to_day'] != null
                ? 'Person not available. Ticket moved to Day ${result['rescheduled_to_day']}'
                : 'Person not available. Ticket removed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelPrize() async {
    if (_currentDrawId == null) return;
    
    // Show dialog to get cancellation reason
    final reason = await _showCancelDialog();
    if (reason == null || reason.isEmpty) return;
    
    setState(() => _isCancelling = true);
    try {
      final result = await DatabaseHelper.cancelDraw(
        drawId: _currentDrawId!,
        reason: reason,
      );
      if (mounted) {
        setState(() {
          _cancelledReason = reason;
          _cancelledPrizeLevel = result['prize_level'];
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prize cancelled successfully. Reason: $reason'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel prize: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Cancel Prize', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to cancel this prize? The ticket will be returned to the pot for re-draw.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason for cancellation *',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.goldPrimary),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: reasonController.text.isEmpty
                ? null
                : () => Navigator.pop(ctx, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRedraw() async {
    if (_currentDrawId == null || _cancelledPrizeLevel == null) return;
    
    setState(() => _isRedrawing = true);
    try {
      // Reset the state to allow a new draw
      setState(() {
        _drawnTicket = null;
        _isRevealed = false;
        _currentDrawId = null;
        _assignedPrizeLevel = null;
        _cancelledReason = null;
        _cancelledPrizeLevel = null;
        _isRedrawing = false;
      });
      _loadTickets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ready for re-draw. Generate a new ticket.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isRedrawing = false);
    }
  }

  void _showPrizeResult(int? prizeLevel) {
    String prizeText;
    String prizeIcon;
    if (prizeLevel == 1) {
      prizeText = '1st Prize Winner!';
      prizeIcon = '🏆';
    } else if (prizeLevel == 2) {
      prizeText = '2nd Prize Winner!';
      prizeIcon = '🥈';
    } else if (prizeLevel == 3) {
      prizeText = '3rd Prize Winner!';
      prizeIcon = '🥉';
    } else {
      prizeText = 'Winner!';
      prizeIcon = '🎉';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prizeIcon, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 12),
            Text(
              prizeText,
              style: TextStyle(
                color: prizeLevel != null ? AppTheme.goldPrimary : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_drawnTicket?['user_name'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'House: ${_drawnTicket?['house_number'] ?? ''}',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _drawnTicket = null;
                _isRevealed = false;
                _currentDrawId = null;
                _assignedPrizeLevel = null;
              });
            },
            child: const Text('OK', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
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
          child: Transform.translate(
            offset: Offset(_shakeOffset.toDouble(), 0),
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
          if (_assignedPrizeLevel == null && _currentDrawId != null && !_isProcessing) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAvailabilityDialog,
              icon: const Icon(Icons.person_search, color: Colors.white),
              label: const Text('Check Availability', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: AppTheme.goldPrimary, strokeWidth: 2),
            ),
          // Cancel Prize button - show when winner is confirmed
          if (_assignedPrizeLevel != null && _cancelledReason == null && !_isCancelling) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cancelPrize,
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text('Cancel Prize', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
          if (_isCancelling)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
            ),
          // Re-draw button - show after cancellation
          if (_cancelledReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  Text(
                    'Prize Cancelled',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $_cancelledReason',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isRedrawing ? null : _startRedraw,
                    icon: _isRedrawing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, color: Colors.white),
                    label: Text(_isRedrawing ? 'Re-drawing...' : 'Re-draw Prize', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: AppTheme.purpleDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              final isDisqualified = draw['status'] == 'disqualified';
              final prizeLabel = isPrize
                  ? ['🏆 1st', '🥈 2nd', '🥉 3rd'][draw['prize_level'] - 1]
                  : isDisqualified
                      ? '❌ Disqualified'
                      : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDisqualified
                      ? Colors.red.withOpacity(0.1)
                      : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: isDisqualified
                      ? Border.all(color: Colors.red.withOpacity(0.3))
                      : null,
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
                    else if (isDisqualified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(prizeLabel, style: TextStyle(fontSize: 10, color: Colors.red.withOpacity(0.7))),
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
                            style: TextStyle(
                              color: isDisqualified ? Colors.white54 : Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              decoration: isDisqualified ? TextDecoration.lineThrough : null,
                            ),
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
