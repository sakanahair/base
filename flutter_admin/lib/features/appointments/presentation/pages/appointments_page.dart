import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Text(
          '予約管理',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}