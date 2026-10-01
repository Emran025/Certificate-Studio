part of '../project_details_screen.dart';

class _ProjectActionData {
  const _ProjectActionData({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;
}
