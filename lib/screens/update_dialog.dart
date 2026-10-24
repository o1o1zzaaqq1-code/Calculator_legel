import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';
import '../models/theme_palette.dart';

class UpdateDialog extends StatelessWidget {
  final AppConfig config;
  final PremiumPalette palette;
  final VoidCallback onDismiss;

  const UpdateDialog({
    super.key,
    required this.config,
    required this.palette,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isForce = config.forceUpdate;
    final isCancelable = config.isCancelable && !isForce;

    return PopScope(
      canPop: isCancelable,
      child: AlertDialog(
        backgroundColor: palette.menuBackgroundColor, // Solid, NO BORDER
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none, // Strictly NO border
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.system_update_rounded,
                  color: palette.accentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                config.updateTitle.isNotEmpty
                    ? config.updateTitle
                    : 'Update Required',
                style: TextStyle(
                  color: palette.numTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.updateDescription.isNotEmpty
                  ? config.updateDescription
                  : 'A newer and faster version of Calculator is available. Please update now!',
              style: TextStyle(
                color: palette.secondaryTextColor,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Required Version: v${config.minVersion}',
              style: TextStyle(
                color: palette.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          if (isCancelable)
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Later',
                style: TextStyle(color: palette.secondaryTextColor),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.opButtonColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
            onPressed: () async {
              final targetUrl = config.updateUrl.isNotEmpty
                  ? config.updateUrl
                  : 'https://play.google.com/store/apps/details?id=${config.packageName}';
              final uri = Uri.tryParse(targetUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'Update Now',
              style: TextStyle(
                color: palette.opTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
