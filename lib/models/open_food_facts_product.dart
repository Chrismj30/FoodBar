class OpenFoodFactsProduct {
  final String? barcode;
  final String? productName;
  final String? imageUrl;
  final String? brands;
  final Map<String, dynamic>? nutriments;
  final String? ingredientsText;
  final List<String>? allergens;
  final String? nutritionGrade;
  final Map<String, dynamic>? nutrientLevels;
  final String? ecoscoreGrade;
  final String? novaGroup;
  final List<String>? categories;

  OpenFoodFactsProduct({
    this.barcode,
    this.productName,
    this.imageUrl,
    this.brands,
    this.nutriments,
    this.ingredientsText,
    this.allergens,
    this.nutritionGrade,
    this.nutrientLevels,
    this.ecoscoreGrade,
    this.novaGroup,
    this.categories,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    try {
      final product = json['product'] ?? {};
      
      // Enhanced debug log with product name and code
      final productName = product['product_name'] ?? product['generic_name'] ?? 'Unknown';
      final code = product['code'] ?? 'No code';
      print('Processing product data: $productName (${code})');
      
      // If we receive unexpected data, log more details
      if (product['product_name'] == null) {
        print('Warning: Product has no name. Available keys: ${product.keys.take(5).join(", ")}...');
      }
      
      List<String> extractAllergens(dynamic allergensData) {
        if (allergensData == null) return [];
        if (allergensData is String) {
          return allergensData.split(',').map((e) => e.trim()).toList();
        }
        return [];
      }
      
      List<String> extractCategories(dynamic categoriesData) {
        if (categoriesData == null) return [];
        if (categoriesData is String) {
          return categoriesData.split(',').map((e) => e.trim()).toList();
        }
        return [];
      }

      // Convert any value to String safely
      String? safeString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }
      
      // Get nutriments map safely
      Map<String, dynamic>? getNutriments(dynamic nutriments) {
        if (nutriments == null) return null;
        if (nutriments is Map) {
          // Convert to Map<String, dynamic> if it's not already
          return Map<String, dynamic>.from(nutriments.map((key, value) => 
            MapEntry(key.toString(), value)));
        }
        return null;
      }

      // For debugging: log if we found an image
      if (product['image_url'] != null || product['image_front_url'] != null) {
        print('Product has image: ${product['image_url'] ?? product['image_front_url']}');
      } else {
        print('Warning: No image found for product $productName');
      }

      return OpenFoodFactsProduct(
        barcode: safeString(product['code']),
        productName: safeString(product['product_name']) ?? safeString(product['generic_name']),
        imageUrl: safeString(product['image_url']) ?? safeString(product['image_front_url']),
        brands: safeString(product['brands']),
        nutriments: getNutriments(product['nutriments']),
        ingredientsText: safeString(product['ingredients_text']),
        allergens: extractAllergens(product['allergens']),
        nutritionGrade: safeString(product['nutrition_grade_fr']),
        nutrientLevels: product['nutrient_levels'] is Map ? 
          Map<String, dynamic>.from(product['nutrient_levels']) : null,
        ecoscoreGrade: safeString(product['ecoscore_grade']),
        novaGroup: safeString(product['nova_group']),
        categories: extractCategories(product['categories']),
      );
    } catch (e) {
      print('Error in OpenFoodFactsProduct.fromJson: $e');
      rethrow;  // Rethrow to let the caller handle or log the error
    }
  }

  // Method to convert OpenFoodFactsProduct to FoodItem for compatibility with existing app
  Map<String, dynamic> toFoodItem() {
    final Map<String, dynamic> foodItem = {
      'name': productName ?? 'Unknown Product',
      'brand': brands ?? '',
      'imageUrl': imageUrl ?? '',
      'dateAdded': DateTime.now().toIso8601String(),
      'nutrients': <String, dynamic>{},
      'ingredients': ingredientsText ?? '',
      'barcode': barcode ?? '',
    };

    if (nutriments != null) {
      try {
        // Map key nutrition facts to the existing model
        foodItem['nutrients'] = {
          'calories': _safeNumber(nutriments!['energy-kcal']) ?? (_safeNumber(nutriments!['energy-kj']) != null ? (_safeNumber(nutriments!['energy-kj'])! / 4.184).round() : 0),
          'total_fat': _safeNumber(nutriments!['fat']) ?? 0,
          'saturated_fat': _safeNumber(nutriments!['saturated-fat']) ?? 0,
          'trans_fat': _safeNumber(nutriments!['trans-fat']) ?? 0,
          'cholesterol': _safeNumber(nutriments!['cholesterol']) ?? 0,
          'sodium': _safeNumber(nutriments!['sodium']) ?? (_safeNumber(nutriments!['salt']) != null ? (_safeNumber(nutriments!['salt'])! * 400).round() : 0),
          'carbohydrates': _safeNumber(nutriments!['carbohydrates']) ?? 0,
          'fiber': _safeNumber(nutriments!['fiber']) ?? 0,
          'sugars': _safeNumber(nutriments!['sugars']) ?? 0,
          'protein': _safeNumber(nutriments!['proteins']) ?? 0,
          'potassium': _safeNumber(nutriments!['potassium']) ?? 0,
          'vitamin_a': _safeNumber(nutriments!['vitamin-a']) ?? 0,
          'vitamin_c': _safeNumber(nutriments!['vitamin-c']) ?? 0,
          'calcium': _safeNumber(nutriments!['calcium']) ?? 0,
          'iron': _safeNumber(nutriments!['iron']) ?? 0,
        };
      } catch (e) {
        print('Error converting nutrients: $e');
      }
    }

    return foodItem;
  }
  
  // Helper method to safely convert nutriment values to numbers
  num? _safeNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      try {
        return num.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
} 