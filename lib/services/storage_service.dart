import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Сервис для работы с локальным хранилищем (SharedPreferences)
class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _currencyRatesKey = 'currency_rates';
  static const String _currencyLastUpdateKey = 'currency_last_update';

  /// Сохраняет список транзакций в локальное хранилище
  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(transactions);
      await prefs.setString(_transactionsKey, jsonString);
      print('Транзакции сохранены: ${transactions.length} записей');
    } catch (e) {
      print('Ошибка сохранения транзакций: $e');
    }
  }

  /// Загружает список транзакций из локального хранилища
  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_transactionsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('Нет сохраненных транзакций');
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final transactions = jsonList.cast<Map<String, dynamic>>().toList();
      print('Загружено транзакций: ${transactions.length} записей');
      return transactions;
    } catch (e) {
      print('Ошибка загрузки транзакций: $e');
      return [];
    }
  }

  /// Сохраняет курсы валют в локальное хранилище
  static Future<void> saveCurrencyRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(rates);
      await prefs.setString(_currencyRatesKey, jsonString);
      await prefs.setString(_currencyLastUpdateKey, DateTime.now().toIso8601String());
      print('Курсы валют сохранены: $rates');
    } catch (e) {
      print('Ошибка сохранения курсов валют: $e');
    }
  }

  /// Загружает курсы валют из локального хранилища
  static Future<Map<String, dynamic>> loadCurrencySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_currencyRatesKey);
      final lastUpdate = prefs.getString(_currencyLastUpdateKey);
      
      Map<String, double> rates = {};
      if (ratesJson != null) {
        final Map<String, dynamic> decoded = json.decode(ratesJson) as Map<String, dynamic>;
        rates = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      
      DateTime? lastUpdateDate;
      if (lastUpdate != null) {
        lastUpdateDate = DateTime.parse(lastUpdate);
      }
      
      print('Загружены курсы валют: $rates, последнее обновление: $lastUpdateDate');
      
      return {
        'rates': rates,
        'lastUpdate': lastUpdateDate,
      };
    } catch (e) {
      print('Ошибка загрузки курсов валют: $e');
      return {
        'rates': {},
        'lastUpdate': null,
      };
    }
  }

  /// Очищает все сохраненные данные (для тестирования)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('Все данные очищены');
    } catch (e) {
      print('Ошибка очистки данных: $e');
    }
  }
}