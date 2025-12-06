import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import '../dialogs/adjust_balance_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionRepository _repository = TransactionRepository();
  List<Transaction> _transactions = [];
  Map<String, double> _currencyRates = {'USD': 0.0, 'EUR': 0.0};
  bool _isLoading = true;
  bool _isRefreshingCurrency = false;

  @override
  void initState() {
    super.initState();
    print('Инициализация HomeScreen...');
    _loadInitialData();
  }

  /// Загружает начальные данные при запуске приложения
  Future<void> _loadInitialData() async {
    print('Начало загрузки данных...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем транзакции
      print('Загрузка транзакций...');
      await _repository.loadTransactions();
      _transactions = _repository.getTransactions();
      print('Транзакций загружено: ${_transactions.length}');
      
      // Загружаем курсы валют
      print('Загрузка курсов валют от ЦБ РФ...');
      await _loadCurrencyRates();
      
      print('Все данные успешно загружены');
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      // Показываем сообщение об ошибке
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка загрузки данных'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Загрузка завершена');
    }
  }

  /// Загружает курсы валют от ЦБ РФ (из API или кэша)
  Future<void> _loadCurrencyRates() async {
    try {
      final settings = await StorageService.loadCurrencySettings();
      final cachedRates = settings['rates'] as Map<String, double>;
      final lastUpdate = settings['lastUpdate'] as DateTime?;
      
      print('=== ЗАГРУЗКА КУРСОВ ВАЛЮТ ОТ ЦБ РФ ===');
      print('Кэшированные курсы: $cachedRates');
      print('Последнее обновление: $lastUpdate');
      
      // Получаем курсы (обновляем если нужно)
      final rates = await CurrencyService.getCurrencyRates(
        cachedRates: cachedRates,
        lastUpdate: lastUpdate,
      );
      
      // Проверяем, изменились ли курсы
      final bool ratesChanged = rates['USD'] != cachedRates['USD'] || 
                                rates['EUR'] != cachedRates['EUR'];
      
      // Сохраняем новые курсы если они обновились
      if (ratesChanged) {
        print('Курсы изменились, сохраняем: $rates');
        await StorageService.saveCurrencyRates(rates);
        
        // Показываем уведомление о обновлении
        if (mounted && cachedRates.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Курсы ЦБ РФ обновлены\nUSD: ${rates['USD']}₽  EUR: ${rates['EUR']}₽',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Курсы не изменились, используем кэш');
      }
      
      if (mounted) {
        setState(() {
          _currencyRates = rates;
        });
      }
      
      print('Текущие курсы валют ЦБ РФ: $_currencyRates');
      print('=== ЗАГРУЗКА КУРСОВ ЗАВЕРШЕНА ===');
      
    } catch (e) {
      print('ОШИБКА ЗАГРУЗКИ КУРСОВ ЦБ РФ: $e');
      
      // Используем дефолтные курсы
      final defaultRates = CurrencyService.getDefaultRates();
      
      if (mounted) {
        setState(() {
          _currencyRates = defaultRates;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Используются базовые курсы валют'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Сохраняем курсы по умолчанию
      await StorageService.saveCurrencyRates(defaultRates);
    }
  }

  /// Проверяет, нужно ли обновлять курсы валют
  bool _shouldUpdateCurrency(DateTime? lastUpdate) {
    if (lastUpdate == null) {
      return true;
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    // Обновляем раз в 12 часов
    return difference > const Duration(hours: 12);
  }

  /// Обновляет курсы валют вручную
  Future<void> _refreshCurrencyRates() async {
    if (_isRefreshingCurrency) return;
    
    setState(() {
      _isRefreshingCurrency = true;
    });
    
    try {
      print('=== РУЧНОЕ ОБНОВЛЕНИЕ КУРСОВ ВАЛЮТ ОТ ЦБ РФ ===');
      
      // Получаем текущие настройки
      final settings = await StorageService.loadCurrencySettings();
      final cachedRates = settings['rates'] as Map<String, double>;
      
      // Принудительно обновляем курсы
      final newRates = await CurrencyService.getCurrencyRates(
        cachedRates: cachedRates,
        lastUpdate: DateTime.now(), // Устанавливаем текущее время чтобы обновить
        forceRefresh: true,
      );
      
      // Сохраняем новые курсы
      await StorageService.saveCurrencyRates(newRates);
      
      // Обновляем состояние
      if (mounted) {
        setState(() {
          _currencyRates = newRates;
        });
        
        // Показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Курсы ЦБ РФ обновлены\nUSD: ${newRates['USD']}₽  EUR: ${newRates['EUR']}₽',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      print('Курсы ЦБ РФ успешно обновлены: $newRates');
      
    } catch (e) {
      print('Ошибка обновления курсов ЦБ РФ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingCurrency = false;
        });
      }
    }
  }

  /// Добавляет новую транзакцию
  Future<void> _addTransaction(Transaction transaction) async {
    try {
      await _repository.addTransaction(transaction);
      // Обновляем список транзакций
      if (mounted) {
        setState(() {
          _transactions = _repository.getTransactions();
        });
      }
      
      print('Транзакция добавлена: ${transaction.title}');
    } catch (e) {
      print('Ошибка добавления транзакции: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка сохранения транзакции'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Удаляет транзакцию по ID
  Future<void> _deleteTransaction(String id) async {
    try {
      await _repository.removeTransaction(id);
      // Обновляем список транзакций
      if (mounted) {
        setState(() {
          _transactions = _repository.getTransactions();
        });
      }
      
      print('Транзакция удалена: $id');
    } catch (e) {
      print('Ошибка удаления транзакции: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка удаления транзакции'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Корректирует баланс путем добавления специальной транзакции
  void _adjustBalance(double newBalance, String reason) {
    final difference = newBalance - _repository.calculateBalance();
    
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

  /// Показывает диалог корректировки баланса
  void _showAdjustBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AdjustBalanceDialog(
        currentBalance: _repository.calculateBalance(),
        onSave: (newBalance, reason) {
          _adjustBalance(newBalance, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Баланс успешно обновлен'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  /// Тестирует API ЦБ РФ с подробной информацией
  void _testCBRApi() async {
    print('=== ДЕТАЛЬНЫЙ ТЕСТ API ЦБ РФ ===');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тестирование API ЦБ РФ'),
        content: FutureBuilder(
          future: _performCBRApiTest(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Тестирование подключения к ЦБ РФ...'),
                ],
              );
            }
            
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❌ Ошибка тестирования:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: const TextStyle(fontFamily: 'monospace')),
                ],
              );
            }
            
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data ?? [const Text('Нет данных')],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<List<Widget>> _performCBRApiTest() async {
    List<Widget> results = [];
    
    try {
      // Тест 1: Проверка основного API
      results.add(const Text('1. Проверка основного API:',
          style: TextStyle(fontWeight: FontWeight.bold)));
      
      final cbrResponse = await http.get(
        Uri.parse('https://www.cbr-xml-daily.ru/daily_json.js'),
      ).timeout(const Duration(seconds: 10));
      
      if (cbrResponse.statusCode == 200) {
        final data = json.decode(cbrResponse.body) as Map<String, dynamic>;
        results.add(const Text('✅ API ЦБ РФ доступен'));
        results.add(Text('   Дата: ${data['Date']}'));
        results.add(Text('   Предыдущая дата: ${data['PreviousDate']}'));
        
        final valutes = data['Valute'] as Map<String, dynamic>;
        results.add(Text('   Количество валют: ${valutes.length}'));
        
        if (valutes.containsKey('USD')) {
          final usd = valutes['USD'] as Map<String, dynamic>;
          results.add(Text('   USD: ${usd['Value']} RUB за ${usd['Nominal']} ${usd['CharCode']}'));
        } else {
          results.add(const Text('   ❌ USD отсутствует'));
        }
        
        if (valutes.containsKey('EUR')) {
          final eur = valutes['EUR'] as Map<String, dynamic>;
          results.add(Text('   EUR: ${eur['Value']} RUB за ${eur['Nominal']} ${eur['CharCode']}'));
        } else {
          results.add(const Text('   ❌ EUR отсутствует'));
        }
      } else {
        results.add(Text('❌ Ошибка: ${cbrResponse.statusCode}'));
        results.add(Text('   Тело: ${cbrResponse.body.substring(0, 100)}...'));
      }
      
      results.add(const SizedBox(height: 16));
      
      // Тест 2: Проверка альтернативного endpoint
      results.add(const Text('2. Проверка альтернативного API:',
          style: TextStyle(fontWeight: FontWeight.bold)));
      
      final latestResponse = await http.get(
        Uri.parse('https://www.cbr-xml-daily.ru/latest.js'),
      ).timeout(const Duration(seconds: 10));
      
      if (latestResponse.statusCode == 200) {
        final data = json.decode(latestResponse.body) as Map<String, dynamic>;
        results.add(const Text('✅ Альтернативный API доступен'));
        results.add(Text('   Дата: ${data['date']}'));
        results.add(Text('   Базовая валюта: ${data['base']}'));
        
        final rates = data['rates'] as Map<String, dynamic>;
        results.add(Text('   RUB доступен: ${rates.containsKey('RUB')}'));
      } else {
        results.add(Text('⚠️ Альтернативный API: ${latestResponse.statusCode}'));
      }
      
      results.add(const SizedBox(height: 16));
      
      // Тест 3: Расчет курсов через CurrencyService
      results.add(const Text('3. Расчет курсов через CurrencyService:',
          style: TextStyle(fontWeight: FontWeight.bold)));
      
      try {
        final calculatedRates = await CurrencyService.fetchCurrencyRates();
        results.add(Text('   USD → RUB: ${calculatedRates['USD']?.toStringAsFixed(2)} ₽'));
        results.add(Text('   EUR → RUB: ${calculatedRates['EUR']?.toStringAsFixed(2)} ₽'));
        results.add(const Text('   ✅ Расчет выполнен успешно'));
      } catch (e) {
        results.add(Text('   ❌ Ошибка расчета: $e'));
      }
      
    } catch (e) {
      results.add(Text('Критическая ошибка: $e', style: const TextStyle(color: Colors.red)));
    }
    
    return results;
  }

  /// Форматирует число (курс валюты)
  String _formatRate(double rate) {
    return rate.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions = _transactions.take(3).toList();
    final balance = _repository.calculateBalance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoinKeeper'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка обновления курсов валют
          IconButton(
            icon: _isRefreshingCurrency
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshingCurrency ? null : _refreshCurrencyRates,
            tooltip: 'Обновить курсы валют',
          ),
          // Кнопка корректировки баланса
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showAdjustBalanceDialog,
            tooltip: 'Корректировать баланс',
          ),
          // Меню дополнительных действий
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_cache',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Очистить кэш валют'),
                  subtitle: Text('Загрузит свежие курсы'),
                ),
              ),
              const PopupMenuItem(
                value: 'test_api',
                child: ListTile(
                  leading: Icon(Icons.wifi_find, color: Colors.blue),
                  title: Text('Тест API ЦБ РФ'),
                  subtitle: Text('Проверить соединение'),
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'clear_cache') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('currency_last_update');
                await prefs.remove('currency_rates');
                await _loadCurrencyRates();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Кэш очищен, загружаем свежие курсы'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else if (value == 'test_api') {
                _testCBRApi();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка данных...'),
                  SizedBox(height: 8),
                  Text(
                    'Пожалуйста, подождите',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Карточка баланса
                    GestureDetector(
                      onTap: _showAdjustBalanceDialog,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Текущий баланс',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.info_outline, size: 14),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${balance.toStringAsFixed(0)} ₽',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: balance >= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Нажмите для корректировки',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Кнопки операций
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('ДОХОД'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
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
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('РАСХОД'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Заголовок последних операций
                    const Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Последние операции:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Список последних операций
                    Expanded(
                      child: recentTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Нет операций',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Добавьте первую транзакцию',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: recentTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = recentTransactions[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 0),
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
                                        color: transaction.isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      transaction.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${transaction.date.day}.${transaction.date.month}.${transaction.date.year} • ${transaction.category}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ₽',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: transaction.isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Виджет с курсами валют
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _refreshCurrencyRates,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.currency_exchange,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Курсы валют (ЦБ РФ)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.blue.shade500,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCurrencyItem(
                                  'USD',
                                  _currencyRates['USD'] ?? 0.0,
                                  Colors.green.shade700,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),
                                _buildCurrencyItem(
                                  'EUR',
                                  _currencyRates['EUR'] ?? 0.0,
                                  Colors.blue.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Нажмите для обновления',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            // Индикатор использования курсов по умолчанию
                            if (_currencyRates['USD'] == 92.50 || _currencyRates['EUR'] == 99.80)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 12,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Используются курсы по умолчанию',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Индикатор успешного обновления
                            if (_isRefreshingCurrency)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Обновление курсов...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Кнопка перехода к полному списку
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsScreen(
                                initialTransactions: _transactions,
                                onDeleteTransaction: _deleteTransaction,
                              ),
                            ),
                          ).then((_) {
                            // После возврата с экрана транзакций обновляем состояние
                            if (mounted) {
                              setState(() {
                                _transactions = _repository.getTransactions();
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('ВСЕ ТРАНЗАКЦИИ'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Строит виджет для отображения курса валюты
  Widget _buildCurrencyItem(String currency, double rate, Color color) {
    return Column(
      children: [
        Text(
          currency,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatRate(rate)} ₽',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '1 $currency',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}