import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/font_repository_impl.dart';
import '../../domain/entities/font_asset.dart';
import '../bloc/fonts_library_bloc.dart';
import '../../data/datasources/font_data_source.dart';

part 'fonts_library_screen/01_fontslibraryscreen.dart';
part 'fonts_library_screen/02_fontslibraryscreenstate.dart';
part 'fonts_library_screen/03_fontcard.dart';
part 'fonts_library_screen/04_fontprevieweditor.dart';
