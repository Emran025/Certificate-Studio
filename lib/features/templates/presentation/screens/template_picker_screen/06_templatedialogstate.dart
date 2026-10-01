part of '../template_picker_screen.dart';

class _TemplateDialogState extends State<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _path = TextEditingController();
  String? _selectedFileName;
  final _width = TextEditingController(text: '1920');
  final _height = TextEditingController(text: '1080');
  final _dpi = TextEditingController(text: '300');
  String _format = 'png';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      _path.text = initial.filePath;
      _width.text = initial.width.toString();
      _height.text = initial.height.toString();
      _dpi.text = initial.dpi.toString();
      _format = initial.format;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    _width.dispose();
    _height.dispose();
    _dpi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: Text(
      context.l10n.text(
        widget.initial == null ? 'Add template' : 'Edit template',
      ),
    ),
    icon: widget.initial == null
        ? Icons.add_photo_alternate_outlined
        : Icons.edit_outlined,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.text('Cancel')),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _TemplateDraft(
              name: _name.text.trim(),
              path: _path.text.trim(),
              width: int.parse(_width.text),
              height: int.parse(_height.text),
              dpi: double.parse(_dpi.text),
              format: _format,
            ),
          );
        },
        child: Text(context.l10n.text('Save')),
      ),
    ],
    child: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field(context, _name, context.l10n.text('Template name')),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _path,
                      context.l10n.text('Background image'),
                      readOnly: true,
                      validator: (value) => validateTemplatePath(value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: _chooseBackground,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(context.l10n.text('Choose image')),
                    ),
                  ),
                ],
              ),
              if (_selectedFileName != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedFileName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _width,
                      context.l10n.text('Width'),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      context,
                      _height,
                      context.l10n.text('Height'),
                      number: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _dpi,
                      context.l10n.text('DPI'),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _format,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('Format'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'png',
                          child: Text(context.l10n.text('PNG')),
                        ),
                        DropdownMenuItem(
                          value: 'jpg',
                          child: Text(context.l10n.text('JPG')),
                        ),
                        DropdownMenuItem(
                          value: 'webp',
                          child: Text(context.l10n.text('WEBP')),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _format = value ?? 'png'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _chooseBackground() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _path.text = path;
      _selectedFileName = file!.name;
      final extension = file.extension?.toLowerCase();
      if (extension == 'jpg' || extension == 'jpeg') {
        _format = 'jpg';
      } else if (extension == 'webp') {
        _format = 'webp';
      } else {
        _format = 'png';
      }
    });
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool number = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? context.l10n.text('Required')
              : null,
    ),
  );
}
