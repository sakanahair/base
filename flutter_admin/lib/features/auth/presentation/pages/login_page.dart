import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/splash_screen.dart';
import '../../../../shared/utils/responsive_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _showSplash = true;
  bool _isLoading = false;
  late AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Show splash for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated Wave Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _gridController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _gridController.value,
                      color: AppTheme.primaryColor.withOpacity(0.05),
                    ),
                  );
                },
              ),
            ),
            
            // Main Content
            Center(
              child: SingleChildScrollView(
                padding: context.responsivePadding,
                child: Container(
                  width: isMobile ? double.infinity : (isTablet ? 500 : 400),
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 500,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isMobile ? 60 : 120),
                      
                      // Logo - Same as splash screen
                      Text(
                        'SAKANA HAIR',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 24,
                            mobileScale: 1.0,
                            tabletScale: 1.1,
                          ),
                          fontWeight: FontWeight.w200,
                          letterSpacing: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 7.2,
                            mobileScale: 0.9,
                          ),
                          color: AppTheme.secondaryColor,
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
                  
                      // Animated bar like splash screen
                      SizedBox(height: isMobile ? 16 : 20),
                      AnimatedBuilder(
                        animation: _gridController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset((_gridController.value - 0.5) * (isMobile ? 40 : 60), 0),
                            child: Container(
                              width: isMobile ? 40 : 60,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.primaryColor,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  
                      SizedBox(height: isMobile ? 40 : 60),
                      
                      // Title
                      Text(
                        'ビジネスをもっとスマートに',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 16,
                            mobileScale: 0.9,
                          ),
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                  
                      SizedBox(height: isMobile ? 48 : 80),
                      
                      // Social Login Buttons
                      _buildSocialButton(
                        context: context,
                        icon: Icons.chat,
                        label: 'LINEで続行',
                        onPressed: () => _handleSocialLogin('LINE'),
                        isPrimary: true,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      _buildSocialButton(
                        context: context,
                        icon: Icons.g_mobiledata,
                        label: 'Googleで続行',
                        onPressed: () => _handleSocialLogin('Google'),
                        isPrimary: false,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                      
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      _buildSocialButton(
                        context: context,
                        icon: Icons.apple,
                        label: 'Appleで続行',
                        onPressed: () => _handleSocialLogin('Apple'),
                        isPrimary: false,
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                  
                      SizedBox(height: isMobile ? 24 : 32),
                      
                      // Divider with text
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppTheme.borderColor,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                            child: Text(
                              'その他のオプション',
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  baseFontSize: 14,
                                  mobileScale: 0.9,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 700.ms),
                  
                      SizedBox(height: isMobile ? 24 : 32),
                      
                      // Admin Login Button
                      TextButton(
                        onPressed: () {
                          if (context.isTouchDevice) {
                            ResponsiveHelper.addHapticFeedback();
                          }
                          _showAdminLoginDialog();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.fromHeight(context.responsiveButtonHeight),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 12,
                            vertical: isMobile ? 12 : 8,
                          ),
                        ),
                        child: Text(
                          '管理者としてログイン',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              baseFontSize: 14,
                              mobileScale: 1.0,
                            ),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final isMobile = context.isMobile;
    final buttonHeight = ResponsiveHelper.getResponsiveButtonHeight(context);
    
    return SizedBox(
      width: double.infinity,
      height: math.max(buttonHeight, ResponsiveHelper.minTouchTarget),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          if (context.isTouchDevice) {
            ResponsiveHelper.addHapticFeedback();
          }
          onPressed();
        },
        icon: Icon(
          icon, 
          size: ResponsiveHelper.getResponsiveIconSize(context),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              baseFontSize: 16,
              mobileScale: 1.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.secondaryColor : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppTheme.textPrimary,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context) * 2),
            side: BorderSide(
              color: isPrimary ? AppTheme.secondaryColor : AppTheme.borderColor,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 14 : 12,
          ),
        ),
      ),
    );
  }
  
  void _handleSocialLogin(String provider) async {
    if (context.isTouchDevice) {
      ResponsiveHelper.addHapticFeedbackMedium();
    }
    
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    final success = await _authService.loginWithProvider(provider);
    
    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      ResponsiveHelper.showResponsiveSnackBar(
        context,
        message: '${provider}ログインに失敗しました',
        backgroundColor: AppTheme.errorColor,
      );
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showAdminLoginDialog() {
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);
    final isMobile = context.isMobile;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        ),
        child: Container(
          padding: context.responsivePadding,
          constraints: dialogConstraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '管理者ログイン',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    baseFontSize: 20,
                    mobileScale: 0.95,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.responsiveSpacing),
              TextField(
                controller: _emailController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'ユーザー名',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                  ),
                  filled: true,
                  fillColor: AppTheme.sidebarBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                  ),
                  filled: true,
                  fillColor: AppTheme.sidebarBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hint: admin / Pass12345',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      baseFontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.responsiveSpacing),
              
              // Responsive button layout
              if (isMobile)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: context.responsiveButtonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.isTouchDevice) {
                            ResponsiveHelper.addHapticFeedback();
                          }
                          _handleAdminLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                          ),
                        ),
                        child: const Text(
                          'ログイン',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: context.responsiveButtonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          if (context.isTouchDevice) {
                            ResponsiveHelper.addHapticFeedback();
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          'キャンセル',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (context.isTouchDevice) {
                          ResponsiveHelper.addHapticFeedback();
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        'キャンセル',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (context.isTouchDevice) {
                          ResponsiveHelper.addHapticFeedback();
                        }
                        _handleAdminLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                        ),
                      ),
                      child: const Text(
                        'ログイン',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleAdminLogin() async {
    if (context.isTouchDevice) {
      ResponsiveHelper.addHapticFeedbackMedium();
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (success && mounted) {
      Navigator.pop(context);
      context.go('/dashboard');
    } else if (mounted) {
      ResponsiveHelper.showResponsiveSnackBar(
        context,
        message: '認証に失敗しました',
        backgroundColor: AppTheme.errorColor,
      );
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Wave Painter for background animation
class WavePainter extends CustomPainter {
  final double animation;
  final Color color;
  
  WavePainter({required this.animation, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Draw flowing waves
    for (int i = 0; i < 3; i++) {
      final yOffset = size.height * (0.3 + i * 0.2);
      final waveHeight = 30.0;
      final waveLength = size.width / 2;
      
      path.moveTo(0, yOffset);
      
      for (double x = 0; x <= size.width; x += 1) {
        final y = yOffset + 
            waveHeight * sin((x / waveLength + animation * 2 + i) * 2 * pi);
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      canvas.drawPath(
        path,
        paint..color = color.withOpacity(0.03 * (3 - i)),
      );
      path.reset();
    }
    
    // Draw floating circles
    for (int i = 0; i < 5; i++) {
      final circleX = size.width * (0.1 + i * 0.2);
      final circleY = size.height * (0.2 + 0.3 * sin(animation * 2 + i));
      final radius = 40.0 + 20 * sin(animation * 3 + i);
      
      canvas.drawCircle(
        Offset(circleX, circleY),
        radius,
        paint..color = color.withOpacity(0.02),
      );
    }
  }
  
  @override
  bool shouldRepaint(WavePainter oldDelegate) => 
      oldDelegate.animation != animation || oldDelegate.color != color;
}

double sin(double radians) => math.sin(radians);
const double pi = math.pi;