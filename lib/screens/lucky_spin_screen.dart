import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/shop_items.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_gradients.dart';

/// Ads required to unlock one spin.
const int _adsRequiredPerSpin = 2;

/// Wheel segments: 0 = empty, 1/2/3 = progress multiplier. Many segments for a realistic feel.
const List<int> _wheelValues = [
  0, 1, 0, 2, 0, 1, 3, 0, 2, 1, 0, 3, // 12 segments: empties and rewards
];

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key, required this.uid});

  final String uid;

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen> with TickerProviderStateMixin {
  ShopItem? _selectedItem;
  int _adsWatchedForSpin = 0;
  bool _spinning = false;
  int? _lastResult;
  double _totalRotation = 0;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  static const int _fullSpins = 6;
  static const int _segmentCount = 12;
  static const double _segmentDeg = 360.0 / _segmentCount;

  bool get _canSpin => _adsWatchedForSpin >= _adsRequiredPerSpin && !_spinning;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  /// Land wheel so segment at [segmentIndex] (0..11) is under the pointer (top).
  double _endAngleForSegmentIndex(int segmentIndex) {
    final centerDeg = -90.0 + (segmentIndex + 0.5) * _segmentDeg;
    final rotationDeg = _fullSpins * 360 + (90 - centerDeg);
    return rotationDeg * pi / 180;
  }

  Future<void> _watchAd() async {
    if (_selectedItem == null || _adsWatchedForSpin >= _adsRequiredPerSpin) return;
    if (!AdService.instance.isRewardedAdReady) {
      AdService.instance.loadRewardedAd(
        onLoaded: () {
          if (mounted) _doWatchAd();
        },
        onFailed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ad not ready. Try again soon.')),
            );
          }
        },
      );
      return;
    }
    await _doWatchAd();
  }

  Future<void> _doWatchAd() async {
    await AdService.instance.showRewardedAd(
      onReward: () {
        if (!mounted) return;
        setState(() {
          _adsWatchedForSpin = (_adsWatchedForSpin + 1).clamp(0, _adsRequiredPerSpin);
        });
        if (_adsWatchedForSpin >= _adsRequiredPerSpin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spin unlocked! Tap Spin to try your luck.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Watch ${_adsRequiredPerSpin - _adsWatchedForSpin} more ad to spin.')),
          );
        }
      },
      onFailed: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad failed: $msg')),
          );
        }
      },
    );
  }

  Future<void> _spinWheel() async {
    if (!_canSpin || _selectedItem == null) return;
    final item = _selectedItem!;
    final rnd = Random();
    final segmentIndex = rnd.nextInt(_wheelValues.length);
    final result = _wheelValues[segmentIndex];
    final endAngle = _endAngleForSegmentIndex(segmentIndex);

    setState(() {
      _spinning = true;
      _lastResult = null;
    });

    _spinAnimation = Tween<double>(begin: 0, end: endAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
    _spinController.reset();
    _spinController.forward();
    await _spinController.forward();

    if (!mounted) return;
    _totalRotation += endAngle;

    if (result > 0) {
      final newCount = await DatabaseService.instance.addShopProgress(widget.uid, item.id, result);
      await DatabaseService.instance.incrementLuckySpinCount(widget.uid, item.id);
      if (newCount >= item.adsRequired) {
        await NotificationService.instance.showShopNotification(
          title: 'Unlocked!',
          body: '${item.name} is yours from Lucky Spin. ${item.description}',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$result× progress! ${item.name}: $newCount/${item.adsRequired}${newCount >= item.adsRequired ? ' – Unlocked!' : ''}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Try again! Watch more ads and spin again.')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _spinning = false;
      _lastResult = result;
      _adsWatchedForSpin = 0;
    });
  }

  LinearGradient _gradientFor(ShopItem item) {
    switch (item.type) {
      case 'rig': return AppGradients.blue;
      case 'booster': return AppGradients.emerald;
      default: return AppGradients.magenta;
    }
  }

  IconData _iconFor(ShopItem item) {
    switch (item.type) {
      case 'rig': return Icons.memory;
      case 'booster': return Icons.bolt;
      default: return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedItem == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lucky Spin'),
          backgroundColor: const Color(0xFFF9F4F7),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.casino, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a pack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Watch $_adsRequiredPerSpin ads to unlock one spin. Wheel has rewards and empty slots!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: DatabaseService.instance.shopProgressStream(widget.uid),
                builder: (context, snap) {
                  final data = snap.data ?? {};
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ShopItem.all.map((item) {
                      final progress = _progress(data, item.id);
                      final spinCount = data['luckySpinCount_${item.id}'] is num
                          ? (data['luckySpinCount_${item.id}'] as num).toInt()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selectedItem = item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: _gradientFor(item),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_iconFor(item), color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF2E123B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _chip('$progress/${item.adsRequired} ads', Colors.blue),
                                            if (spinCount > 0) ...[
                                              const SizedBox(width: 8),
                                              _chip('$spinCount spin${spinCount == 1 ? '' : 's'}', Colors.amber),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucky Spin'),
        backgroundColor: const Color(0xFFF9F4F7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _spinning ? null : () => setState(() => _selectedItem = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: _gradientFor(_selectedItem!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(_selectedItem!), color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    _selectedItem!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip('$_adsWatchedForSpin/$_adsRequiredPerSpin ads', Colors.blue),
                if (_canSpin) ...[
                  const SizedBox(width: 12),
                  _chip('Spin ready!', Colors.green),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _totalRotation + _spinAnimation.value,
                        child: child,
                      );
                    },
                    child: _SpinWheel(size: 260, segments: _wheelValues),
                  ),
                  Positioned(
                    top: 0,
                    child: SizedBox(
                      width: 24,
                      height: 32,
                      child: CustomPaint(
                        painter: _NeedlePainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: 12),
              Text(
                _lastResult! == 0
                    ? 'Last spin: Try again'
                    : 'Last spin: $_lastResult× progress!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _lastResult! == 0 ? Colors.grey.shade700 : Colors.amber.shade800,
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (_canSpin)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _spinning ? null : _spinWheel,
                  icon: _spinning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.casino, size: 28),
                  label: Text(_spinning ? 'Spinning...' : 'SPIN!'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _spinning ? null : _watchAd,
                  icon: const Icon(Icons.play_circle_filled, size: 24),
                  label: Text('Watch ad ($_adsWatchedForSpin/$_adsRequiredPerSpin)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              _canSpin
                  ? 'Tap SPIN to spin the wheel. You might get 1×, 2× or 3× progress – or try again.'
                  : 'Watch $_adsRequiredPerSpin ads to unlock one spin for ${_selectedItem!.name}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  int _progress(Map<String, dynamic> data, String itemId) {
    final key = 'adsFor${itemId[0].toUpperCase()}${itemId.substring(1)}';
    final v = data[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

Color _wheelColorForValue(int value) {
  switch (value) {
    case 0: return Colors.grey.shade400;
    case 1: return const Color(0xFF1B5E20);
    case 2: return const Color(0xFFE65100);
    case 3: return const Color(0xFF0D47A1);
    default: return Colors.grey;
  }
}

String _wheelLabelForValue(int value) {
  if (value == 0) return '—';
  return '$value×';
}

class _SpinWheel extends StatelessWidget {
  const _SpinWheel({required this.size, required this.segments});

  final double size;
  final List<int> segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _WheelPainter(segments: segments),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.segments});

  final List<int> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final value = segments[i];
      final color = _wheelColorForValue(value);
      final startAngle = -pi / 2 + i * sweep;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      final textAngle = startAngle + sweep / 2;
      final textRadius = radius * 0.6;
      final dx = center.dx + textRadius * cos(textAngle);
      final dy = center.dy + textRadius * sin(textAngle);
      final label = _wheelLabelForValue(value);
      final fontSize = value == 0 ? 18.0 : 22.0;
      _drawText(canvas, label, dx, dy, value == 0 ? Colors.grey.shade600 : Colors.white, fontSize);
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, double fontSize) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(x - tp.width / 2, y - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    const needleWidth = 3.0;
    final path = Path()
      ..moveTo(centerX, 0)
      ..lineTo(centerX - needleWidth, h * 0.4)
      ..lineTo(centerX, h)
      ..lineTo(centerX + needleWidth, h * 0.4)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.amber.shade700
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(centerX, 0),
      5,
      Paint()..color = Colors.amber.shade800,
    );
    canvas.drawCircle(
      Offset(centerX, 0),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
