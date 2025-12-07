import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/category.dart';

typedef TransactionCallback = void Function(Transaction transaction);

class AddTransactionScreen extends StatefulWidget {
  final TransactionCallback onSave;
  final bool initialIsIncome;

  const AddTransactionScreen({
    super.key, 
    required this.onSave,
    required this.initialIsIncome,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedCategory();
    });
  }

  void _updateSelectedCategory() {
    final categories = _currentCategories;
    if (categories.isNotEmpty) {
      setState(() {
        _selectedCategory = categories[0].name;
      });
    }
  }

  List<Category> get _currentCategories {
    final viewModel = context.read<HomeViewModel>();
    return viewModel.categoryRepository.getCategories(isIncome: _isIncome);
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните сумму и название'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сумма должна быть больше 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите категорию'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transaction = Transaction.create(
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory!,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : null,
      isIncome: _isIncome,
    );

    widget.onSave(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isIncome 
              ? 'Доход добавлен: +${amount.toStringAsFixed(2)} ₽'
              : 'Расход добавлен: -${amount.toStringAsFixed(2)} ₽',
        ),
        backgroundColor: _isIncome ? Colors.green : Colors.blue,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _currentCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить операцию'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('ДОХОД'),
                        selected: _isIncome,
                        onSelected: (selected) {
                          setState(() {
                            _isIncome = true;
                            _updateSelectedCategory();
                          });
                        },
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: _isIncome ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('РАСХОД'),
                        selected: !_isIncome,
                        onSelected: (selected) {
                          setState(() {
                            _isIncome = false;
                            _updateSelectedCategory();
                          });
                        },
                        selectedColor: Colors.red,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: !_isIncome ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isIncome ? 'Источник дохода' : 'На что потратили',
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
                hintText: _isIncome ? 'Зарплата, подарок...' : 'Продукты, кафе...',
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Сумма',
                prefixIcon: const Icon(Icons.currency_ruble),
                border: const OutlineInputBorder(),
                hintText: '0',
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Категория',
                prefixIcon: const Icon(Icons.category),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category.name,
                  child: Row(
                    children: [
                      Icon(
                        category.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: category.isIncome ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание (необязательно)',
                prefixIcon: const Icon(Icons.description),
                border: const OutlineInputBorder(),
                hintText: 'Дополнительные детали...',
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isIncome ? Colors.green : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isIncome ? 'СОХРАНИТЬ ДОХОД' : 'СОХРАНИТЬ РАСХОД',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isIncome 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isIncome 
                      ? Colors.green.withOpacity(0.3) 
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                    color: _isIncome ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isIncome
                          ? 'Доход увеличит ваш баланс'
                          : 'Расход уменьшит ваш баланс',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isIncome ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
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