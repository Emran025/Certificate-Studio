import '../../../../config/localization/app_localizations.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../verification/domain/certificate_verification_service.dart';
import '../../data/services/certificate_export_service.dart';
import '../../data/repositories/certificate_repository_impl.dart';
import '../../domain/entities/certificate_record.dart';
import '../../domain/usecases/get_certificates.dart';
import '../bloc/certificate_library_bloc.dart';
import '../../data/datasources/certificate_data_source.dart';

part 'certificate_library_screen/01_certificatelibraryscreen.dart';
part 'certificate_library_screen/02_certificatelibraryscreenstate.dart';
part 'certificate_library_screen/03_certificatecard.dart';
part 'certificate_library_screen/04_certificatepreviewscreen.dart';
part 'certificate_library_screen/05_certificateexportoptions.dart';
part 'certificate_library_screen/06_certificatedetails.dart';
part 'certificate_library_screen/07_detail.dart';
part 'certificate_library_screen/08_artifactimage.dart';
part 'certificate_library_screen/09_librarycertificate.dart';
