import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/localization/app_localizations.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/certificate_verification_service.dart';
import '../bloc/verification_bloc.dart';

part 'verification_screen/01_verificationscreen.dart';
part 'verification_screen/02_verificationscreenstate.dart';
part 'verification_screen/03_resultcard.dart';
part 'verification_screen/04_info.dart';
