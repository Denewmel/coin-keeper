import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _newCategoryController = TextEditingController();
  String _selectedType = 'expense';

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final categories = viewModel.categoryRepository.getCategories(isIncome: _selectedType == 'income');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление категориями'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('РАСХОДЫ'),
                        selected: _selectedType == 'expense',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'expense';
                          });
                        },
                        selectedColor: Colors.red,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('ДОХОДЫ'),
                        selected: _selectedType == 'income',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'income';
                          });
                        },
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Добавить новую категорию',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newCategoryController,
                      decoration: InputDecoration(
                        labelText: 'Название категории',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addNewCategory,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addNewCategory(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedType == 'income'
                          ? 'Категория будет добавлена в доходы'
                          : 'Категория будет добавлена в расходы',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: categories.isEmpty
                  ? const Center(
                      child: Text('Нет категорий'),
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _buildCategoryItem(category, viewModel);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category, HomeViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.isIncome ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            category.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: category.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(category.name),
        subtitle: Text(
          category.name == 'Другое' ? 'Системная категория' : 'Пользовательская категория',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: category.name == 'Другое'
            ? const Icon(Icons.lock, color: Colors.grey)
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(category.id, category.name, category.isIncome, viewModel),
              ),
      ),
    );
  }

  void _addNewCategory() {
    if (_newCategoryController.text.trim().isEmpty) return;

    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    final newCategory = Category.create(
      name: _newCategoryController.text.trim(),
      isIncome: _selectedType == 'income',
      isSystem: false,
    );
    
    viewModel.categoryRepository.addCategory(newCategory);

    _newCategoryController.clear();
    setState(() {});
  }

  void _deleteCategory(String id, String categoryName, bool isIncome, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию'),
        content: Text('Вы уверены, что хотите удалить категорию "$categoryName"? Все транзакции с этой категорией будут переведены в категорию "Другое".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await viewModel.removeCategory(id, categoryName, isIncome);
                // После успешного удаления обновляем экран
                setState(() {});
              } catch (e) {
                // Ошибка уже обработана в ViewModel
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}