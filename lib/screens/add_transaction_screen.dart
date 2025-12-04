import 'package:flutter/material.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить операцию'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Переключатель тип операции
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('ДОХОД'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('РАСХОД'),
                        selected: true,
                        onSelected: (selected) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Поле для суммы
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Сумма',
                prefixIcon: Icon(Icons.currency_ruble),
                border: OutlineInputBorder(),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Выбор категории
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Категория',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'food',
                  child: Text('Еда'),
                ),
                DropdownMenuItem(
                  value: 'transport',
                  child: Text('Транспорт'),
                ),
                DropdownMenuItem(
                  value: 'entertainment',
                  child: Text('Развлечения'),
                ),
                DropdownMenuItem(
                  value: 'shopping',
                  child: Text('Покупки'),
                ),
                DropdownMenuItem(
                  value: 'salary',
                  child: Text('Зарплата'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Другое'),
                ),
              ],
              onChanged: (value) {},
            ),

            const SizedBox(height: 16),

            // Поле для описания
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                hintText: 'Завтрак, кофе, магазин...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Кнопка сохранения
            ElevatedButton(
              onPressed: null, // Пока без логики
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'СОХРАНИТЬ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            // Подсказка
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Операция будет добавлена в историю транзакций и учтена в балансе',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}