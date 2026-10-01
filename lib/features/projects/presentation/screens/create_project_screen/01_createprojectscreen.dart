part of '../create_project_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({
    super.key,
    required this.institutionId,
    required this.createProject,
  });

  final String institutionId;
  final CreateProject createProject;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}
