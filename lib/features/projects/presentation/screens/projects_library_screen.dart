import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../core/security/keys/project_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/create_project.dart';
import '../../domain/usecases/delete_project.dart';
import '../bloc/projects_library_bloc.dart';
import '../../../certificates/presentation/screens/certificate_generation_screen.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';
import '../../../settings/data/services/workspace_transfer_service.dart';
import '../../data/datasources/project_data_source.dart';

part 'projects_library_screen/01_projectslibraryscreen.dart';
part 'projects_library_screen/02_projectslibraryscreenstate.dart';
part 'projects_library_screen/03_projecttile.dart';
