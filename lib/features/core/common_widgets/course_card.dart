// lib/features/core/common_widgets/course_card.dart

import 'package:flutter/material.dart';

// This is a generic card used in both Teacher and Student views.
class CourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final String statusText;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final bool showMoreOptions;

  const CourseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.statusText,
    required this.gradientColors,
    this.onTap,
    this.showMoreOptions = false, // Teacher view uses this
  });

  @override
  Widget build(BuildContext context) {
    final isPending = statusText.toLowerCase().contains('pending');
    final statusColor = isPending ? Colors.red.shade700 : Colors.green.shade700;
    final statusBgColor = isPending ? Colors.red.shade100 : Colors.green.shade100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                ],
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Options Menu (Teacher View)
                if (showMoreOptions) 
                  const Icon(Icons.more_vert, color: Colors.black54),
                
                // Status Chip
                if (statusText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}