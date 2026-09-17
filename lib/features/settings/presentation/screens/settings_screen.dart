import 'package:flutter/material.dart';

import '../../../../config/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/workspace_transfer_service.dart';
import '../../domain/entities/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.database,
    required this.institutionId,
    required this.settings,
    required this.keyStorage,
    this.onSettingsChanged,
  });

  final AppDatabase database;
  final String institutionId;
  final AppSettings settings;
  final KeyStorage keyStorage;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.settings;
  late final SettingsRepositoryImpl _settingsRepository;
  late final WorkspaceTransferService _transfer;
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
        initialColor: _settings.accentColor,
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
                                color: _settings.accentColor,
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

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialColor,
    required this.title,
    required this.closeLabel,
    required this.applyLabel,
  });

  final Color initialColor;
  final String title;
  final String closeLabel;
  final String applyLabel;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _color = HSVColor.fromColor(widget.initialColor);

  void _updateSaturationAndValue(Offset position, Size size) {
    setState(() {
      _color = _color
          .withSaturation((position.dx / size.width).clamp(0.0, 1.0))
          .withValue((1 - position.dy / size.height).clamp(0.0, 1.0));
    });
  }

  void _updateHue(Offset position, Size size) {
    setState(() {
      _color = _color.withHue(
        (position.dx / size.width * 360).clamp(0.0, 360.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _color.toColor();
    return AppDialog(
      title: Text(widget.title),
      icon: Icons.colorize,
      width: 420,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.closeLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: Text(widget.applyLabel),
        ),
      ],
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 190);
                return GestureDetector(
                  onPanDown: (details) =>
                      _updateSaturationAndValue(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _updateSaturationAndValue(details.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: _SaturationValuePainter(hue: _color.hue),
                    foregroundPainter: _SelectionPainter(
                      x: _color.saturation * size.width,
                      y: (1 - _color.value) * size.height,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 24);
                return GestureDetector(
                  onPanDown: (details) =>
                      _updateHue(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _updateHue(details.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: const _HuePainter(),
                    foregroundPainter: _HueSelectionPainter(
                      x: _color.hue / 360 * size.width,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}

class _HuePainter extends CustomPainter {
  const _HuePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => false;
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({required this.x, required this.y});

  final double x;
  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(x, y),
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x, y),
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate.x != x || oldDelegate.y != y;
}

class _HueSelectionPainter extends CustomPainter {
  const _HueSelectionPainter({required this.x});

  final double x;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(x - 2, 0, 4, size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 3, -1, 6, size.height + 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_HueSelectionPainter oldDelegate) => oldDelegate.x != x;
}
