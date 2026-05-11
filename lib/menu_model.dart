class MenuModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final String ingredients;
  final String steps;
  final String calories;
  final String protein;
  final String suitableForDisease;
  final String suitableForGoal;

  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.calories,
    required this.protein,
    required this.suitableForDisease,
    required this.suitableForGoal,
  });

  factory MenuModel.fromMap(String id, Map<String, dynamic> data) {
    return MenuModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      ingredients: (data['ingredients'] ?? '').toString(),
      steps: (data['steps'] ?? '').toString(),
      calories: (data['calories'] ?? '').toString(),
      protein: (data['protein'] ?? '').toString(),
      suitableForDisease: (data['suitableForDisease'] ?? '').toString(),
      suitableForGoal: (data['suitableForGoal'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps,
      'calories': calories,
      'protein': protein,
      'suitableForDisease': suitableForDisease,
      'suitableForGoal': suitableForGoal,
    };
  }
}