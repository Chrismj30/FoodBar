class FoodItem {
  final String name;
  final String? brand;
  final String? barcode;
  double quantity;
  final String unit;
  final Map<String, dynamic> nutrientsPer100g;
  final String? ingredients;
  final String? imageUrl;
  final DateTime dateAdded;

  FoodItem({
    required this.name,
    this.brand,
    this.barcode,
    required this.quantity,
    required this.unit,
    required this.nutrientsPer100g,
    this.ingredients,
    this.imageUrl,
    DateTime? dateAdded,
  }) : this.dateAdded = dateAdded ?? DateTime.now();

  Map<String, double> calculateTotalNutrients() {
    final factor = quantity / 100; // Convert to 100g basis
    return {
      'calories': (nutrientsPer100g['calories'] ?? 0) * factor,
      'protein': (nutrientsPer100g['protein'] ?? 0) * factor,
      'carbohydrates': (nutrientsPer100g['carbohydrates'] ?? 0) * factor,
      'fat': (nutrientsPer100g['fat'] ?? 0) * factor,
      'fiber': (nutrientsPer100g['fiber'] ?? 0) * factor,
    };
  }

  void updateQuantity(double newQuantity) {
    quantity = newQuantity;
  }

  // Factory method to create FoodItem from JSON (for Open Food Facts API)
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Extract nutrients safely to handle null values
    final nutrients = json['nutrients'] ?? {};
    
    // Create a standardized nutrients map
    final Map<String, dynamic> standardizedNutrients = {
      'calories': nutrients['calories'] ?? 0,
      'protein': nutrients['protein'] ?? 0,
      'carbohydrates': nutrients['carbohydrates'] ?? 0,
      'fat': nutrients['total_fat'] ?? 0,
      'fiber': nutrients['fiber'] ?? 0,
      'sugar': nutrients['sugars'] ?? 0,
      'sodium': nutrients['sodium'] ?? 0,
      'potassium': nutrients['potassium'] ?? 0,
      'calcium': nutrients['calcium'] ?? 0,
      'vitamin_a': nutrients['vitamin_a'] ?? 0,
      'vitamin_c': nutrients['vitamin_c'] ?? 0,
      'iron': nutrients['iron'] ?? 0,
    };

    DateTime? parsedDate;
    if (json['dateAdded'] != null) {
      try {
        parsedDate = DateTime.parse(json['dateAdded']);
      } catch (e) {
        print('Error parsing date: $e');
        parsedDate = DateTime.now();
      }
    }

    return FoodItem(
      name: json['name'] ?? 'Unknown Product',
      brand: json['brand'],
      barcode: json['barcode'],
      quantity: 100.0, // Default to 100g/ml serving
      unit: json['unit'] ?? 'g',
      nutrientsPer100g: standardizedNutrients,
      ingredients: json['ingredients'],
      imageUrl: json['imageUrl'],
      dateAdded: parsedDate,
    );
  }
}
