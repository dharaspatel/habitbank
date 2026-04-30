import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

/// Cents-stored money input. Behaves like the iOS Wallet / banking apps:
/// every digit pushes onto the cents register, so typing "150" reads $1.50.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.cents,
    required this.onChanged,
    this.symbol = r'$',
  });

  final int cents;
  final ValueChanged<int> onChanged;
  final String symbol;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.cents));
  }

  @override
  void didUpdateWidget(covariant MoneyField old) {
    super.didUpdateWidget(old);
    if (widget.cents != old.cents) {
      final text = _format(widget.cents);
      if (text != _controller.text) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int cents) =>
      '${widget.symbol}${(cents / 100).toStringAsFixed(2)}';

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = int.tryParse(digits) ?? 0;
    final text = _format(cents);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged(cents);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\$]'))],
      onChanged: _onChanged,
      padding: const EdgeInsets.all(14),
      style: AppTheme.headline,
      placeholder: r'$0.00',
    );
  }
}

String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
