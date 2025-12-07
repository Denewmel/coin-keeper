import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import '../repositories/category_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<Transaction> _transactions = [];
  Map<String, double> _currencyRates = {'USD': 0.0, 'EUR': 0.0};
  bool _isLoading = true;
  bool _isRefreshingCurrency = false;
  
  List<Transaction> get transactions => _transactions;
  Map<String, double> get currencyRates => _currencyRates;
  bool get isLoading => _isLoading;
  bool get isRefreshingCurrency => _isRefreshingCurrency;
  CategoryRepository get categoryRepository => _categoryRepository;
  
  double get balance => _transactionRepository.calculateBalance();
  
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _categoryRepository.loadCategories();
      await _transactionRepository.loadTransactions();
      _transactions = _transactionRepository.getTransactions();
      await _loadCurrencyRates();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadCurrencyRates() async {
    try {
      final settings = await StorageService.loadCurrencySettings();
      final cachedRates = settings['rates'] as Map<String, double>;
      final lastUpdate = settings['lastUpdate'] as DateTime?;
      
      final rates = await CurrencyService.getCurrencyRates(
        cachedRates: cachedRates,
        lastUpdate: lastUpdate,
      );
      
      _currencyRates = rates;
    } catch (e) {
      print('Ошибка загрузки курсов: $e');
      _currencyRates = CurrencyService.getDefaultRates();
    }
  }
  
  Future<void> addTransaction(Transaction transaction) async {
    await _transactionRepository.addTransaction(transaction);
    // Получаем обновленный список, сохраняя сортировку
    await _transactionRepository.loadTransactions();
    _transactions = _transactionRepository.getTransactions();
    notifyListeners();
  }
  
  Future<void> deleteTransaction(String id) async {
    await _transactionRepository.removeTransaction(id);
    // Получаем обновленный список, сохраняя сортировку
    await _transactionRepository.loadTransactions();
    _transactions = _transactionRepository.getTransactions();
    notifyListeners();
  }
  
  Future<void> refreshCurrencyRates() async {
    if (_isRefreshingCurrency) return;
    
    _isRefreshingCurrency = true;
    notifyListeners();
    
    try {
      final settings = await StorageService.loadCurrencySettings();
      final cachedRates = settings['rates'] as Map<String, double>;
      
      final newRates = await CurrencyService.getCurrencyRates(
        cachedRates: cachedRates,
        lastUpdate: DateTime.now(),
        forceRefresh: true,
      );
      
      await StorageService.saveCurrencyRates(newRates);
      _currencyRates = newRates;
      notifyListeners();
    } catch (e) {
      print('Ошибка обновления курсов: $e');
    } finally {
      _isRefreshingCurrency = false;
      notifyListeners();
    }
  }
  
  void adjustBalance(double newBalance, String reason) {
    final currentBalance = balance;
    final difference = newBalance - currentBalance;
    
    if (difference.abs() > 0.01) {
      final otherCategory = _categoryRepository.getOtherCategory(difference > 0);
      
      final transaction = Transaction.create(
        title: reason.isEmpty ? 'Корректировка баланса' : reason,
        amount: difference.abs(),
        category: otherCategory.name,
        description: 'Ручная корректировка баланса',
        isIncome: difference > 0,
      );
      
      addTransaction(transaction);
    }
  }
  
  Future<void> removeCategory(String id, String categoryName, bool isIncome) async {
    try {
      final category = _categoryRepository.getCategoryById(id);
      
      if (category != null && category.name != 'Другое') {
        final otherCategory = _categoryRepository.getOtherCategory(isIncome);
        
        // Обновляем категорию в транзакциях
        await _transactionRepository.updateCategoryInTransactions(
          categoryName, 
          isIncome, 
          otherCategory.name
        );
        
        // Удаляем категорию из репозитория
        await _categoryRepository.removeCategory(id, isIncome);
        
        // Получаем обновленный список транзакций, сохраняя сортировку
        await _transactionRepository.loadTransactions();
        _transactions = _transactionRepository.getTransactions();
        
        notifyListeners();
        
        // Возвращаем успех, SnackBar покажем в UI
      } else {
        throw Exception('Категория не найдена или является "Другое"');
      }
    } catch (e) {
      print('Ошибка при удалении категории: $e');
      rethrow;
    }
  }
}