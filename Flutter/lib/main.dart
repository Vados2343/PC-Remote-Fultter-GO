import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PC Remote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0057B8),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String _currentLang = 'ru';
  bool _rememberMe = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isPassVisible = false;
  bool _isVerifying = false;

  late AnimationController _animController;
  bool _playingAnim = false;

  final Map<String, Map<String, String>> _dict = {
    'en': {'title': 'PC Link', 'connect': 'CONNECT', 'ip': 'IP Address', 'pass': 'Secret Key', 'shutdown': 'SHUTDOWN', 'reboot': 'REBOOT', 'timer': 'Timer', 'minutes': 'min', 'verifying': 'Verifying...', 'error_net': 'PC Offline or Wrong IP', 'error_pass': 'Wrong Password', 'custom_time': 'Set Timer (min)', 'enter_min': 'Enter minutes', 'cancel': 'CANCEL', 'ok': 'START'},
    'ru': {'title': 'PC Remote', 'connect': 'ПОДКЛЮЧИТЬСЯ', 'ip': 'IP Адрес', 'pass': 'Пароль доступа', 'shutdown': 'ВЫКЛЮЧИТЬ', 'reboot': 'ПЕРЕЗАГРУЗИТЬ', 'timer': 'Таймер', 'minutes': 'мин', 'verifying': 'Проверка...', 'error_net': 'ПК не в сети или неверный IP', 'error_pass': 'Неверный пароль', 'custom_time': 'Таймер (минуты)', 'enter_min': 'Через сколько минут?', 'cancel': 'ОТМЕНА', 'ok': 'ПУСК'},
    'uk': {'title': 'Керування ПК', 'connect': 'ПІДКЛЮЧИТИСЬ', 'ip': 'IP Адреса', 'pass': 'Пароль доступу', 'shutdown': 'ВИМКНУТИ', 'reboot': 'ПЕРЕЗАВАНТАЖИТИ', 'timer': 'Таймер', 'minutes': 'хв', 'verifying': 'Перевірка...', 'error_net': 'ПК офлайн або помилка IP', 'error_pass': 'Невірний пароль', 'custom_time': 'Таймер (хвилини)', 'enter_min': 'Через скільки хвилин?', 'cancel': 'СКАСУВАТИ', 'ok': 'ПУСК'},
    'it': {'title': 'Controllo PC', 'connect': 'CONNETTI', 'ip': 'Indirizzo IP', 'pass': 'Password', 'shutdown': 'SPEGNI', 'reboot': 'RIAVVIA', 'timer': 'Timer', 'minutes': 'min', 'verifying': 'Verifica...', 'error_net': 'PC Offline', 'error_pass': 'Password Errata', 'custom_time': 'Timer Spegnimento', 'enter_min': 'Tra quanti minuti?', 'cancel': 'ANNULLA', 'ok': 'AVVIA'},
  };

  String t(String key) => _dict[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _playingAnim = false);
            _animController.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _ipController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ip') ?? '192.168.1.3:8080';
      _currentLang = prefs.getString('lang') ?? 'ru';
      String? savedPass = prefs.getString('pass');
      if (savedPass != null) {
        _passController.text = savedPass;
        _rememberMe = true;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('lang', _currentLang);
    if (_rememberMe) {
      await prefs.setString('pass', _passController.text);
    } else {
      await prefs.remove('pass');
    }
  }

  Future<void> _tryLogin() async {
    if (_ipController.text.isEmpty || _passController.text.isEmpty) return;

    setState(() => _isVerifying = true);

    String baseUrl = _ipController.text;
    if (!baseUrl.startsWith('http')) baseUrl = 'http://$baseUrl';

    final uri = Uri.parse('$baseUrl/check_auth?key=${_passController.text}');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 404 || response.statusCode == 200) {
        await _saveSettings();
        setState(() {
          _isLoggedIn = true;
          _isVerifying = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showSnack(t('error_pass'), Colors.red);
        setState(() => _isVerifying = false);
      } else {
        _showSnack('Error: ${response.statusCode}', Colors.orange);
        setState(() => _isVerifying = false);
      }
    } catch (e) {
      _showSnack(t('error_net'), Colors.red);
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _sendCommand(String cmd, {int? timeMin}) async {
    String baseUrl = _ipController.text;
    if (!baseUrl.startsWith('http')) baseUrl = 'http://$baseUrl';

    String fullCmd = cmd;
    if (timeMin != null) {
      fullCmd += '?time=${timeMin * 60}&key=${_passController.text}';
    } else {
      fullCmd += '?key=${_passController.text}';
    }

    final uri = Uri.parse('$baseUrl/$fullCmd');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _showSnack('OK!', Colors.green);
      } else if (response.statusCode == 401) {
        _showSnack(t('error_pass'), Colors.red);
        setState(() => _isLoggedIn = false);
      }
    } catch (e) {
      _showSnack(t('error_net'), Colors.red);
    }
  }

  void _showTimerDialog() {
    final TextEditingController customTimeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A35),
        title: Row(
          children: [
            const Icon(Icons.timer, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text(t('custom_time'), style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('enter_min'), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 15),
            TextField(
              controller: customTimeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '30',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [10, 30, 60, 120].map((m) => ActionChip(
                label: Text('$m ${t('minutes')}'),
                backgroundColor: const Color(0xFF3E3E4A),
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () => customTimeCtrl.text = m.toString(),
              )).toList(),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              if (customTimeCtrl.text.isNotEmpty) {
                int? min = int.tryParse(customTimeCtrl.text);
                if (min != null) {
                  Navigator.pop(ctx);
                  _sendCommand('shutdown', timeMin: min);
                }
              }
            },
            child: Text(t('ok'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
    ));
  }

  void _onLangChanged(String? lang) {
    if (lang == null) return;
    setState(() => _currentLang = lang);
    _saveSettings();

    if (lang == 'uk') {
      setState(() => _playingAnim = true);
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(t('title'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            actions: [
              _buildLangDropdown(),
              const SizedBox(width: 10),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLoggedIn ? _buildControlPanel() : _buildLoginForm(),
          ),
        ),
        if (_playingAnim) _buildProfessionalAnimation(),
      ],
    );
  }

  Widget _buildLangDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF1E1E2C),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentLang,
          icon: const Icon(Icons.language, color: Colors.white70),
          selectedItemBuilder: (BuildContext context) {
            return ['en', 'ru', 'uk', 'it'].map((l) {
              return Center(child: Text(l.toUpperCase(), style: const TextStyle(color: Colors.white)));
            }).toList();
          },
          items: ['en', 'ru', 'uk', 'it'].map((l) {
            bool isUA = l == 'uk';
            return DropdownMenuItem(
              value: l,
              child: isUA
                  ? SizedBox(
                width: 60,
                height: 30,
                child: Column(
                  children: [
                    Expanded(child: Container(color: const Color(0xFF0057B8))),
                    Expanded(child: Container(color: const Color(0xFFFFD700))),
                  ],
                ),
              )
                  : Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  l.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }).toList(),
          onChanged: _onLangChanged,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(Icons.desktop_windows, size: 60, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 40),
            _buildInput(_ipController, t('ip'), Icons.wifi, false),
            const SizedBox(height: 16),
            _buildInput(_passController, t('pass'), Icons.lock, true),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: Theme.of(context).colorScheme.primary,
                  side: const BorderSide(color: Colors.white54),
                  onChanged: (v) => setState(() => _rememberMe = v!),
                ),
                const Text("Remember me", style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _tryLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                child: _isVerifying
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(t('connect'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, bool isPass) {
    return TextField(
      controller: ctrl,
      obscureText: isPass && !_isPassVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: isPass
            ? IconButton(
          icon: Icon(_isPassVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white38),
          onPressed: () => setState(() => _isPassVisible = !_isPassVisible),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LargeButton(
            text: t('shutdown'),
            icon: Icons.power_settings_new,
            color: Colors.redAccent,
            onTap: () => _sendCommand('shutdown'),
          ),
          const SizedBox(height: 20),
          _LargeButton(
            text: t('custom_time'),
            icon: Icons.timer,
            color: Colors.blueAccent,
            onTap: _showTimerDialog,
          ),
          const SizedBox(height: 20),
          _LargeButton(
            text: t('reboot'),
            icon: Icons.refresh,
            color: Colors.orangeAccent,
            onTap: () => _sendCommand('reboot'),
          ),
          const SizedBox(height: 50),
          TextButton.icon(
            onPressed: () => setState(() => _isLoggedIn = false),
            icon: const Icon(Icons.logout, color: Colors.white38),
            label: const Text("Logout", style: TextStyle(color: Colors.white38)),
          )
        ],
      ),
    );
  }

  Widget _buildProfessionalAnimation() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (ctx, _) {
              return CustomPaint(
                size: const Size(360, 500),
                painter: UkrainianHeartPainter(_animController.value),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LargeButton({required this.text, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class UkrainianHeartPainter extends CustomPainter {
  final double progress;
  UkrainianHeartPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final Paint paint = Paint()..style = PaintingStyle.fill..strokeCap = StrokeCap.round..strokeWidth = 8.0;

    if (progress <= 0.20) {
      double flyProg = progress / 0.20;
      Offset startPos = Offset(size.width - 60, 40);
      double sinPath = sin(flyProg * pi * 2) * 100;
      Offset currentPos = Offset.lerp(startPos, center, Curves.easeInOutCubic.transform(flyProg))!;
      currentPos = Offset(currentPos.dx + sinPath * (1-flyProg), currentPos.dy);
      double w = lerpDouble(80, 140, flyProg)!;
      double h = lerpDouble(50, 100, flyProg)!;
      Rect rect = Rect.fromCenter(center: currentPos, width: w, height: h);
      paint.shader = const LinearGradient(
          colors: [Color(0xFF0057B8), Color(0xFF0057B8), Color(0xFFFFD700), Color(0xFFFFD700)],
          stops: [0.0, 0.5, 0.5, 1.0],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ).createShader(rect);
      canvas.drawRect(rect, paint);
      return;
    }

    if (progress <= 0.45) {
      double pumpProg = (progress - 0.20) / 0.25;
      double scale = 1.0 + sin(pumpProg * 8 * pi) * 0.15 * pumpProg;
      double w = 140.0;
      double h = 100.0 + (40.0 * pumpProg);
      double cornerRadius = 70 * pumpProg;
      Rect rect = Rect.fromCenter(center: center, width: w * scale, height: h * scale);
      RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
      paint.shader = const LinearGradient(
          colors: [Color(0xFF0057B8), Color(0xFF0057B8), Color(0xFFFFD700), Color(0xFFFFD700)],
          stops: [0.0, 0.5, 0.5, 1.0],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ).createShader(rect);
      canvas.drawRRect(rRect, paint);
      return;
    }

    if (progress <= 0.50) {
      double burstProg = (progress - 0.45) / 0.05;
      paint.shader = null;
      for (int i = 0; i < 50; i++) {
        double angle = (2 * pi / 50) * i;
        double dist = 70 + (burstProg * 300);
        double radius = 12 * (1 - burstProg);
        Color pColor = i % 2 == 0 ? const Color(0xFF0057B8) : const Color(0xFFFFD700);
        paint.color = pColor.withOpacity(1 - burstProg);
        canvas.drawCircle(center + Offset(cos(angle) * dist, sin(angle) * dist), radius, paint);
      }
      return;
    }

    Path heartOutline = Path();
    heartOutline.moveTo(center.dx, center.dy + 120);
    heartOutline.cubicTo(center.dx - 220, center.dy + 20, center.dx - 120, center.dy - 160, center.dx, center.dy - 40);
    heartOutline.cubicTo(center.dx + 120, center.dy - 160, center.dx + 220, center.dy + 20, center.dx, center.dy + 120);

    if (progress > 0.50) {
      double fillProg = (progress - 0.50) / 0.50;

      canvas.save();
      canvas.clipPath(heartOutline);

      Paint scribblePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round;

      scribblePaint.color = const Color(0xFFFFD700);
      Path yellowScribble = _generateScribble(
          Rect.fromLTWH(center.dx - 150, center.dy + 10, 300, 120),
          steps: 10
      );
      _drawAnimatedPath(canvas, yellowScribble, scribblePaint, fillProg);

      scribblePaint.color = const Color(0xFF0057B8);
      Path blueScribble = _generateScribble(
          Rect.fromLTWH(center.dx - 150, center.dy - 100, 300, 110),
          steps: 10
      );
      _drawAnimatedPath(canvas, blueScribble, scribblePaint, fillProg);

      canvas.restore();

      if (fillProg > 0.6) {
        double textOp = (fillProg - 0.6) * 2.5;
        if(textOp>1) textOp=1;
        _drawText(canvas, size, center, textOp);
      }
    }
  }

  Path _generateScribble(Rect rect, {required int steps}) {
    Path path = Path();
    path.moveTo(rect.left, rect.top);
    double stepHeight = rect.height / steps;
    for (int i = 0; i < steps; i++) {
      double y = rect.top + (i * stepHeight);
      path.lineTo(rect.right, y + (stepHeight/2));
      path.lineTo(rect.left, y + stepHeight);
    }
    return path;
  }

  void _drawAnimatedPath(Canvas canvas, Path path, Paint paint, double progress) {
    for (PathMetric m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  void _drawText(Canvas canvas, Size size, Offset center, double opacity) {
    const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]
    );

    final textSpan1 = TextSpan(text: "НЕЗЛАМНИЙ НАРОД", style: textStyle.copyWith(color: Colors.white.withOpacity(opacity)));
    final textPainter1 = TextPainter(text: textSpan1, textDirection: TextDirection.ltr);
    textPainter1.layout();
    textPainter1.paint(canvas, Offset(size.width / 2 - textPainter1.width / 2, center.dy + 140));

    final textSpan2 = TextSpan(text: "НЕЗЛАМНОЇ КРАЇНИ", style: textStyle.copyWith(color: const Color(0xFFFFD700).withOpacity(opacity), fontSize: 22));
    final textPainter2 = TextPainter(text: textSpan2, textDirection: TextDirection.ltr);
    textPainter2.layout();
    textPainter2.paint(canvas, Offset(size.width / 2 - textPainter2.width / 2, center.dy + 175));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}