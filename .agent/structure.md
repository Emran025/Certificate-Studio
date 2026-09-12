```tree
lib/
│   main.dart
│
├───config
│   ├───di
│   │       injection.dart
│   │       injection.config.dart
│   │       register_module.dart
│   │
│   ├───env
│   │       app_environment.dart
│   │
│   └───localization
│       │   l10n_config.dart
│       │
│       └───l10n
│               app_ar.arb
│               app_en.arb
│               app_localizations.dart
│
├───core
│   ├───database
│   │       app_database.dart
│   │       database_migrations.dart
│   │       database_tables.dart
│   │
│   ├───entities
│   │       base_entity.dart
│   │       file_reference.dart
│   │       operation_result.dart
│   │       page_info.dart
│   │
│   ├───error
│   │       exceptions.dart
│   │       failures.dart
│   │
│   ├───files
│   │   ├───file_picker
│   │   │       file_picker_service.dart
│   │   │       file_picker_service_impl.dart
│   │   │
│   │   ├───file_system
│   │   │       app_directories.dart
│   │   │       file_system_service.dart
│   │   │       file_system_service_impl.dart
│   │   │
│   │   └───sharing
│   │           file_share_service.dart
│   │           file_share_service_impl.dart
│   │
│   ├───image
│   │       image_processing_service.dart
│   │       image_processing_service_impl.dart
│   │
│   ├───logging
│   │       app_logger.dart
│   │
│   ├───platform
│   │       platform_capabilities.dart
│   │       platform_service.dart
│   │
│   ├───security
│   │   ├───keys
│   │   │       key_manager.dart
│   │   │       key_storage.dart
│   │   │       project_key_manager.dart
│   │   │       institution_key_manager.dart
│   │   │
│   │   ├───hashing
│   │   │       hash_service.dart
│   │   │       hash_service_impl.dart
│   │   │
│   │   ├───signing
│   │   │       digital_signature_service.dart
│   │   │       digital_signature_service_impl.dart
│   │   │
│   │   └───encryption
│   │           encryption_service.dart
│   │           encryption_service_impl.dart
│   │
│   ├───services
│   │       clipboard_service.dart
│   │       clipboard_service_impl.dart
│   │       document_metadata_service.dart
│   │       pdf_service.dart
│   │       qr_service.dart
│   │
│   ├───utils
│   │       app_assets.dart
│   │       app_constants.dart
│   │       app_extensions.dart
│   │       date_utils_helper.dart
│   │       json_utils.dart
│   │       path_utils.dart
│   │       string_utils.dart
│   │
│   └───validators
│           certificate_validator.dart
│           file_validator.dart
│           project_validator.dart
│
├───features
│   │
│   ├───app
│   │   ├───presentation
│   │   │   ├───bloc
│   │   │   │       app_bloc.dart
│   │   │   │       app_event.dart
│   │   │   │       app_state.dart
│   │   │   │
│   │   │   ├───screens
│   │   │   │       splash_screen.dart
│   │   │   │       welcome_screen.dart
│   │   │   │       home_screen.dart
│   │   │   │
│   │   │   └───widgets
│   │   │           app_shell.dart
│   │   │           desktop_navigation.dart
│   │   │           mobile_navigation.dart
│   │   │
│   │   └───domain
│   │           app_startup.dart
│   │
│   ├───institution
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       institution_local_data_source.dart
│   │   │   │       institution_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       institution_model.dart
│   │   │   │       institution_key_model.dart
│   │   │   │       institution_settings_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           institution_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       institution.dart
│   │   │   │       institution_key.dart
│   │   │   │       institution_settings.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       institution_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           initialize_institution.dart
│   │   │           get_institution.dart
│   │   │           update_institution.dart
│   │   │           rotate_institution_key.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       institution_bloc.dart
│   │       │       institution_event.dart
│   │       │       institution_state.dart
│   │       │
│   │       ├───screens
│   │       │       institution_setup_screen.dart
│   │       │       institution_settings_screen.dart
│   │       │
│   │       └───widgets
│   │               institution_form.dart
│   │               institution_logo_picker.dart
│   │               institution_key_section.dart
│   │
│   ├───projects
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       project_local_data_source.dart
│   │   │   │       project_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       project_model.dart
│   │   │   │       project_settings_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           project_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       project.dart
│   │   │   │       project_settings.dart
│   │   │   │       project_key.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       project_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           create_project.dart
│   │   │           delete_project.dart
│   │   │           duplicate_project.dart
│   │   │           get_project.dart
│   │   │           get_projects.dart
│   │   │           update_project.dart
│   │   │           generate_project_key.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       project_bloc.dart
│   │       │       project_event.dart
│   │       │       project_state.dart
│   │       │
│   │       ├───screens
│   │       │       projects_screen.dart
│   │       │       create_project_screen.dart
│   │       │       project_details_screen.dart
│   │       │       project_settings_screen.dart
│   │       │
│   │       └───widgets
│   │               project_card.dart
│   │               project_list.dart
│   │               project_actions.dart
│   │
│   ├───templates
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       template_local_data_source.dart
│   │   │   │       template_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       certificate_template_model.dart
│   │   │   │       template_metadata_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           template_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       certificate_template.dart
│   │   │   │       template_metadata.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       template_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           add_template.dart
│   │   │           delete_template.dart
│   │   │           get_template.dart
│   │   │           get_templates.dart
│   │   │           import_template.dart
│   │   │           save_template.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       template_bloc.dart
│   │       │       template_event.dart
│   │       │       template_state.dart
│   │       │
│   │       ├───screens
│   │       │       templates_screen.dart
│   │       │       template_picker_screen.dart
│   │       │
│   │       └───widgets
│   │               template_card.dart
│   │               template_preview.dart
│   │               template_drop_zone.dart
│   │
│   ├───certificate_designer
│   │   ├───data
│   │   │   ├───models
│   │   │   │       certificate_field_model.dart
│   │   │   │       field_style_model.dart
│   │   │   │       field_position_model.dart
│   │   │   │       designer_state_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           certificate_designer_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       certificate_field.dart
│   │   │   │       field_position.dart
│   │   │   │       field_style.dart
│   │   │   │       field_alignment.dart
│   │   │   │       field_overflow.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       certificate_designer_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           add_certificate_field.dart
│   │   │           update_certificate_field.dart
│   │   │           delete_certificate_field.dart
│   │   │           duplicate_certificate_field.dart
│   │   │           reorder_certificate_fields.dart
│   │   │           save_design.dart
│   │   │           load_design.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       certificate_designer_bloc.dart
│   │       │       certificate_designer_event.dart
│   │       │       certificate_designer_state.dart
│   │       │
│   │       ├───screens
│   │       │       certificate_designer_screen.dart
│   │       │       field_properties_screen.dart
│   │       │
│   │       └───widgets
│   │               certificate_canvas.dart
│   │               certificate_field_box.dart
│   │               field_toolbar.dart
│   │               field_properties_panel.dart
│   │               alignment_toolbar.dart
│   │               ruler_widget.dart
│   │               grid_widget.dart
│   │               zoom_controls.dart
│   │               canvas_background.dart
│   │
│   ├───fonts
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       font_local_data_source.dart
│   │   │   │       font_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       font_model.dart
│   │   │   │       font_metadata_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           font_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       certificate_font.dart
│   │   │   │       font_metadata.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       font_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           add_font.dart
│   │   │           delete_font.dart
│   │   │           get_fonts.dart
│   │   │           validate_font.dart
│   │   │           register_project_font.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       font_bloc.dart
│   │       │       font_event.dart
│   │       │       font_state.dart
│   │       │
│   │       ├───screens
│   │       │       fonts_screen.dart
│   │       │       font_picker_screen.dart
│   │       │
│   │       └───widgets
│   │               font_card.dart
│   │               font_preview.dart
│   │               font_import_dialog.dart
│   │
│   ├───data_import
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       excel_data_source.dart
│   │   │   │       excel_data_source_impl.dart
│   │   │   │       clipboard_data_source.dart
│   │   │   │       clipboard_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       spreadsheet_model.dart
│   │   │   │       spreadsheet_row_model.dart
│   │   │   │       spreadsheet_column_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           data_import_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       imported_table.dart
│   │   │   │       imported_row.dart
│   │   │   │       imported_column.dart
│   │   │   │       import_source.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       data_import_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           import_excel.dart
│   │   │           paste_table.dart
│   │   │           validate_imported_data.dart
│   │   │           save_imported_data.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       data_import_bloc.dart
│   │       │       data_import_event.dart
│   │       │       data_import_state.dart
│   │       │
│   │       ├───screens
│   │       │       data_import_screen.dart
│   │       │       spreadsheet_preview_screen.dart
│   │       │
│   │       └───widgets
│   │               spreadsheet_table.dart
│   │               spreadsheet_toolbar.dart
│   │               excel_drop_zone.dart
│   │               paste_table_dialog.dart
│   │
│   ├───field_mapping
│   │   ├───data
│   │   │   ├───models
│   │   │   │       field_mapping_model.dart
│   │   │   │       mapping_rule_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           field_mapping_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       field_mapping.dart
│   │   │   │       mapping_rule.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       field_mapping_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           create_mapping.dart
│   │   │           update_mapping.dart
│   │   │           validate_mapping.dart
│   │   │           preview_mapping.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       field_mapping_bloc.dart
│   │       │       field_mapping_event.dart
│   │       │       field_mapping_state.dart
│   │       │
│   │       ├───screens
│   │       │       field_mapping_screen.dart
│   │       │
│   │       └───widgets
│   │               mapping_row.dart
│   │               mapping_selector.dart
│   │               mapping_preview.dart
│   │
│   ├───signatures
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       signature_local_data_source.dart
│   │   │   │       signature_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       signature_model.dart
│   │   │   │       stamp_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           signature_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       signature.dart
│   │   │   │       stamp.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       signature_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           add_signature.dart
│   │   │           delete_signature.dart
│   │   │           get_signatures.dart
│   │   │           update_signature.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       signature_bloc.dart
│   │       │       signature_event.dart
│   │       │       signature_state.dart
│   │       │
│   │       ├───screens
│   │       │       signatures_screen.dart
│   │       │
│   │       └───widgets
│   │               signature_card.dart
│   │               signature_picker.dart
│   │               signature_position_editor.dart
│   │
│   ├───certificate_generation
│   │   ├───data
│   │   │   ├───models
│   │   │   │       generation_job_model.dart
│   │   │   │       generation_result_model.dart
│   │   │   │       render_configuration_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           certificate_generation_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       generation_job.dart
│   │   │   │       generation_result.dart
│   │   │   │       render_configuration.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       certificate_generation_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           generate_certificate.dart
│   │   │           generate_all_certificates.dart
│   │   │           regenerate_certificate.dart
│   │   │           cancel_generation.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       certificate_generation_bloc.dart
│   │       │       certificate_generation_event.dart
│   │       │       certificate_generation_state.dart
│   │       │
│   │       ├───screens
│   │       │       generation_screen.dart
│   │       │       generation_progress_screen.dart
│   │       │
│   │       └───widgets
│   │               generation_progress.dart
│   │               generation_summary.dart
│   │               generation_error_list.dart
│   │
│   ├───certificates
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       certificate_local_data_source.dart
│   │   │   │       certificate_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       certificate_model.dart
│   │   │   │       certificate_file_model.dart
│   │   │   │       certificate_metadata_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           certificate_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       certificate.dart
│   │   │   │       certificate_file.dart
│   │   │   │       certificate_metadata.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       certificate_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           get_certificates.dart
│   │   │           get_certificate.dart
│   │   │           delete_certificate.dart
│   │   │           regenerate_certificate.dart
│   │   │           share_certificate.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       certificates_bloc.dart
│   │       │       certificates_event.dart
│   │       │       certificates_state.dart
│   │       │
│   │       ├───screens
│   │       │       certificates_screen.dart
│   │       │       certificate_preview_screen.dart
│   │       │       certificate_details_screen.dart
│   │       │
│   │       └───widgets
│   │               certificate_card.dart
│   │               certificate_preview.dart
│   │               certificate_actions.dart
│   │
│   ├───export
│   │   ├───data
│   │   │   ├───models
│   │   │   │       export_configuration_model.dart
│   │   │   │       export_job_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           export_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       export_configuration.dart
│   │   │   │       export_job.dart
│   │   │   │       filename_pattern.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       export_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           export_certificate.dart
│   │   │           export_certificates.dart
│   │   │           export_as_zip.dart
│   │   │           build_filename.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       export_bloc.dart
│   │       │       export_event.dart
│   │       │       export_state.dart
│   │       │
│   │       ├───screens
│   │       │       export_screen.dart
│   │       │       export_configuration_screen.dart
│   │       │
│   │       └───widgets
│   │               filename_pattern_editor.dart
│   │               export_format_selector.dart
│   │               export_options.dart
│   │
│   ├───project_package
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       project_package_data_source.dart
│   │   │   │       project_package_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       project_manifest_model.dart
│   │   │   │       project_package_model.dart
│   │   │   │       project_package_version_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           project_package_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       project_manifest.dart
│   │   │   │       project_package.dart
│   │   │   │       project_package_version.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       project_package_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           export_project.dart
│   │   │           import_project.dart
│   │   │           validate_project_package.dart
│   │   │           migrate_project_package.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       project_package_bloc.dart
│   │       │       project_package_event.dart
│   │       │       project_package_state.dart
│   │       │
│   │       ├───screens
│   │       │       project_import_screen.dart
│   │       │       project_export_screen.dart
│   │       │
│   │       └───widgets
│   │               package_info_card.dart
│   │               import_validation_result.dart
│   │
│   ├───verification
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       verification_local_data_source.dart
│   │   │   │       verification_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       verification_record_model.dart
│   │   │   │       verification_result_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           verification_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       verification_record.dart
│   │   │   │       verification_result.dart
│   │   │   │       verification_status.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       verification_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           verify_certificate.dart
│   │   │           verify_certificate_file.dart
│   │   │           verify_certificate_qr.dart
│   │   │           verify_certificate_id.dart
│   │   │           validate_certificate_hash.dart
│   │   │           validate_certificate_signature.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       verification_bloc.dart
│   │       │       verification_event.dart
│   │       │       verification_state.dart
│   │       │
│   │       ├───screens
│   │       │       verification_screen.dart
│   │       │       verification_result_screen.dart
│   │       │       qr_scanner_screen.dart
│   │       │
│   │       └───widgets
│   │               verification_status_card.dart
│   │               verification_details.dart
│   │               verification_error.dart
│   │
│   ├───students
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       student_local_data_source.dart
│   │   │   │       student_local_data_source_impl.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       student_model.dart
│   │   │   │       student_data_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           student_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       student.dart
│   │   │   │       student_data.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       student_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           add_student.dart
│   │   │           update_student.dart
│   │   │           delete_student.dart
│   │   │           get_students.dart
│   │   │           get_student.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       students_bloc.dart
│   │       │       students_event.dart
│   │       │       students_state.dart
│   │       │
│   │       ├───screens
│   │       │       students_screen.dart
│   │       │       student_details_screen.dart
│   │       │
│   │       └───widgets
│   │               student_card.dart
│   │               student_data_table.dart
│   │               student_actions.dart
│   │
│   ├───sharing
│   │   ├───data
│   │   │   ├───datasources
│   │   │   │       system_share_data_source.dart
│   │   │   │       whatsapp_share_data_source.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       share_request_model.dart
│   │   │   │       share_result_model.dart
│   │   │   │
│   │   │   └───repositories
│   │   │           sharing_repository_impl.dart
│   │   │
│   │   ├───domain
│   │   │   ├───entities
│   │   │   │       share_request.dart
│   │   │   │       share_result.dart
│   │   │   │       share_target.dart
│   │   │   │
│   │   │   ├───repositories
│   │   │   │       sharing_repository.dart
│   │   │   │
│   │   │   └───usecases
│   │   │           share_certificate.dart
│   │   │           share_to_whatsapp.dart
│   │   │           share_to_system.dart
│   │   │           normalize_phone_number.dart
│   │   │
│   │   └───presentation
│   │       ├───bloc
│   │       │       sharing_bloc.dart
│   │       │       sharing_event.dart
│   │       │       sharing_state.dart
│   │       │
│   │       └───widgets
│   │               share_certificate_dialog.dart
│   │               share_target_selector.dart
│   │
│   └───settings
│       ├───data
│       │   ├───datasources
│       │   │       settings_local_data_source.dart
│       │   │       settings_local_data_source_impl.dart
│       │   │
│       │   ├───models
│       │   │       app_settings_model.dart
│       │   │       export_settings_model.dart
│       │   │       verification_settings_model.dart
│       │   │
│       │   └───repositories
│       │           settings_repository_impl.dart
│       │
│       ├───domain
│       │   ├───entities
│       │   │       app_settings.dart
│       │   │       export_settings.dart
│       │   │       verification_settings.dart
│       │   │
│       │   ├───repositories
│       │   │       settings_repository.dart
│       │   │
│       │   └───usecases
│       │           get_settings.dart
│       │           update_settings.dart
│       │           reset_settings.dart
│       │
│       └───presentation
│           ├───bloc
│           │       settings_bloc.dart
│           │       settings_event.dart
│           │       settings_state.dart
│           │
│           ├───screens
│           │       settings_screen.dart
│           │       appearance_settings_screen.dart
│           │       security_settings_screen.dart
│           │       export_settings_screen.dart
│           │
│           └───widgets
│                   settings_section.dart
│                   settings_tile.dart
│
├───routes
│       app_router.dart
│       route_names.dart
│
└───shared
    ├───extensions
    │       context_extensions.dart
    │       date_extensions.dart
    │       string_extensions.dart
    │
    ├───themes
    │       app_theme.dart
    │       app_colors.dart
    │       app_text_styles.dart
    │
    └───widgets
            app_button.dart
            app_card.dart
            app_dialog.dart
            app_empty_state.dart
            app_error_view.dart
            app_loading.dart
            app_text_field.dart
            confirmation_dialog.dart
            file_drop_zone.dart
            responsive_layout.dart
            search_field.dart
```

```
certificate-studio/
│
├───lib/
│
├───packages/
│   ├───certificate_core/
│   ├───certificate_crypto/
│   ├───certificate_renderer/
│   ├───certificate_excel/
│   ├───certificate_verifier/
│   └───certificate_project/
│
├───python/
│   └───certificate_crypto/
│       ├───src/
│       ├───tests/
│       ├───pyproject.toml
│       └───README.md
│
├───assets/
│   ├───fonts/
│   ├───icons/
│   ├───images/
│   └───templates/
│
├───docs/
│   ├───architecture/
│   ├───security/
│   ├───project-package/
│   ├───certificate-format/
│   └───srs/
│
├───test/
├───integration_test/
│
├───android/
├───ios/
├───linux/
├───macos/
├───web/
└───windows/
```