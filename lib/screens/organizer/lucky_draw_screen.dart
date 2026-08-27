import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class LuckyDrawScreen extends StatefulWidget {
  const LuckyDrawScreen({super.key});

  @override
  State<LuckyDrawScreen> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends State<LuckyDrawScreen> {
  int _selectedDay = 1;
  int _spinsToday = 0;
  int _maxSpins = 6;
  bool _isSpinning = false;
  bool _isLoading = true;
  Map<String, dynamic>? _lastResult;
  List<Map<String, dynamic>> _drawHistory = [];
  List<Map<String, dynamic>> _days = [];

  // Slot machine state
  List<int> _currentDigits = List.generate(10, (_) => 0);
  List<int> _targetDigits = List.generate(10, (_) => 0);
  List<bool> _digitLocked = List.generate(10, (_) => true);
  Timer? _spinTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final countData = await DatabaseHelper.getDailyDrawCount(_selectedDay);
    final history = await DatabaseHelper.getDailyDrawHistory(dayNumber: _selectedDay);
    final days = await DatabaseHelper.getNavratriDays();
    setState(() {
      _spinsToday = countData['count'] ?? 0;
      _maxSpins = countData['max'] ?? 6;
      _drawHistory = history;
      _days = days;
      _isLoading = false;
    });
  }

  Map<String, dynamic>? _getDayData(int dayNum) {
    final matches = _days.where((d) => d['day_number'] == dayNum);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> _doSpin() async {
    if (_spinsToday >= _maxSpins || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _lastResult = null;
      _digitLocked = List.generate(10, (_) => false);
      _currentDigits = List.generate(10, (_) => 0);
    });

    // Start all digits spinning
    _spinTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted || _isSpinning == false) {
        timer.cancel();
        return;
      }
      setState(() {
        for (int i = 0; i < 10; i++) {
          if (!_digitLocked[i]) {
            _currentDigits[i] = _random.nextInt(10);
          }
        }
      });
    });

    // Call API to get the result
    final auth = context.read<AuthProvider>();
    final result = await DatabaseHelper.spinDraw(
      dayNumber: _selectedDay,
      drawnBy: auth.currentUser?['id'] ?? 0,
    );

    if (result != null) {
      // Parse the ticket code into 10 digits
      final code = (result['ticket_code'] ?? '0000000000').toString();
      final padded = code.padLeft(10, '0');
      _targetDigits = padded.split('').map((c) => int.tryParse(c) ?? 0).toList();
    } else {
      _targetDigits = List.generate(10, (_) => 0);
    }

    // Lock digits one by one every 300ms
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) {
        _spinTimer?.cancel();
        return;
      }
      setState(() {
        _digitLocked[i] = true;
        _currentDigits[i] = _targetDigits[i];
      });
    }

    _spinTimer?.cancel();

    // Small pause after all digits locked
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isSpinning = false;
      _lastResult = result;
    });

    if (result != null) {
      _showWinnerDialog(result);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more tickets available to draw'), backgroundColor: Colors.orange),
        );
      }
    }
    _loadData();
  }

  void _showWinnerDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.goldPrimary, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Draw #${result['draw_number']}', style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    result['ticket_code'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary, letterSpacing: 3),
                  ),
                  const SizedBox(height: 8),
                  Text(result['user_name'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('House: ${result['house_number'] ?? ''}', style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
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
        title: const Text('Lucky Draw', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDaySelector(),
                  const SizedBox(height: 16),
                  _buildSpinCounter(),
                  const SizedBox(height: 24),
                  _buildSlotMachine(),
                  const SizedBox(height: 16),
                  _buildSpinButton(),
                  const SizedBox(height: 20),
                  if (_lastResult != null) _buildLastResult(),
                  const SizedBox(height: 20),
                  _buildDrawHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final dayData = _getDayData(day);
          final isActive = dayData?['is_active'] == true;
          final isCompleted = dayData?['is_completed'] == true;
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () { setState(() => _selectedDay = day); _loadData(); },
            child: Container(
              width: 65,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : (isCompleted ? Colors.green.withOpacity(0.3) : AppTheme.cardBg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? Colors.amber : Colors.white24, width: isActive ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('D$day', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (isActive) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  if (isCompleted) const Icon(Icons.check_circle, size: 12, color: Colors.green),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpinCounter() {
    final remaining = _maxSpins - _spinsToday;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.purpleCard, AppTheme.purpleDeep]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino, color: AppTheme.goldPrimary, size: 24),
              const SizedBox(width: 8),
              Text('Spins Today: $_spinsToday / $_maxSpins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _maxSpins > 0 ? _spinsToday / _maxSpins : 0,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(remaining > 0 ? AppTheme.goldPrimary : Colors.red),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text('$remaining spins remaining', style: TextStyle(fontSize: 12, color: remaining > 0 ? AppTheme.goldPrimary : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldPrimary, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final isLocked = _digitLocked[index];
          return Container(
            width: 32,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isLocked ? AppTheme.purpleDeep : Colors.black,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isLocked ? AppTheme.goldPrimary : Colors.white24,
                width: isLocked ? 2 : 1,
              ),
              boxShadow: isLocked
                  ? [BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.4), blurRadius: 6)]
                  : [],
            ),
            child: Center(
              child: Text(
                '${_currentDigits[index]}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? AppTheme.goldPrimary : Colors.white54,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSpinButton() {
    final canSpin = _spinsToday < _maxSpins && !_isSpinning;
    return GestureDetector(
      onTap: canSpin ? _doSpin : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          gradient: canSpin
              ? const LinearGradient(colors: [AppTheme.goldPrimary, Color(0xFFB8860B)])
              : LinearGradient(colors: [Colors.grey, Colors.black54]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: canSpin
              ? [BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.5), blurRadius: 15, spreadRadius: 3)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isSpinning ? Icons.hourglass_top : Icons.play_arrow, color: canSpin ? Colors.black : Colors.white70, size: 28),
            const SizedBox(width: 10),
            Text(
              _isSpinning ? 'SPINNING...' : (_spinsToday >= _maxSpins ? 'LIMIT REACHED' : 'SPIN NOW'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: canSpin ? Colors.black : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), AppTheme.purpleCard]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text('Last Winner', style: TextStyle(fontSize: 14, color: Colors.green)),
          const SizedBox(height: 8),
          Text(_lastResult!['ticket_code'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(_lastResult!['user_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('House: ${_lastResult!['house_number'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDrawHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Draw History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
        const SizedBox(height: 8),
        if (_drawHistory.isEmpty)
          const Center(child: Text('No draws yet today', style: TextStyle(color: AppTheme.textMuted)))
        else
          ..._drawHistory.map((draw) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.hubItemDecoration,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Center(child: Text('#${draw['draw_number'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.purpleDark))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draw['ticket_code'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1)),
                      Text(draw['winner_name'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.goldPrimary)),
                    ],
                  ),
                ),
                Text(draw['house_number'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          )),
      ],
    );
  }
}
