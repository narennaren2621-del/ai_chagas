import 'package:flutter/material.dart';

class SegmentedAuth extends StatelessWidget {
  const SegmentedAuth({
    required this.isLogin,
    required this.onChanged,
    super.key,
  });

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _choice('Sign in', true),
            _choice('Sign up', false),
          ],
        ),
      );

  Widget _choice(String label, bool login) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => onChanged(login),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isLogin == login ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: isLogin == login
                  ? const [BoxShadow(color: Color(0x18001F1D), blurRadius: 5)]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isLogin == login
                    ? const Color(0xFF006B67)
                    : const Color(0xFF68807E),
              ),
            ),
          ),
        ),
      );
}
