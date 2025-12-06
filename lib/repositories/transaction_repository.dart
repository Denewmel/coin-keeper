import '../models/transaction.dart';
import '../services/storage_service.dart';

class TransactionRepository {
  List<Transaction> _transactions = [];
  
  Future<void> loadTransactions() async {
    try {
      final transactionsData = await StorageService.loadTransactions();
      
      if (transactionsData.isEmpty) {
        // При первом запуске список пустой
        _transactions = [];
      } else {
        // Загружаем сохраненные транзакции
        _transactions = transactionsData
            .map((data) => Transaction.fromMap(data))
            .toList()
            .reversed
            .toList(); // Новые первыми
      }
    } catch (e) {
      print('Ошибка загрузки транзакций: $e');
      _transactions = []; // Пустой список при ошибке
    }
  }
  
  List<Transaction> getTransactions() {
    return List.from(_transactions);
  }
  
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.insert(0, transaction); // Добавляем в начало
    await _saveTransactions();
  }
  
  Future<void> removeTransaction(String id) async {
    final initialCount = _transactions.length;
    _transactions.removeWhere((transaction) => transaction.id == id);
    
    if (_transactions.length < initialCount) {
      await _saveTransactions();
    }
  }
  
  double calculateBalance() {
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
  
  Future<void> _saveTransactions() async {
    final transactionsData = _transactions.map((t) => t.toMap()).toList();
    await StorageService.saveTransactions(transactionsData);
  }
  
  Future<void> clearAllTransactions() async {
    _transactions.clear();
    await StorageService.clearAllData();
  }
}