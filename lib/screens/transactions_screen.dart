import 'package:flutter/material.dart';
import '../models/transaction.dart';

/// Экран для отображения всех транзакций с возможностью фильтрации
class TransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  
  const TransactionsScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Фильтр для отображения транзакций: all, income, expense
  String _filter = 'all';

  /// Возвращает отфильтрованный список транзакций в зависимости от выбранного фильтра
  List<Transaction> get _filteredTransactions {
    switch (_filter) {
      case 'income':
        return widget.transactions.where((t) => t.isIncome).toList();
      case 'expense':
        return widget.transactions.where((t) => !t.isIncome).toList();
      default:
        return widget.transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все транзакции'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Панель фильтров: Все/Доходы/Расходы
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: _filter == 'all',
                  onSelected: (bool value) {
                    setState(() {
                      _filter = 'all';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Доходы'),
                  selected: _filter == 'income',
                  onSelected: (bool value) {
                    setState(() {
                      _filter = 'income';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Расходы'),
                  selected: _filter == 'expense',
                  onSelected: (bool value) {
                    setState(() {
                      _filter = 'expense';
                    });
                  },
                ),
              ],
            ),
          ),

          // Информация о количестве отфильтрованных транзакций
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Показано: ${_filteredTransactions.length} из ${widget.transactions.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Список транзакций
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нет транзакций',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Добавьте первую транзакцию на главном экране',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Строит карточку для отображения транзакции с полной информацией
  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок карточки: иконка, название, категория и сумма
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Иконка типа операции (доход/расход)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: transaction.isIncome 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          transaction.isIncome 
                              ? Icons.arrow_upward 
                              : Icons.arrow_downward,
                          size: 20,
                          color: transaction.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название транзакции
                            Text(
                              transaction.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Категория транзакции
                            Text(
                              transaction.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Сумма транзакции (зеленый для доходов, красный для расходов)
                Text(
                  '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Строка с датой и временем операции
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${transaction.date.day}.${transaction.date.month}.${transaction.date.year} '
                  '${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Блок с описанием (отображается только если описание есть)
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    'Описание:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            // Отладочная информация: последние 6 символов ID транзакции
            if (transaction.description == null || transaction.description!.isEmpty)
              const SizedBox(height: 4),
            Text(
              'ID: ${transaction.id.substring(transaction.id.length - 6)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}