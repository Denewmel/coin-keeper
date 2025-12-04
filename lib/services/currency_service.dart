import 'package:http/http.dart' as http;
import 'dart:convert';

/// Сервис для получения курсов валют ЦБ РФ
/// API документация: https://www.cbr-xml-daily.ru/
class CurrencyService {
  static const Duration _cacheDuration = Duration(hours: 12);
  
  /// Основной API: Центробанк России (CBR)
  /// Возвращает актуальные курсы валют к рублю
  static const String _cbrApiUrl = 'https://www.cbr-xml-daily.ru/daily_json.js';
  
  /// Получает актуальные курсы валют из API ЦБ РФ
  /// Возвращает курсы в формате: {'USD': 92.50, 'EUR': 99.80}
  /// где значения - это сколько рублей стоит 1 USD/EUR
  static Future<Map<String, double>> fetchCurrencyRates() async {
    print('=== ЗАПРОС К API ЦБ РФ ===');
    print('URL: $_cbrApiUrl');
    
    try {
      final response = await http.get(
        Uri.parse(_cbrApiUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'CoinKeeper/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('Статус ответа: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Успешно получены данные от ЦБ РФ');
        
        // Логируем дату курсов
        final date = data['Date'] as String;
        final previousDate = data['PreviousDate'] as String;
        print('Дата курсов: $date');
        print('Предыдущая дата: $previousDate');
        
        final Map<String, dynamic> valutes = data['Valute'] as Map<String, dynamic>;
        
        // Извлекаем курсы USD и EUR
        if (valutes.containsKey('USD') && valutes.containsKey('EUR')) {
          final Map<String, dynamic> usdData = valutes['USD'] as Map<String, dynamic>;
          final Map<String, dynamic> eurData = valutes['EUR'] as Map<String, dynamic>;
          
          final double usdValue = (usdData['Value'] as num).toDouble();
          final int usdNominal = usdData['Nominal'] as int;
          final double usdToRub = usdValue / usdNominal;
          
          final double eurValue = (eurData['Value'] as num).toDouble();
          final int eurNominal = eurData['Nominal'] as int;
          final double eurToRub = eurValue / eurNominal;
          
          final result = {
            'USD': double.parse(usdToRub.toStringAsFixed(2)),
            'EUR': double.parse(eurToRub.toStringAsFixed(2)),
          };
          
          // Логируем детали
          print('Детали курсов:');
          print('  USD:');
          print('    ID: ${usdData['ID']}');
          print('    NumCode: ${usdData['NumCode']}');
          print('    CharCode: ${usdData['CharCode']}');
          print('    Nominal: $usdNominal');
          print('    Name: ${usdData['Name']}');
          print('    Value: $usdValue');
          print('    Previous: ${usdData['Previous']}');
          print('    Курс к RUB: ${result['USD']}');
          
          print('  EUR:');
          print('    ID: ${eurData['ID']}');
          print('    NumCode: ${eurData['NumCode']}');
          print('    CharCode: ${eurData['CharCode']}');
          print('    Nominal: $eurNominal');
          print('    Name: ${eurData['Name']}');
          print('    Value: $eurValue');
          print('    Previous: ${eurData['Previous']}');
          print('    Курс к RUB: ${result['EUR']}');
          
          print('=== УСПЕШНО ПОЛУЧЕНЫ КУРСЫ ОТ ЦБ РФ ===');
          return result;
        } else {
          print('❌ В ответе отсутствуют нужные валюты');
          print('Доступные валюты: ${valutes.keys.join(', ')}');
          return _getFallbackRates();
        }
      } else {
        print('❌ Ошибка API ЦБ РФ: ${response.statusCode}');
        print('Тело ответа: ${response.body.substring(0, 200)}...');
        return _getFallbackRates();
      }
    } catch (e) {
      print('❌ Критическая ошибка при запросе к ЦБ РФ: $e');
      print('=== ИСПОЛЬЗУЕМ РЕЗЕРВНЫЕ КУРСЫ ===');
      return _getFallbackRates();
    }
  }
  
  /// Резервный метод на случай ошибки API
  static Map<String, double> _getFallbackRates() {
    // Используем реалистичные фиксированные курсы
    return {
      'USD': 92.50,
      'EUR': 99.80,
    };
  }
  
  /// Возвращает курсы по умолчанию (для инициализации)
  static Map<String, double> getDefaultRates() {
    return {
      'USD': 92.50,
      'EUR': 99.80,
    };
  }
  
  /// Проверяет, нужно ли обновлять курсы валют
  static bool shouldUpdateCurrency(DateTime? lastUpdate) {
    if (lastUpdate == null) {
      return true;
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    // Обновляем раз в 12 часов
    return difference > _cacheDuration;
  }
  
  /// Умный метод для получения курсов с кэшированием и повторными попытками
  static Future<Map<String, double>> getCurrencyRates({
    required Map<String, double> cachedRates,
    required DateTime? lastUpdate,
    bool forceRefresh = false,
  }) async {
    // Если принудительное обновление или кэш устарел
    if (forceRefresh || shouldUpdateCurrency(lastUpdate)) {
      print('Обновляем курсы валют от ЦБ РФ...');
      
      // Пробуем получить свежие курсы
      try {
        final rates = await fetchCurrencyRates();
        if (_areValidRates(rates)) {
          print('✅ Получены валидные курсы от ЦБ РФ');
          return rates;
        } else {
          print('⚠️ Курсы от ЦБ РФ невалидны, проверяем...');
        }
      } catch (e) {
        print('Первая попытка не удалась: $e');
      }
      
      // Вторая попытка через 2 секунды
      await Future.delayed(const Duration(seconds: 2));
      try {
        final rates = await fetchCurrencyRates();
        if (_areValidRates(rates)) {
          print('✅ Вторая попытка успешна');
          return rates;
        }
      } catch (e) {
        print('Вторая попытка не удалась: $e');
      }
      
      // Если обе попытки неудачны, используем кэш или дефолтные значения
      print('⚠️ Используем кэшированные курсы из-за ошибок API');
    } else {
      print('Используем кэшированные курсы ЦБ РФ (еще актуальны)');
    }
    
    return cachedRates.isNotEmpty ? cachedRates : getDefaultRates();
  }
  
  /// Проверяет валидность полученных курсов
  static bool _areValidRates(Map<String, double> rates) {
    return rates.containsKey('USD') && 
           rates.containsKey('EUR') &&
           rates['USD']! > 50 && // Реалистичный минимум для USD
           rates['EUR']! > 50 && // Реалистичный минимум для EUR
           rates['USD']! < 200 && // Реалистичный максимум
           rates['EUR']! < 200;
  }
  
  /// Тестовый метод для проверки работы API ЦБ РФ
  static Future<void> testApiConnection() async {
    print('=== ТЕСТ ПОДКЛЮЧЕНИЯ К API ЦБ РФ ===');
    
    try {
      final testResponse = await http.get(
        Uri.parse('https://www.cbr-xml-daily.ru/latest.js'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (testResponse.statusCode == 200) {
        final data = json.decode(testResponse.body) as Map<String, dynamic>;
        print('✅ API ЦБ РФ доступен');
        print('Дата: ${data['date']}');
        print('Базовая валюта: ${data['base']}');
        
        final rates = data['rates'] as Map<String, dynamic>;
        print('Количество валют: ${rates.length}');
        print('USD доступен: ${rates.containsKey('USD')}');
        print('EUR доступен: ${rates.containsKey('EUR')}');
        print('RUB доступен: ${rates.containsKey('RUB')}');
        
        print('=== ТЕСТ ПРОЙДЕН УСПЕШНО ===');
      } else {
        print('❌ Тест не пройден. Статус: ${testResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка теста: $e');
    }
  }
}