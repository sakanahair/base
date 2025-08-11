import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';

class QuickActionDial extends StatefulWidget {
  final VoidCallback onNewCustomer;
  final VoidCallback? onStartChat;
  final VoidCallback? onCall;

  const QuickActionDial({
    super.key,
    required this.onNewCustomer,
    this.onStartChat,
    this.onCall,
  });

  @override
  State<QuickActionDial> createState() => _QuickActionDialState();
}

class _QuickActionDialState extends State<QuickActionDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    ResponsiveHelper.addHapticFeedback();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // オーバーレイ
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ).animate().fadeIn(duration: 200.ms),
        
        // アクションボタン
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 新規顧客
            if (_isOpen)
              ScaleTransition(
                scale: _expandAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '新規顧客',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'new_customer',
                      backgroundColor: Colors.green,
                      onPressed: () {
                        _toggle();
                        widget.onNewCustomer();
                      },
                      child: const Icon(Icons.person_add, size: 20),
                    ),
                  ],
                ),
              ).animate().slideX(
                begin: 0.2,
                end: 0,
                duration: 200.ms,
                delay: 50.ms,
              ),
            
            const SizedBox(height: 12),
            
            // 電話
            if (_isOpen && widget.onCall != null)
              ScaleTransition(
                scale: _expandAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '電話',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'call',
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        _toggle();
                        widget.onCall!();
                      },
                      child: const Icon(Icons.phone, size: 20),
                    ),
                  ],
                ),
              ).animate().slideX(
                begin: 0.2,
                end: 0,
                duration: 200.ms,
                delay: 100.ms,
              ),
            
            const SizedBox(height: 12),
            
            // チャット
            if (_isOpen && widget.onStartChat != null)
              ScaleTransition(
                scale: _expandAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'チャット',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'chat',
                      backgroundColor: AppTheme.primaryColor,
                      onPressed: () {
                        _toggle();
                        widget.onStartChat!();
                      },
                      child: const Icon(Icons.chat_bubble, size: 20),
                    ),
                  ],
                ),
              ).animate().slideX(
                begin: 0.2,
                end: 0,
                duration: 200.ms,
                delay: 150.ms,
              ),
            
            const SizedBox(height: 12),
            
            // メインFAB
            FloatingActionButton(
              heroTag: 'main_fab',
              backgroundColor: AppTheme.secondaryColor,
              onPressed: _toggle,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _expandAnimation,
              ),
            ),
          ],
        ),
      ],
    );
  }
}