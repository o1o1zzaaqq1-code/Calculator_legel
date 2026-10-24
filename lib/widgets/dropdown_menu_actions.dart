import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';
import '../models/theme_palette.dart';
import '../services/history_service.dart';
import '../services/supabase_service.dart';

class DropdownMenuActions {
  /// Map string icon name or emoji from Supabase to Flutter IconData
  static IconData getIconData(String iconName) {
    switch (iconName.trim().toLowerCase()) {
      case 'shield':
      case 'privacy':
      case 'policy':
      case '🛡️':
      case '🛡':
        return Icons.shield_outlined;
      case 'share':
      case '📤':
        return Icons.share_rounded;
      case 'star':
      case 'rate':
      case '⭐':
        return Icons.star_rounded;
      case 'delete':
      case 'clear':
      case 'clear_history':
      case '🗑️':
      case '🗑':
        return Icons.delete_sweep_rounded;
      case 'palette':
      case 'theme':
      case '🎨':
        return Icons.palette_outlined;
      case 'feedback':
      case 'support':
      case '💬':
        return Icons.feedback_outlined;
      case 'telegram':
      case 'send':
        return Icons.send_rounded;
      case 'link':
      case 'web':
        return Icons.open_in_new_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Render button icon supporting both direct emojis (🛡️, 📤, ⭐...) and Material icons
  static Widget buildButtonIcon(AppButtonConfig button, PremiumPalette palette) {
    final iconStr = button.icon.trim();
    final isEmoji = iconStr.runes.any((rune) =>
        (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x1F600 && rune <= 0x1F64F) ||
        (rune >= 0x1F680 && rune <= 0x1F6FF));

    if (isEmoji) {
      return Text(
        iconStr,
        style: const TextStyle(fontSize: 18),
      );
    }

    return Icon(
      getIconData(iconStr),
      color: palette.accentColor,
      size: 20,
    );
  }

  /// Handle dynamic button click from Supabase configuration
  static void handleButtonAction({
    required BuildContext context,
    required AppButtonConfig button,
    required PremiumPalette palette,
    VoidCallback? onHistoryCleared,
    Function(PremiumPalette)? onThemeSelected,
  }) {
    switch (button.actionType.toLowerCase()) {
      case 'policy':
        showPrivacyPolicy(context, palette);
        break;
      case 'share':
        shareApp(context);
        break;
      case 'rate':
        showRateUs(context, palette);
        break;
      case 'clear_history':
        showClearHistory(
          context,
          palette,
          onHistoryCleared ?? () {},
        );
        break;
      case 'theme':
        if (onThemeSelected != null) {
          showThemeSelector(
            context: context,
            currentPalette: palette,
            onThemeSelected: onThemeSelected,
          );
        }
        break;
      case 'feedback':
        showSendFeedback(context, palette);
        break;
      case 'url':
      default:
        if (button.actionUrl.isNotEmpty) {
          openExternalUrl(button.actionUrl);
        }
        break;
    }
  }

  /// Launch external URL safely
  static Future<void> openExternalUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[DropdownMenuActions] Failed to open URL $urlString: $e');
    }
  }

  /// 1. Show Privacy Policy Dialog (Borderless & Solid Colors)
  static void showPrivacyPolicy(BuildContext context, PremiumPalette palette) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.menuBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none, // Strictly NO border
        ),
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: palette.accentColor),
            const SizedBox(width: 10),
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: palette.numTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your privacy is strictly respected and protected.',
                style: TextStyle(
                  color: palette.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _policySection(
                'Data Collection',
                'This calculator operates entirely on your local device. We do not collect, store, or transmit your calculation history or inputs to any external server.',
                palette,
              ),
              const SizedBox(height: 10),
              _policySection(
                'Advertisements',
                'This app uses official Google AdMob advertising services to serve banner and app open ads. Google AdMob may collect anonymous device identifiers in compliance with Google Play Services policies.',
                palette,
              ),
              const SizedBox(height: 10),
              _policySection(
                'Permissions',
                'Only standard Internet permission is requested for fetching non-intrusive advertisements. No storage, location, contacts, or camera access is required.',
                palette,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: palette.opButtonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'I Understand',
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

  static Widget _policySection(
      String title, String body, PremiumPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.numTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            color: palette.secondaryTextColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 2. Share App
  static void shareApp(BuildContext context) {
    HapticFeedback.lightImpact();
    final remoteShare = SupabaseService.instance.getRemoteConfig('share_text');
    final shareText = remoteShare.isNotEmpty
        ? remoteShare
        : 'Check out this Ultra-Premium Calculator! Clean, borderless luxury design with blazing-fast calculations: https://play.google.com/store/apps/details?id=com.dimension.calculator';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Calculator App',
      ),
    );
  }

  /// 3. Rate Us Interactive Dialog (5 Stars)
  static void showRateUs(BuildContext context, PremiumPalette palette) {
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: palette.menuBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 12),
              Text(
                'Rate Calculator',
                style: TextStyle(
                  color: palette.numTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your rating helps us improve your daily calculation experience!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starIndex <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: palette.accentColor,
                      size: 36,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 5
                    ? 'Excellent! Thank you!'
                    : selectedRating >= 4
                        ? 'Great!'
                        : 'We will keep improving!',
                style: TextStyle(
                  color: palette.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                SupabaseService.instance.sendRating(selectedRating);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thank you for giving $selectedRating stars!',
                      style: TextStyle(color: palette.backgroundColor),
                    ),
                    backgroundColor: palette.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Text(
                'Submit Rating',
                style: TextStyle(
                  color: palette.opTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Clear History Dialog
  static void showClearHistory(
    BuildContext context,
    PremiumPalette palette,
    VoidCallback onHistoryCleared,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.menuBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
        title: Text(
          'Clear All History?',
          style: TextStyle(
            color: palette.numTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently remove all saved calculation history.',
          style: TextStyle(color: palette.secondaryTextColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
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
            ),
            onPressed: () async {
              await HistoryService.instance.clearHistory();
              onHistoryCleared();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All calculation history cleared',
                      style: TextStyle(color: palette.backgroundColor),
                    ),
                    backgroundColor: palette.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Clear Now',
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

  /// 5. Theme Selector Modal (Borderless, Solid Palettes)
  static void showThemeSelector({
    required BuildContext context,
    required PremiumPalette currentPalette,
    required Function(PremiumPalette newPalette) onThemeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: currentPalette.menuBackgroundColor, // Solid, NO BORDER
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: currentPalette.secondaryTextColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Theme Palette',
              style: TextStyle(
                color: currentPalette.numTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pure solid luxury colors • Zero borders',
              style: TextStyle(
                color: currentPalette.secondaryTextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ...PremiumPalette.allThemes.map((theme) {
              final isSelected = theme.type == currentPalette.type;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.accentColor.withValues(alpha: 0.15)
                      : theme.displayCardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide.none,
                  ),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    theme.name,
                    style: TextStyle(
                      color: currentPalette.numTextColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: theme.accentColor)
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HistoryService.instance
                        .saveThemeIndex(theme.type.index);
                    onThemeSelected(theme);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 6. Send Feedback Dialog
  static void showSendFeedback(BuildContext context, PremiumPalette palette) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.menuBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
        title: Row(
          children: [
            Icon(Icons.feedback_outlined, color: palette.accentColor),
            const SizedBox(width: 10),
            Text(
              'Send Feedback',
              style: TextStyle(
                color: palette.numTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a suggestion or found a bug? Let us know!',
              style: TextStyle(
                color: palette.secondaryTextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: palette.displayCardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: textController,
                maxLines: 4,
                style: TextStyle(color: palette.numTextColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type your feedback here...',
                  hintStyle: TextStyle(
                    color: palette.secondaryTextColor.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none, // Strictly NO border
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              final feedbackText = textController.text.trim();
              if (feedbackText.isEmpty) return;

              Navigator.pop(ctx);

              // Submit to Supabase Cloud Database
              await SupabaseService.instance.sendFeedback(feedbackText: feedbackText);

              // Launch email client fallback if needed
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'support@dimension.app',
                query:
                    'subject=Calculator App Feedback&body=${Uri.encodeComponent(feedbackText)}',
              );

              try {
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              } catch (_) {}

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thank you! Your feedback has been sent successfully.',
                      style: TextStyle(color: palette.backgroundColor),
                    ),
                    backgroundColor: palette.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Send',
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
