import 'package:flutter/material.dart';
import 'models/transaction.dart';

class TransactionProvider with ChangeNotifier {
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

  List<Transaction> get transactions => _transactions;

  double get balance {
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

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  void adjustBalance(double newBalance, String reason) {
    final currentBalance = balance;
    final difference = newBalance - currentBalance;
    
    if (difference.abs() > 0.01) {
      final adjustTransaction = Transaction.create(
        title: reason.isEmpty ? 'Корректировка баланса' : reason,
        amount: difference.abs(),
        category: 'Корректировка',
        description: 'Ручная корректировка баланса',
        isIncome: difference > 0,
      );
      
      addTransaction(adjustTransaction);
    }
  }
}