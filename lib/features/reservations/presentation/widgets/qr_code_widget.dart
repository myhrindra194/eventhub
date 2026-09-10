import 'package:flutter/material.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QrCodeWidget({super.key, required this.data, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.qr_code_2_rounded,
          size: size * 0.8,
          color: Colors.black,
        ),
      ),
    );
  }
}
