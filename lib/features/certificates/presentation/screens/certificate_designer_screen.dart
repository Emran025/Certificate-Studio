import '../../../../config/localization/app_localizations.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../data/services/template_bytes.dart';
import '../../../templates/presentation/template_file_support.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/utils/field_identifier.dart';
import '../../../../shared/widgets/design_system.dart';

part '../widgets/elements_panel.dart';
part '../widgets/designer_canvas.dart';
part '../widgets/properties_panel.dart';
part '../widgets/column_picker.dart';

part 'certificate_designer_screen/01_certificatedesignerscreen.dart';
part 'certificate_designer_screen/02_certificatedesignerscreenstate.dart';
part 'certificate_designer_screen/03_designerfield.dart';
