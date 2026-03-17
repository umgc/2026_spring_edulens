import 'package:flutter/material.dart';

class NavigationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;
  final double? focusOrder;
  final bool autofocus;

  const NavigationCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.focusOrder,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: Colors.grey.shade400,
        width: 1.5,
      ),
    );

    final child = Semantics(
      button: true,
      enabled: onPressed != null,
      label: title,
      child: Card(
        color: Colors.white,
        shape: cardShape,
        elevation: 0,
        child: InkWell(
          autofocus: autofocus,
          borderRadius: BorderRadius.circular(12),
          canRequestFocus: onPressed != null,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (focusOrder == null) {
      return child;
    }

    return FocusTraversalOrder(
      order: NumericFocusOrder(focusOrder!),
      child: child,
    );
  }
}
