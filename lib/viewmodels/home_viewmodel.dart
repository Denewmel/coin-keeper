import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

class HomeViewModel extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();
  
  List<Transaction> _transactions = [];
  Map<String, double> _currencyRates = {'USD': 0.0, 'EUR': 0.0};
  bool _isLoading = true;
  bool _isRefreshingCurrency = false;
  
  List<Transaction> get transactions => _transactions;
  Map<String, double> get currencyRates => _currencyRates;
  bool get isLoading => _isLoading;
  bool get isRefreshingCurrency => _isRefreshingCurrency;
  
  double get balance => _repository.calculateBalance();
  
  Future<void> loadInitialData() async {
    _isLoading = true;
    
    try {
      await _repository.loadTransactions();
      _transactions = _repository.getTransactions();
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
    await _repository.addTransaction(transaction);
    _transactions = _repository.getTransactions();
    notifyListeners();
  }
  
  Future<void> deleteTransaction(String id) async {
    await _repository.removeTransaction(id);
    _transactions = _repository.getTransactions();
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
      final transaction = Transaction.create(
        title: reason.isEmpty ? 'Корректировка баланса' : reason,
        amount: difference.abs(),
        category: 'Корректировка',
        description: 'Ручная корректировка баланса',
        isIncome: difference > 0,
      );
      
      addTransaction(transaction);
    }
  }
}