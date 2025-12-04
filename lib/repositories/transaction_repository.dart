import '../models/transaction.dart';
import '../services/storage_service.dart';

/// Репозиторий для управления транзакциями
/// Служит прослойкой между UI и сервисами хранения
class TransactionRepository {
  List<Transaction> _transactions = [];
  
  /// Загружает транзакции из хранилища
  Future<void> loadTransactions() async {
    try {
      final transactionsData = await StorageService.loadTransactions();
      
      if (transactionsData.isEmpty) {
        // Если нет сохраненных данных, создаем демо-транзакции
        _transactions = _getInitialTransactions();
        await _saveTransactions();
        print('Созданы начальные транзакции');
      } else {
        // Конвертируем данные из хранилища в объекты Transaction
        _transactions = transactionsData
            .map((data) => Transaction.fromMap(data))
            .toList()
            .reversed
            .toList(); // Новые первыми
        print('Загружено ${_transactions.length} транзакций');
      }
    } catch (e) {
      print('Ошибка в репозитории при загрузке транзакций: $e');
      _transactions = _getInitialTransactions();
    }
  }
  
  /// Возвращает список всех транзакций
  List<Transaction> getTransactions() {
    return List.from(_transactions);
  }
  
  /// Добавляет новую транзакцию
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.insert(0, transaction); // Добавляем в начало
    await _saveTransactions();
    print('Добавлена транзакция: ${transaction.title}');
  }
  
  /// Удаляет транзакцию по ID
  Future<void> removeTransaction(String id) async {
    final initialCount = _transactions.length;
    _transactions.removeWhere((transaction) => transaction.id == id);
    
    if (_transactions.length < initialCount) {
      await _saveTransactions();
      print('Удалена транзакция с ID: $id');
    }
  }
  
  /// Рассчитывает текущий баланс
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
  
  /// Сохраняет транзакции в хранилище
  Future<void> _saveTransactions() async {
    final transactionsData = _transactions.map((t) => t.toMap()).toList();
    await StorageService.saveTransactions(transactionsData);
  }
  
  /// Возвращает начальные демо-транзакции
  List<Transaction> _getInitialTransactions() {
    return [
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
  }
  
  /// Очищает все транзакции (для тестирования)
  Future<void> clearAllTransactions() async {
    _transactions.clear();
    await StorageService.clearAllData();
    print('Все транзакции очищены');
  }
}