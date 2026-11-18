import 'package:flutter/material.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({
    super.key,
    this.userName = 'User',
    this.onSpanish,
    this.onEnglish,
  });

  final String userName;

  /// Called after the sheet closes when "Switch To Spanish" is tapped.
  final VoidCallback? onSpanish;

  /// Called after the sheet closes when "Continue in English" is tapped.
  final VoidCallback? onEnglish;

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
      BuildContext context, {
        String userName = 'User',
        VoidCallback? onSpanish,
        VoidCallback? onEnglish,
      }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false, // user must pick a language
      enableDrag: false,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LanguageSheet(
        userName: userName,
        onSpanish: onSpanish,
        onEnglish: onEnglish,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title: bold green
          Text(
            'Hello, $userName!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please choose which language you prefer.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Spanish
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSpanish?.call();
                    },
                    icon: const Text('🇪🇸', style: TextStyle(fontSize: 20)),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Switch To Spanish'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // English
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEnglish?.call();
                    },
                    icon: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Continue in English'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}