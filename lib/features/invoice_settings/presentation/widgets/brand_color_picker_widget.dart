import 'package:flutter/material.dart';

class BrandColorPickerWidget extends StatefulWidget {
  final String currentColorHex;
  final ValueChanged<String> onColorChanged;

  const BrandColorPickerWidget({
    super.key,
    required this.currentColorHex,
    required this.onColorChanged,
  });

  @override
  State<BrandColorPickerWidget> createState() => _BrandColorPickerWidgetState();
}

class _BrandColorPickerWidgetState extends State<BrandColorPickerWidget> {
  late TextEditingController _hexController;
  String? _hexErrorText;

  final List<String> _suggestedColors = const [
    '#2563EB', // Royal Blue
    '#7C3AED', // Violet
    '#059669', // Emerald
    '#DC2626', // Crimson
    '#D97706', // Amber
    '#0284C7', // Sky Blue
    '#DB2777', // Pink
    '#4F46E5', // Indigo
    '#10B981', // Teal
    '#6366F1', // Iris
    '#EC4899', // Rose
    '#14B8A6', // Mint
    '#F59E0B', // Gold
    '#4B5563', // Slate
  ];

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _formatHex(widget.currentColorHex));
  }

  @override
  void didUpdateWidget(covariant BrandColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColorHex != widget.currentColorHex) {
      final formatted = _formatHex(widget.currentColorHex);
      if (_hexController.text.toUpperCase() != formatted.toUpperCase()) {
        _hexController.text = formatted;
        _hexErrorText = null;
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _formatHex(String hex) {
    String clean = hex.replaceAll('#', '').toUpperCase();
    if (clean.length == 6) {
      return '#$clean';
    }
    return hex.startsWith('#') ? hex.toUpperCase() : '#${hex.toUpperCase()}';
  }

  Color _parseColor(String hex) {
    try {
      String clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF2563EB);
  }

  bool _isValidHex(String hex) {
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return false;
    final hexRegex = RegExp(r'^[0-9a-fA-F]{6}$');
    return hexRegex.hasMatch(clean);
  }

  void _onHexSubmitted(String input) {
    String clean = input.replaceAll('#', '').trim();
    if (_isValidHex(clean)) {
      setState(() {
        _hexErrorText = null;
      });
      final fullHex = '#${clean.toUpperCase()}';
      widget.onColorChanged(fullHex);
    } else {
      setState(() {
        _hexErrorText = 'Invalid HEX code (e.g. #2563EB)';
      });
    }
  }

  void _selectColor(String hex) {
    final formatted = _formatHex(hex);
    setState(() {
      _hexController.text = formatted;
      _hexErrorText = null;
    });
    widget.onColorChanged(formatted);
  }

  void _openCustomColorDialog(BuildContext context) {
    Color currentColor = _parseColor(widget.currentColorHex);
    double red = (currentColor.r * 255.0).roundToDouble();
    double green = (currentColor.g * 255.0).roundToDouble();
    double blue = (currentColor.b * 255.0).roundToDouble();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedColor = Color.fromRGBO(
              red.round(),
              green.round(),
              blue.round(),
              1.0,
            );
            final hexString =
                '#${red.round().toRadixString(16).padLeft(2, '0')}${green.round().toRadixString(16).padLeft(2, '0')}${blue.round().toRadixString(16).padLeft(2, '0')}'
                    .toUpperCase();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Custom Brand Color Picker', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          hexString,
                          style: TextStyle(
                            color: selectedColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Red Slider
                    Row(
                      children: [
                        const SizedBox(width: 20, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                        Expanded(
                          child: Slider(
                            value: red,
                            min: 0,
                            max: 255,
                            activeColor: Colors.red,
                            onChanged: (val) => setDialogState(() => red = val),
                          ),
                        ),
                        SizedBox(width: 36, child: Text('${red.round()}', textAlign: TextAlign.right)),
                      ],
                    ),

                    // Green Slider
                    Row(
                      children: [
                        const SizedBox(width: 20, child: Text('G', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                        Expanded(
                          child: Slider(
                            value: green,
                            min: 0,
                            max: 255,
                            activeColor: Colors.green,
                            onChanged: (val) => setDialogState(() => green = val),
                          ),
                        ),
                        SizedBox(width: 36, child: Text('${green.round()}', textAlign: TextAlign.right)),
                      ],
                    ),

                    // Blue Slider
                    Row(
                      children: [
                        const SizedBox(width: 20, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        Expanded(
                          child: Slider(
                            value: blue,
                            min: 0,
                            max: 255,
                            activeColor: Colors.blue,
                            onChanged: (val) => setDialogState(() => blue = val),
                          ),
                        ),
                        SizedBox(width: 36, child: Text('${blue.round()}', textAlign: TextAlign.right)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: selectedColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _selectColor(hexString);
                  },
                  child: const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _parseColor(widget.currentColorHex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Color Preview Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.color_lens,
                color: currentColor.computeLuminance() > 0.5
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Manual HEX Input Field
            Expanded(
              child: TextFormField(
                controller: _hexController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'HEX Color Code',
                  hintText: '#2563EB',
                  errorText: _hexErrorText,
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Open Custom Color Palette',
                    onPressed: () => _openCustomColorDialog(context),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  String clean = val.replaceAll('#', '').trim();
                  if (clean.length == 6 && _isValidHex(clean)) {
                    setState(() {
                      _hexErrorText = null;
                    });
                    widget.onColorChanged('#${clean.toUpperCase()}');
                  } else if (clean.length > 6) {
                    setState(() {
                      _hexErrorText = 'HEX code must be 6 hex digits';
                    });
                  }
                },
                onFieldSubmitted: _onHexSubmitted,
              ),
            ),
            const SizedBox(width: 10),

            // Custom Picker Button
            IconButton.filledTonal(
              onPressed: () => _openCustomColorDialog(context),
              tooltip: 'Custom Color Wheel',
              icon: const Icon(Icons.palette_outlined),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Suggested Colors Header & Swatches
        Text(
          'Suggested Palette',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestedColors.map((hex) {
            final color = _parseColor(hex);
            final selected = widget.currentColorHex.toUpperCase().replaceAll('#', '') ==
                hex.toUpperCase().replaceAll('#', '');

            return GestureDetector(
              onTap: () => _selectColor(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
