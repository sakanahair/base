import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _fadeInUp;
  late Animation<double> _opacity;
  late Animation<Offset> _loadingBar;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _loadingBar = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: const Offset(0.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _opacity,
                  child: SlideTransition(
                    position: _fadeInUp,
                    child: const Text(
                      'SAKANA HAIR',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 7.2, // 0.3em * 24px
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 60,
              height: 1,
              child: AnimatedBuilder(
                animation: _loadingBar,
                builder: (context, child) {
                  return SlideTransition(
                    position: _loadingBar,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF8B7962),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}