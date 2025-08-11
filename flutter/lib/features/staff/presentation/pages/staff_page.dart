import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Text(
          'スタッフ管理',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}