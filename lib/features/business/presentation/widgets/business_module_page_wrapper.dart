import 'package:flutter/material.dart';

class BusinessModulePageWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BusinessModulePageWrapper({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: theme.appBarTheme.titleTextStyle ??
              TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
        ),
        actions: actions,
        scrolledUnderElevation: 1.0,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
