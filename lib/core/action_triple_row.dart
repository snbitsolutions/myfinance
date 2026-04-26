import 'package:flutter/material.dart';

/// A single action item for [ActionTripleRow].
class ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.onLongPress,
  });
}

/// A consistent 3-button quick-action bar (Deposit / Withdraw / Transfer)
/// used uniformly across the app wherever these three actions appear.
/// An optional [extra] item renders as a full-width row beneath the main three.
class ActionTripleRow extends StatelessWidget {
  final ActionItem deposit;
  final ActionItem withdraw;
  final ActionItem transfer;
  final ActionItem? extra;

  const ActionTripleRow({
    super.key,
    required this.deposit,
    required this.withdraw,
    required this.transfer,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionTile(item: deposit)),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(item: withdraw)),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(item: transfer)),
          ],
        ),
        if (extra != null) ...[
          const SizedBox(height: 10),
          _ActionPill(item: extra!),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ActionItem item;

  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = item.onTap == null;

    return Opacity(
      opacity: disabled ? 0.38 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          onLongPress: item.onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
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

/// Full-width horizontal pill tile — used for the optional [extra] action.
class _ActionPill extends StatelessWidget {
  final ActionItem item;
  const _ActionPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = item.onTap == null;

    return Opacity(
      opacity: disabled ? 0.38 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          onLongPress: item.onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
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
