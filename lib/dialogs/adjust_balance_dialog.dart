import 'package:flutter/material.dart';

/// Диалоговое окно для ручной корректировки баланса
/// Позволяет установить точное значение баланса с указанием причины
class AdjustBalanceDialog extends StatefulWidget {
  final double currentBalance;
  final Function(double, String) onSave;

  const AdjustBalanceDialog({
    super.key,
    required this.currentBalance,
    required this.onSave,
  });

  @override
  State<AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<AdjustBalanceDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Устанавливаем текущий баланс в поле ввода по умолчанию
    _amountController.text = widget.currentBalance.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Корректировка баланса'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Текущий баланс:'),
          Text(
            '${widget.currentBalance.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Поле для ввода нового значения баланса
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Новый баланс',
              prefixIcon: Icon(Icons.currency_ruble),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          // Поле для указания причины корректировки
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Причина корректировки (необязательно)',
              border: OutlineInputBorder(),
              hintText: 'Например: начальный баланс, ошибка в расчетах',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        // Кнопка отмены
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Отмена'),
        ),
        // Кнопка сохранения
        ElevatedButton(
          onPressed: () {
            final newBalance = double.tryParse(_amountController.text) ?? 0;
            widget.onSave(newBalance, _reasonController.text);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}