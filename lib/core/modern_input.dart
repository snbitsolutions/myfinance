import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_ext.dart';
import 'layout/responsive.dart';

class ModernInput extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? prefixText;
  final IconData? prefixIcon;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final String? errorText;
  final String? helperText;
  final bool enableInteractiveSelection;

  const ModernInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.prefixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.errorText,
    this.helperText,
    this.enableInteractiveSelection = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpanded = Responsive.isExpanded(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isExpanded
              ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enableInteractiveSelection: enableInteractiveSelection,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.4),
            ),
            filled: true,
            fillColor: errorText != null
                ? theme.colorScheme.error.withOpacitySafe(0.05)
                : theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withOpacitySafe(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withOpacitySafe(0.2),
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        if (errorText != null || helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText ?? helperText!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withOpacitySafe(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
