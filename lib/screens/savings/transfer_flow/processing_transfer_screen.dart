import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class ProcessingTransferScreen extends StatefulWidget {
  final TransferData? initialData;

  const ProcessingTransferScreen({
    super.key,
    this.initialData,
  });

  @override
  State<ProcessingTransferScreen> createState() =>
      _ProcessingTransferScreenState();
}

class _ProcessingTransferScreenState extends State<ProcessingTransferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late TransferData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? TransferData();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.push(
          '/transfer/success',
          extra: _data,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated spinner
            SizedBox(
              width: 80,
              height: 80,
              child: RotationTransition(
                turns: _controller,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status text
            Text(
              'Processing Transfer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your transfer...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
