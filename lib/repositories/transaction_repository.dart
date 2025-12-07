import '../models/transaction.dart';
import '../services/storage_service.dart';

class TransactionRepository {
  List<Transaction> _transactions = [];
  
  Future<void> loadTransactions() async {
    try {
      final transactionsData = await StorageService.loadTransactions();
      
      if (transactionsData.isEmpty) {
        _transactions = [];
      } else {
        _transactions = transactionsData
            .map((data) => Transaction.fromMap(data))
            .toList();
        
        // Сортируем по дате в порядке убывания (новые первыми)
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      print('Ошибка загрузки транзакций: $e');
      _transactions = [];
    }
  }
  
  List<Transaction> getTransactions() {
    return List.from(_transactions);
  }
  
  Future<void> addTransaction(Transaction transaction) async {
    // Добавляем в начало списка
    _transactions.insert(0, transaction);
    await _saveTransactions();
  }
  
  Future<void> removeTransaction(String id) async {
    final initialCount = _transactions.length;
    _transactions.removeWhere((transaction) => transaction.id == id);
    
    if (_transactions.length < initialCount) {
      await _saveTransactions();
    }
  }
  
  Future<void> updateCategoryInTransactions(String oldCategory, bool isIncome, String newCategory) async {
    bool updated = false;
    final List<Transaction> updatedTransactions = [];
    
    print('Обновление категории в транзакциях: $oldCategory -> $newCategory, тип: $isIncome');
    
    for (final transaction in _transactions) {
      if (transaction.category == oldCategory && transaction.isIncome == isIncome) {
        print('Найдена транзакция для обновления: ${transaction.title}, категория: ${transaction.category}, дата: ${transaction.date}');
        updatedTransactions.add(Transaction(
          id: transaction.id,
          title: transaction.title,
          amount: transaction.amount,
          date: transaction.date, // Сохраняем оригинальную дату
          category: newCategory,
          description: transaction.description,
          isIncome: transaction.isIncome,
        ));
        updated = true;
      } else {
        updatedTransactions.add(transaction);
      }
    }
    
    if (updated) {
      _transactions = updatedTransactions;
      await _saveTransactions();
      print('Обновлено транзакций: $updated');
    } else {
      print('Не найдено транзакций для обновления');
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