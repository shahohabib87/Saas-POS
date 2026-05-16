import 'package:flutter/material.dart';
import 'package:easycasher/core/constants/app_colors.dart';

class PinPad extends StatefulWidget {
  final void Function(String pin) onComplete;
  final bool hasError;
  final VoidCallback onErrorClear;

  const PinPad({
    super.key,
    required this.onComplete,
    required this.hasError,
    required this.onErrorClear,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '',  '0', '⌫',
  ];

  void _onKey(String key) {
    if (widget.hasError) widget.onErrorClear();

    if (key == '⌫') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }

    if (key.isEmpty || _pin.length >= 4) return;

    setState(() => _pin += key);

    if (_pin.length == 4) {
      widget.onComplete(_pin);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _pin = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PinDots(length: _pin.length, hasError: widget.hasError),
        const SizedBox(height: 24),
        SizedBox(
          width: 260,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: _keys.map((k) => _KeyButton(label: k, onTap: () => _onKey(k))).toList(),
          ),
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final bool hasError;

  const _PinDots({required this.length, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final color = hasError ? AppColors.danger : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < length ? color : Colors.transparent,
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.outlineVariant,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    final isBackspace = label == '⌫';

    return Material(
      color: isBackspace
          ? AppColors.surfaceContainer
          : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBackspace ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: isBackspace
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
