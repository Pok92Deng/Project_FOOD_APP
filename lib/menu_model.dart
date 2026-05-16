class MenuModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int calories;
  final int protein;
  final List<String> suitableForDisease;
  final List<String> suitableForGoal;
  final String authorEmail;

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
    required this.authorEmail,
  });

  factory MenuModel.fromMap(String id, Map<String, dynamic> data) {
    // 🌟 ฟังก์ชันพิเศษ: ตัวช่วยแปลงข้อมูลให้รองรับทั้งของเก่าและของใหม่
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      
      // ถ้าไปเจอข้อมูลเก่า (ที่เป็น String) ให้สับเป็นข้อๆ ด้วยลูกน้ำ
      if (value is String) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      
      // ถ้าเป็นข้อมูลใหม่ (ที่เป็น List อยู่แล้ว) ก็ใช้งานได้เลย
      if (value is List) {
        return List<String>.from(value);
      }
      
      return [];
    }

    return MenuModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      
      // เรียกใช้ฟังก์ชันพิเศษแทนการดึงตรงๆ
      ingredients: parseList(data['ingredients']),
      steps: parseList(data['steps']),
      suitableForDisease: parseList(data['suitableForDisease']),
      suitableForGoal: parseList(data['suitableForGoal']),
      
      calories: int.tryParse(data['calories'].toString()) ?? 0,
      protein: int.tryParse(data['protein'].toString()) ?? 0,
      authorEmail: (data['authorEmail'] ?? 'ไม่ระบุตัวตน').toString(),
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
      'authorEmail': authorEmail,
    };
  }
}