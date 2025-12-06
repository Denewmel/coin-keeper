import 'package:flutter/material.dart';
import '../models/transaction.dart';

/// Экран для отображения всех транзакций с возможностью удаления
class TransactionsScreen extends StatefulWidget {
  final List<Transaction> initialTransactions;
  final Function(String) onDeleteTransaction;
  
  const TransactionsScreen({
    super.key,
    required this.initialTransactions,
    required this.onDeleteTransaction,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';
  List<Transaction> _transactions = [];
  
  @override
  void initState() {
    super.initState();
    _transactions = widget.initialTransactions;
  }

  List<Transaction> get _filteredTransactions {
    switch (_filter) {
      case 'income':
        return _transactions.where((t) => t.isIncome).toList();
      case 'expense':
        return _transactions.where((t) => !t.isIncome).toList();
      default:
        return _transactions;
    }
  }

  /// Удаляет транзакцию с подтверждением
  void _deleteTransaction(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить операцию'),
        content: Text('Вы уверены, что хотите удалить операцию "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Закрыть диалог
              
              // Удаляем из списка СРАЗУ
              setState(() {
                _transactions.removeWhere((t) => t.id == id);
              });
              
              // Вызываем callback для удаления из хранилища
              await widget.onDeleteTransaction(id);
              
              // Показать уведомление об успешном удалении
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Операция удалена'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
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
          // Панель фильтров
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

          // Информация о количестве
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Показано: ${_filteredTransactions.length} из ${_transactions.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Список транзакций с кнопкой удаления
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

  /// Строит карточку транзакции с кнопкой удаления
  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
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
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.date.day}.${transaction.date.month}.${transaction.date.year}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              transaction.category,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 20,
                color: Colors.red.shade400,
              ),
              onPressed: () => _deleteTransaction(transaction.id, transaction.title),
              tooltip: 'Удалить операцию',
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
        onTap: () {
          // Показываем детали транзакции
          _showTransactionDetails(transaction);
        },
      ),
    );
  }

  /// Показывает детали транзакции
  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали операции'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
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
                    size: 30,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDetailRow('Название:', transaction.title),
              _buildDetailRow('Тип:', transaction.isIncome ? 'Доход' : 'Расход'),
              _buildDetailRow('Сумма:', '${transaction.amount.toStringAsFixed(2)} ₽'),
              _buildDetailRow('Категория:', transaction.category),
              _buildDetailRow(
                'Дата:', 
                '${transaction.date.day}.${transaction.date.month}.${transaction.date.year} '
                '${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}'
              ),
              
              if (transaction.description != null && transaction.description!.isNotEmpty)
                _buildDetailRow('Описание:', transaction.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрыть детали
              _deleteTransaction(transaction.id, transaction.title); // Удалить
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Вспомогательный метод для отображения строки деталей
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}