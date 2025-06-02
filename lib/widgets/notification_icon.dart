import 'package:flutter/material.dart';
import '../utils/notification_helper.dart';
import '../routes/app_routes.dart';
import 'dart:async';

class NotificationIcon extends StatefulWidget {
  final Color? color;
  final double size;
  final Color? badgeColor;

  const NotificationIcon({
    super.key,
    this.color,
    this.size = 24.0,
    this.badgeColor,
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  bool _hasUnread = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();

    // Setup timer untuk refresh status notifikasi setiap 30 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkUnreadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      // Gunakan refresh untuk mendapatkan data terbaru dari server
      await NotificationHelper.refreshUnreadCount();
      final hasUnread = await NotificationHelper.hasUnreadNotifications();

      if (mounted) {
        setState(() {
          _hasUnread = hasUnread;
        });
      }
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: widget.color,
            size: widget.size,
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.notifications,
            ).then((_) => _checkUnreadNotifications());
          },
        ),
        if (_hasUnread)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            ),
          ),
      ],
    );
  }
}
