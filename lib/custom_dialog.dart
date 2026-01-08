import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  // Static helper to show the dialog easily
  static void show(BuildContext context, {
    required String title, 
    required String message, 
    bool isSuccess = true
  }) {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: title,
        message: message,
        icon: isSuccess ? Icons.check_circle : Icons.error_outline,
        color: isSuccess ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- 1. The White Card ---
          Container(
            margin: const EdgeInsets.only(top: 40), // Push down to make room for icon
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20), // Padding for content
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Hug content
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900], // Brand Color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Okay"),
                  ),
                )
              ],
            ),
          ),

          // --- 2. The Floating Icon ---
          Positioned(
            top: 0,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white, // White rim
              child: CircleAvatar(
                radius: 35,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 40, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}