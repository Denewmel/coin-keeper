import 'dart:convert';

/// Модель данных для финансовой транзакции
/// Хранит информацию о доходе/расходе
class Transaction {
  final String id;           // Уникальный идентификатор транзакции
  final String title;        // Название операции
  final double amount;       // Сумма транзакции
  final DateTime date;       // Дата и время операции
  final String category;     // Категория (Еда, Транспорт и т.д.)
  final String? description; // Описание (опционально)
  final bool isIncome;       // true - доход, false - расход

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    required this.isIncome,
  });

  /// Фабричный метод для создания новой транзакции
  /// Автоматически генерирует ID и устанавливает текущую дату
  factory Transaction.create({
    required String title,
    required double amount,
    required String category,
    String? description,
    required bool isIncome,
  }) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
      description: description,
      isIncome: isIncome,
    );
  }

  /// Конвертирует транзакцию в Map для JSON-сериализации
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'isIncome': isIncome,
    };
  }

  /// Создает транзакцию из Map (при загрузке из хранилища)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      description: map['description'] as String?,
      isIncome: map['isIncome'] as bool,
    );
  }

  /// Конвертирует транзакцию в JSON строку
  String toJson() => json.encode(toMap());

  /// Создает транзакцию из JSON строки
  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source) as Map<String, dynamic>);
}