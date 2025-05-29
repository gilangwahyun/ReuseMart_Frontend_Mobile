import 'package:flutter/material.dart';
import '../custom_app_bar.dart';

class BaseLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  const BaseLayout({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        backgroundColor: backgroundColor,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? Colors.white,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
