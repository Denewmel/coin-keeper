import 'package:flutter/material.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final double amount;
  final String date;
  final IconData icon;
  final bool isIncome;

  const TransactionItem({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
    required this.isIncome,
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
            color: isIncome ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          date,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} ₽',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}