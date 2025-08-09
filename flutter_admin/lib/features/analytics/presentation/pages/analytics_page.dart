import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Text(
          '分析',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}