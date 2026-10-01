part of '../settings_screen.dart';

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.settings;
  late final SettingsRepositoryImpl _settingsRepository;
  late final WorkspaceTransferServiceContract _transfer;
  String? _message;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepositoryImpl(widget.database);
    _transfer = WorkspaceTransferService(
      widget.database,
      keyStorage: widget.keyStorage,
    );
  }

  Future<void> _save(AppSettings settings) async {
    await _settingsRepository.saveAppSettings(settings);
    if (!mounted) return;
    setState(() => _settings = settings);
    widget.onSettingsChanged?.call(settings);
  }

  Future<void> _run(Future<String?> Function() action) async {
    try {
      final result = await action();
      if (!mounted) return;
      setState(
        () => _message = result == null
            ? 'The operation was cancelled.'
            : 'Operation completed successfully.',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Operation failed: $error');
    }
  }

  Future<void> _openColorPicker(String Function(String, String) label) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: Color(_settings.accentColorValue),
        title: label('اختيار اللون الرئيسي', 'Choose brand color'),
        closeLabel: label('إلغاء', 'Cancel'),
        applyLabel: label('تطبيق', 'Apply'),
      ),
    );
    if (color != null) {
      await _save(_settings.copyWith(accentColorValue: color.toARGB32()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageTable(
        header: AppPageHeader(
          title: context.l10n.text('Organization settings'),
          subtitle: context.l10n.text('Control center'),
          icon: Icons.tune,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: context.l10n.text('Appearance & language'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _settings.languageCode,
                          decoration: InputDecoration(
                            labelText: context.l10n.text(
                              'Application language',
                            ),
                            prefixIcon: const Icon(Icons.translate),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text(context.l10n.text('Arabic')),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(context.l10n.text('English')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _save(_settings.copyWith(languageCode: value));
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<AppThemeMode>(
                          initialValue: _settings.themeMode,
                          decoration: InputDecoration(
                            labelText: context.l10n.text('Color mode'),
                            prefixIcon: const Icon(Icons.contrast),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: AppThemeMode.system,
                              child: Text(context.l10n.text('System')),
                            ),
                            DropdownMenuItem(
                              value: AppThemeMode.light,
                              child: Text(context.l10n.text('Light')),
                            ),
                            DropdownMenuItem(
                              value: AppThemeMode.dark,
                              child: Text(context.l10n.text('Dark')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _save(_settings.copyWith(themeMode: value));
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            context.l10n.text('Brand color'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: context.l10n.text('Open color picker'),
                              onPressed: () => _openColorPicker(
                                (ar, en) => context.l10n.text(en),
                              ),
                              icon: Icon(
                                Icons.colorize,
                                color: Color(_settings.accentColorValue),
                                size: 30,
                              ),
                            ),
                            for (final color in [
                              const Color(0xFF5B4B8A),
                              const Color(0xFF2E7D5B),
                              const Color(0xFFB45F06),
                              const Color(0xFF333333),
                            ])
                              IconButton(
                                tooltip: context.l10n.text('Primary color'),
                                onPressed: () => _save(
                                  _settings.copyWith(
                                    accentColorValue: color.toARGB32(),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.circle,
                                  color: color,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => _openColorPicker(
                              (ar, en) => context.l10n.text(en),
                            ),
                            icon: const Icon(Icons.palette_outlined),
                            label: Text(
                              context.l10n.text('Choose custom color'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(
                    title: context.l10n.text('Electronic signature'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _run(
                            () => _transfer.exportProfile(
                              widget.institutionId,
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            context.l10n.text('Export institution profile'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _run(() async {
                            final imported = await _transfer.importProfile();
                            return imported ? '1' : null;
                          }),
                          icon: const Icon(Icons.download),
                          label: Text(
                            context.l10n.text('Import institution profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_message!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
