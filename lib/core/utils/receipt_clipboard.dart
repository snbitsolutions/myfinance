import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> copyReceiptToClipboard(
  BuildContext context, {
  required String text,
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receipt copied')));
  } on PlatformException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not copy the receipt. Try again.')),
    );
  }
}
