import 'package:flutter/material.dart';
import 'package:educheck_app/features/teacher_dashboard/domain/entities/class_entity.dart';
import 'package:educheck_app/core/colors.dart';

class ClassCard extends StatelessWidget {
  final ClassEntity classDetails;
  final VoidCallback onTap;
  final Function(String) onActionSelected;
  final bool showToDo;

  const ClassCard({
    super.key,
    required this.classDetails,
    required this.onTap,
    required this.onActionSelected,
    this.showToDo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: classDetails.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        classDetails.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildThreeDotMenu(),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Grade: ${classDetails.category} | ${classDetails.studentsCount} Students',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (showToDo && classDetails.toDoAssignment != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TO DO: ${classDetails.toDoAssignment}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreeDotMenu() {
    return PopupMenuButton<String>(
      onSelected: onActionSelected,
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'archive', child: Text('Archive Class')),
        PopupMenuItem<String>(value: 'delete', child: Text('Delete Class', style: TextStyle(color: Colors.red))),
      ],
      icon: const Icon(Icons.more_vert, color: Colors.white),
    );
  }
}