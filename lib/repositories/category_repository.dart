import '../models/category.dart';
import '../services/storage_service.dart';

class CategoryRepository {
  List<Category> _categories = [];

  Future<void> loadCategories() async {
    try {
      final categoriesData = await StorageService.loadCategories();
      
      if (categoriesData.isEmpty) {
        await _initializeDefaultCategories();
      } else {
        _categories = categoriesData
            .map((data) => Category.fromMap(data))
            .toList();
        
        await _ensureOtherCategoriesExist();
      }
    } catch (e) {
      print('Ошибка загрузки категорий: $e');
      await _initializeDefaultCategories();
    }
  }

  Future<void> _ensureOtherCategoriesExist() async {
    final hasIncomeOther = _categories.any((cat) => cat.name == 'Другое' && cat.isIncome);
    final hasExpenseOther = _categories.any((cat) => cat.name == 'Другое' && !cat.isIncome);
    
    if (!hasIncomeOther) {
      _categories.add(Category.create(name: 'Другое', isIncome: true, isSystem: true));
    }
    
    if (!hasExpenseOther) {
      _categories.add(Category.create(name: 'Другое', isIncome: false, isSystem: true));
    }
    
    await _saveCategories();
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = [
      Category.create(name: 'Зарплата', isIncome: true, isSystem: false),
      Category.create(name: 'Фриланс', isIncome: true, isSystem: false),
      Category.create(name: 'Инвестиции', isIncome: true, isSystem: false),
      Category.create(name: 'Подарок', isIncome: true, isSystem: false),
      Category.create(name: 'Возврат', isIncome: true, isSystem: false),
      Category.create(name: 'Другое', isIncome: true, isSystem: true),
      
      Category.create(name: 'Еда', isIncome: false, isSystem: false),
      Category.create(name: 'Транспорт', isIncome: false, isSystem: false),
      Category.create(name: 'Развлечения', isIncome: false, isSystem: false),
      Category.create(name: 'Покупки', isIncome: false, isSystem: false),
      Category.create(name: 'Коммуналка', isIncome: false, isSystem: false),
      Category.create(name: 'Другое', isIncome: false, isSystem: true),
    ];
    
    _categories = defaultCategories;
    await _saveCategories();
  }

  List<Category> getCategories({bool? isIncome}) {
    if (isIncome == null) {
      return List.from(_categories);
    }
    return _categories.where((cat) => cat.isIncome == isIncome).toList();
  }

  Category? getCategoryByName(String name, bool isIncome) {
    try {
      return _categories.firstWhere(
        (cat) => cat.name == name && cat.isIncome == isIncome,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> addCategory(Category category) async {
    if (!_categoryExists(category.name, category.isIncome)) {
      _categories.add(category);
      await _saveCategories();
    }
  }

  Future<void> removeCategory(String id, bool isIncome) async {
    try {
      final categoryIndex = _categories.indexWhere((cat) => cat.id == id && cat.isIncome == isIncome);
      
      if (categoryIndex != -1) {
        final category = _categories[categoryIndex];
        
        if (category.name != 'Другое') {
          _categories.removeAt(categoryIndex);
          await _saveCategories();
        }
      }
    } catch (e) {
      print('Ошибка удаления категории: $e');
      rethrow;
    }
  }

  bool _categoryExists(String name, bool isIncome) {
    return _categories.any((cat) => 
      cat.name == name && cat.isIncome == isIncome);
  }

  Future<void> _saveCategories() async {
    final categoriesData = _categories.map((c) => c.toMap()).toList();
    await StorageService.saveCategories(categoriesData);
  }

  Category getOtherCategory(bool isIncome) {
    try {
      return _categories.firstWhere(
        (cat) => cat.name == 'Другое' && cat.isIncome == isIncome,
      );
    } catch (e) {
      final otherCategory = Category.create(
        name: 'Другое', 
        isIncome: isIncome, 
        isSystem: true
      );
      _categories.add(otherCategory);
      _saveCategories();
      return otherCategory;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}