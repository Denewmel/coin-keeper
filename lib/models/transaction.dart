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
}