import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExistingMemberEnrollmentScreen extends StatefulWidget {
  const ExistingMemberEnrollmentScreen({
    super.key,
    this.memberType = 'existing',
  });

  final String memberType;

  @override
  State<ExistingMemberEnrollmentScreen> createState() =>
      _ExistingMemberEnrollmentScreenState();
}

class _ExistingMemberEnrollmentScreenState
    extends State<ExistingMemberEnrollmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final destination = widget.memberType == 'new' ? '/signup' : '/login';
      context.go(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.memberType == 'new'
                  ? 'Opening registration...'
                  : 'Opening sign in...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
