import 'package:flutter/material.dart';
import '../services/config_service.dart';

class PinDialog extends StatelessWidget {
  const PinDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => const _PinDialogContent();
}

class _PinDialogContent extends StatefulWidget {
  const _PinDialogContent();

  @override
  State<_PinDialogContent> createState() => _PinDialogContentState();
}

class _PinDialogContentState extends State<_PinDialogContent> {
  String? _errorMessage;
  final GlobalKey<PinInputState> _pinKey = GlobalKey<PinInputState>();
  bool _isChecking = false;

  Future<void> _onPinComplete(String pin) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final correctPin = await ConfigService.getParentPin();
    if (!mounted) return;

    final effectivePin = correctPin ?? '0000';

    if (pin == effectivePin) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorMessage = 'Code PIN incorrect.';
      _isChecking = false;
    });
    _pinKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Code PIN parental'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entrez le code à 4 chiffres pour accéder aux paramètres.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            PinInput(key: _pinKey, onComplete: _onPinComplete),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class PinInput extends StatefulWidget {
  const PinInput({super.key, required this.onComplete});
  final void Function(String pin) onComplete;

  @override
  State<PinInput> createState() => PinInputState();
}

class PinInputState extends State<PinInput> {
  final List<String?> _digits = List.filled(4, null);
  int _currentIndex = 0;
  bool _submitted = false;

  void _addDigit(String digit) {
    if (_currentIndex >= 4 || _submitted) return;
    setState(() {
      _digits[_currentIndex] = digit;
      _currentIndex++;
    });
    if (_currentIndex == 4) {
      _submitted = true;
      final pin = _digits.whereType<String>().join();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) widget.onComplete(pin);
      });
    }
  }

  void _removeDigit() {
    if (_currentIndex == 0 || _submitted) return;
    setState(() {
      _currentIndex--;
      _digits[_currentIndex] = null;
    });
  }

  void _clear() {
    setState(() {
      for (var i = 0; i < 4; i++) {
        _digits[i] = null;
      }
      _currentIndex = 0;
      _submitted = false;
    });
  }

  void clear() => _clear();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isActive = index == _currentIndex;
            final digit = _digits[index];
            return Container(
              width: 48,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isActive ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: digit != null
                  ? Text(digit,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))
                  : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.grey.shade400
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildNumpad(),
      ],
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('1'), const SizedBox(width: 8),
          _buildKey('2'), const SizedBox(width: 8),
          _buildKey('3'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('4'), const SizedBox(width: 8),
          _buildKey('5'), const SizedBox(width: 8),
          _buildKey('6'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('7'), const SizedBox(width: 8),
          _buildKey('8'), const SizedBox(width: 8),
          _buildKey('9'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildBackspaceKey(), const SizedBox(width: 8),
          _buildKey('0'), const SizedBox(width: 8),
          _buildClearKey(),
        ]),
      ],
    );
  }

  Widget _buildKey(String digit) => SizedBox(
        width: 60,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _addDigit(digit),
            child: Center(
              child: Text(digit,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      );

  Widget _buildBackspaceKey() => SizedBox(
        width: 60,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _removeDigit,
            child: const Center(child: Icon(Icons.backspace_outlined, size: 20)),
          ),
        ),
      );

  Widget _buildClearKey() => SizedBox(
        width: 60,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _clear,
            child: const Center(child: Icon(Icons.clear, size: 20)),
          ),
        ),
      );
}