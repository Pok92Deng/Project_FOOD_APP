class MenuModel {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final num calories;
  final num protein;
  final num carb;       // 🌟 เพิ่มตัวแปรคาร์บ
  final num fat;        // 🌟 เพิ่มตัวแปรไขมัน
  final num sodium;     // 🌟 เพิ่มตัวแปรโซเดียม
  final List<String> suitableForDisease;
  final List<String> suitableForGoal;
  final String authorEmail;
  final String creator;
  final String status;
  
  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.calories,
    required this.protein,
    this.carb = 0,      // กำหนดค่าเริ่มต้นเป็น 0
    this.fat = 0,
    this.sodium = 0,
    required this.suitableForDisease,
    required this.suitableForGoal,
    required this.authorEmail,
    required this.creator,
    required this.status,
  });

  factory MenuModel.fromMap(String id, Map<String, dynamic> map) {
    return MenuModel(
      id: id,
      name: map['name']?.toString() ?? 'ไม่มีชื่อ',
      category: map['category']?.toString() ?? 'ไม่ระบุ',
      imageUrl: map['imageUrl']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      carb: map['carb'] ?? 0,         // 🌟 ดึงข้อมูลคาร์บจาก Firebase
      fat: map['fat'] ?? 0,           // 🌟 ดึงข้อมูลไขมันจาก Firebase
      sodium: map['sodium'] ?? 0,     // 🌟 ดึงข้อมูลโซเดียมจาก Firebase
      suitableForDisease: List<String>.from(map['suitableForDisease'] ?? []),
      suitableForGoal: List<String>.from(map['suitableForGoal'] ?? []),
      authorEmail: map['authorEmail']?.toString() ?? '',
      creator: map['creator']?.toString() ?? '',
      status: map['status']?.toString() ?? 'published',
    );
  }
}