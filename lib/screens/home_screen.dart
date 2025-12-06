import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../viewmodels/home_viewmodel.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import '../dialogs/adjust_balance_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Ждем окончания построения виджета перед загрузкой данных
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CoinKeeper'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: viewModel.isRefreshingCurrency
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: viewModel.isRefreshingCurrency ? null : viewModel.refreshCurrencyRates,
                tooltip: 'Обновить курсы валют',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAdjustBalanceDialog(context, viewModel),
                tooltip: 'Корректировать баланс',
              ),
            ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка данных...'),
          ],
        ),
      );
    }

    final recentTransactions = viewModel.transactions.take(3).toList();
    final balance = viewModel.balance;

    return RefreshIndicator(
      onRefresh: () => viewModel.loadInitialData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildBalanceCard(context, viewModel, balance),
              const SizedBox(height: 20),
              _buildActionButtons(context, viewModel),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 8),
                  Text('Последние операции:', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: recentTransactions.isEmpty
                    ? _buildEmptyTransactions()
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = recentTransactions[index];
                          return _buildTransactionItem(transaction);
                        },
                      ),
              ),
              const SizedBox(height: 16),
              _buildCurrencyRates(context, viewModel),
              const SizedBox(height: 16),
              _buildAllTransactionsButton(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, HomeViewModel viewModel, double balance) {
    return GestureDetector(
      onTap: () => _showAdjustBalanceDialog(context, viewModel),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text('Текущий баланс', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('${balance.toStringAsFixed(2)} ₽',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Нажмите для корректировки',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HomeViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToAddTransaction(context, viewModel, true),
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
            onPressed: () => _navigateToAddTransaction(context, viewModel, false),
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
    );
  }

  Widget _buildEmptyTransactions() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Нет операций', style: TextStyle(fontSize: 18, color: Colors.grey)),
          Text('Добавьте первую транзакцию', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction.isIncome ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${transaction.date.day}.${transaction.date.month}.${transaction.date.year} • ${transaction.category}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ₽',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyRates(BuildContext context, HomeViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.refreshCurrencyRates,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100, width: 1),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.currency_exchange, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text('Курсы валют (ЦБ РФ)', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCurrencyItem('USD', viewModel.currencyRates['USD'] ?? 0.0, Colors.green),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildCurrencyItem('EUR', viewModel.currencyRates['EUR'] ?? 0.0, Colors.blue),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Нажмите для обновления',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyItem(String currency, double rate, Color color) {
    return Column(
      children: [
        Text(currency, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('${rate.toStringAsFixed(2)} ₽',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text('1 $currency', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildAllTransactionsButton(BuildContext context, HomeViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAllTransactions(context, viewModel),
        icon: const Icon(Icons.list_alt),
        label: const Text('ВСЕ ТРАНЗАКЦИИ'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showAdjustBalanceDialog(BuildContext context, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AdjustBalanceDialog(
        currentBalance: viewModel.balance,
        onSave: (newBalance, reason) {
          viewModel.adjustBalance(newBalance, reason);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Баланс успешно обновлен'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _navigateToAddTransaction(BuildContext context, HomeViewModel viewModel, bool isIncome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          onSave: viewModel.addTransaction,
          initialIsIncome: isIncome,
        ),
      ),
    );
  }

  void _navigateToAllTransactions(BuildContext context, HomeViewModel viewModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionsScreen(
          initialTransactions: viewModel.transactions,
          onDeleteTransaction: viewModel.deleteTransaction,
        ),
      ),
    );
  }
}