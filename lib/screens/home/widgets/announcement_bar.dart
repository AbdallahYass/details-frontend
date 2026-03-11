import 'package:flutter/material.dart';

class AnnouncementBar extends StatelessWidget {
  const AnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF452512),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "التوصيل متاح لجميع مناطق الضفة والقدس والداخل 🚛",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
