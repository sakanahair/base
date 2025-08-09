import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Text(
          'サービス管理',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}