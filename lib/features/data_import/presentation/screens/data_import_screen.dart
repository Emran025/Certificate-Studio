import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/data_import_repository_impl.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';
import '../bloc/data_import_bloc.dart';
import '../widgets/data_preview.dart';

part 'data_import_screen/01_dataimportscreen.dart';
part 'data_import_screen/02_dataimportscreenstate.dart';
part 'data_import_screen/03_importcard.dart';
part 'data_import_screen/04_emptyimportstate.dart';
