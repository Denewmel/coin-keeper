import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все транзакции'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Фильтры
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: true,
                  onSelected: (bool value) {},
                ),
                FilterChip(
                  label: const Text('Доходы'),
                  selected: false,
                  onSelected: (bool value) {},
                ),
                FilterChip(
                  label: const Text('Расходы'),
                  selected: false,
                  onSelected: (bool value) {},
                ),
              ],
            ),
          ),

          // Список транзакций
          Expanded(
            child: ListView(
              children: const [
                TransactionItem(
                  title: 'Продукты',
                  amount: -1200,
                  date: '12 окт 2024',
                  icon: Icons.shopping_cart,
                ),
                TransactionItem(
                  title: 'Зарплата',
                  amount: 30000,
                  date: '11 окт 2024', 
                  icon: Icons.work,
                ),
                TransactionItem(
                  title: 'Кафе',
                  amount: -850,
                  date: '10 окт 2024',
                  icon: Icons.restaurant,
                ),
                TransactionItem(
                  title: 'Транспорт',
                  amount: -350,
                  date: '9 окт 2024',
                  icon: Icons.directions_bus,
                ),
                TransactionItem(
                  title: 'Кино',
                  amount: -600,
                  date: '8 окт 2024',
                  icon: Icons.movie,
                ),
                TransactionItem(
                  title: 'Интернет',
                  amount: -500,
                  date: '7 окт 2024',
                  icon: Icons.wifi,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final int amount;
  final String date;
  final IconData icon;

  const TransactionItem({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: amount > 0 ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: amount > 0 ? Colors.green : Colors.red,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          date,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${amount > 0 ? '+' : ''}${amount.toString()} ₽',
          style: TextStyle(
            color: amount > 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}