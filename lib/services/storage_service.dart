import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _currencyRatesKey = 'currency_rates';
  static const String _currencyLastUpdateKey = 'currency_last_update';
  static const String _categoriesKey = 'categories';

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

  static Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(categories);
      await prefs.setString(_categoriesKey, jsonString);
      print('Категории сохранены: ${categories.length} записей');
    } catch (e) {
      print('Ошибка сохранения категорий: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_categoriesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('Нет сохраненных категорий');
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final categories = jsonList.cast<Map<String, dynamic>>().toList();
      print('Загружено категорий: ${categories.length} записей');
      return categories;
    } catch (e) {
      print('Ошибка загрузки категорий: $e');
      return [];
    }
  }

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