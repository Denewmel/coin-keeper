import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoinKeeper'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Карточка баланса
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Баланс'),
                    const SizedBox(height: 8),
                    Text(
                      '15 430 ₽',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Кнопки операций
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: null,
                    child: const Text('ДОХОД'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: null,
                    child: const Text('РАСХОД'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Список операций
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Последние операции:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.shopping_cart),
                    title: Text('Продукты'),
                    trailing: Text('-1 200 ₽'),
                  ),
                  ListTile(
                    leading: Icon(Icons.work),
                    title: Text('Зарплата'),
                    trailing: Text('+30 000 ₽'),
                  ),
                  ListTile(
                    leading: Icon(Icons.restaurant),
                    title: Text('Кафе'),
                    trailing: Text('-850 ₽'),
                  ),
                ],
              ),
            ),

            // Курс валют
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.currency_exchange, size: 16),
                  SizedBox(width: 8),
                  Text('USD: 92.50 ₽ • EUR: 99.80 ₽'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка перехода
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('ВСЕ ТРАНЗАКЦИИ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}