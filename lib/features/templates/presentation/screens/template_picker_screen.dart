import '../../../../config/localization/app_localizations.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/template_repository_impl.dart';
import '../../domain/entities/template_asset.dart';
import '../bloc/template_picker_bloc.dart';
import '../template_file_support.dart';

part 'template_picker_screen/01_templatepickerscreen.dart';
part 'template_picker_screen/02_templatecard.dart';
part 'template_picker_screen/03_missingpreview.dart';
part 'template_picker_screen/04_templatedraft.dart';
part 'template_picker_screen/05_templatedialog.dart';
part 'template_picker_screen/06_templatedialogstate.dart';
