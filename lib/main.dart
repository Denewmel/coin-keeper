import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      //home: HomeScreen(), // Стартовый экран
      // Для тестирования других экранов:
      // home: TransactionsScreen()
      home: AddTransactionScreen()
    );
  }
}