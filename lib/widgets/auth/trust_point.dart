import 'package:flutter/material.dart';

class TrustPoint extends StatelessWidget {
  const TrustPoint({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFDDF0ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF006B67), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3F5D59),
            ),
          ),
        ],
      );
}
