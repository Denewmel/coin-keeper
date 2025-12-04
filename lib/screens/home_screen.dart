import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import '../dialogs/adjust_balance_dialog.dart';

/// Главный экран приложения
/// Отображает баланс, последние операции и навигационные кнопки
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Список всех транзакций (хранится в памяти приложения)
  List<Transaction> _transactions = [
    Transaction.create(
      title: 'Продукты',
      amount: 1200,
      category: 'Еда',
      isIncome: false,
    ),
    Transaction.create(
      title: 'Зарплата',
      amount: 30000,
      category: 'Зарплата',
      isIncome: true,
    ),
    Transaction.create(
      title: 'Кафе',
      amount: 850,
      category: 'Еда',
      isIncome: false,
    ),
  ];

  /// Рассчитывает текущий баланс на основе всех транзакций
  /// Доходы увеличивают баланс, расходы уменьшают
  double get _balance {
    double total = 0;
    for (var transaction in _transactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      } else {
        total -= transaction.amount;
      }
    }
    return total;
  }

  /// Добавляет новую транзакцию в начало списка
  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.insert(0, transaction);
    });
  }

  /// Корректирует баланс путем добавления специальной транзакции
  void _adjustBalance(double newBalance, String reason) {
    final difference = newBalance - _balance;
    
    if (difference.abs() > 0.01) {
      final adjustTransaction = Transaction.create(
        title: reason.isEmpty ? 'Корректировка баланса' : reason,
        amount: difference.abs(),
        category: 'Корректировка',
        description: 'Ручная корректировка баланса',
        isIncome: difference > 0,
      );
      
      _addTransaction(adjustTransaction);
    }
  }

  /// Показывает диалоговое окно для корректировки баланса
  void _showAdjustBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AdjustBalanceDialog(
        currentBalance: _balance,
        onSave: (newBalance, reason) {
          _adjustBalance(newBalance, reason);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Баланс успешно обновлен'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Берем только 3 последние транзакции для отображения на главном экране
    final recentTransactions = _transactions.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoinKeeper'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка для корректировки баланса
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showAdjustBalanceDialog,
            tooltip: 'Корректировать баланс',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Карточка с балансом (кликабельна для корректировки)
            GestureDetector(
              onTap: _showAdjustBalanceDialog,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Баланс'),
                          SizedBox(width: 8),
                          Icon(Icons.info_outline, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_balance.toStringAsFixed(0)} ₽',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Нажмите для корректировки',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Кнопки для добавления доходов и расходов
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            onSave: _addTransaction,
                            initialIsIncome: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('ДОХОД'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            onSave: _addTransaction,
                            initialIsIncome: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('РАСХОД'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Секция с последними операциями
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Последние операции:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = recentTransactions[index];
                        return ListTile(
                          leading: Icon(
                            transaction.isIncome
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: transaction.isIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(transaction.title),
                          subtitle: Text(
                            '${transaction.date.day}.${transaction.date.month}.${transaction.date.year}',
                          ),
                          trailing: Text(
                            '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              color: transaction.isIncome
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Виджет с курсами валют (статический, для демонстрации)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.currency_exchange, size: 16),
                  SizedBox(width: 8),
                  Text('USD: 92.50 ₽ • EUR: 99.80 ₽'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка для перехода к полному списку транзакций
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionsScreen(
                        transactions: _transactions,
                      ),
                    ),
                  );
                },
                child: const Text('ВСЕ ТРАНЗАКЦИИ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}