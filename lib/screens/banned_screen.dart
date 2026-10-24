import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/theme_palette.dart';

class DeviceBannedScreen extends StatelessWidget {
  final String banReason;
  final PremiumPalette palette;

  const DeviceBannedScreen({
    super.key,
    required this.banReason,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final reasonText = banReason.trim().isNotEmpty
        ? banReason.trim()
        : 'Your device has been restricted by the administrator from accessing this application.';

    return PopScope(
      canPop: false, // Prevent bypassing via Android back button
      child: Scaffold(
        backgroundColor: palette.backgroundColor, // Solid luxury color, NO BORDER
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: Color(0xFFEF4444),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Access Suspended',
                    style: TextStyle(
                      color: palette.numTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reasonText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.secondaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.opButtonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide.none, // Strictly NO border
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () async {
                      final emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@calculator.app',
                        query: 'subject=App Access Inquiry&body=Reason: ${Uri.encodeComponent(reasonText)}',
                      );
                      try {
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      } catch (_) {}
                    },
                    child: Text(
                      'Contact Support',
                      style: TextStyle(
                        color: palette.opTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
