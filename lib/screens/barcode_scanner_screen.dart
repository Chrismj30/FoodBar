import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/food_facts_service.dart';
import '../models/open_food_facts_product.dart';
import '../models/food_item.dart';
import '../logic.dart';
import '../utils/custom_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final FoodFactsService _foodFactsService = FoodFactsService();
  final Logic _logic = Logic();
  String _scanBarcode = '';
  OpenFoodFactsProduct? _scannedProduct;
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  // Method to handle camera scanning (for mobile devices)
  Future<void> _scanBarcodeWithCamera() async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = 'Camera scanning is not supported in web browsers. Please use manual entry.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      // Check if scan was cancelled
      if (barcodeScanRes == '-1') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Barcode scanned: $barcodeScanRes');
      setState(() {
        _scanBarcode = barcodeScanRes;
      });

      await _lookupProductByBarcode(barcodeScanRes);
    } on PlatformException catch (e) {
      print('Platform exception during barcode scan: $e');
      setState(() {
        _errorMessage = 'Could not access camera: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      print('Exception during barcode scan: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // Method to handle manual barcode entry
  Future<void> _searchManualBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a barcode number';
      });
      return;
    }

    setState(() {
      _scanBarcode = barcode;
      _isLoading = true;
      _errorMessage = '';
    });

    await _lookupProductByBarcode(barcode);
  }

  // Common method to lookup product data by barcode
  Future<void> _lookupProductByBarcode(String barcode) async {
    try {
      print('Fetching product data for barcode: $barcode');
      final product = await _foodFactsService.getProductByBarcode(barcode);
      print('Product data received: ${product != null ? 'Found' : 'Not found'}');

      setState(() {
        _scannedProduct = product;
        _isLoading = false;
        if (product == null) {
          _errorMessage = 'Product not found. Try a different barcode or search by name.';
        }
      });
    } catch (e) {
      print('Exception during barcode lookup: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _addProductToLog() {
    if (_scannedProduct != null) {
      try {
        print('Converting product to food item format');
        // Convert to food item format and add to log
        final foodItemData = _scannedProduct!.toFoodItem();
        print('Food item data: $foodItemData');
        final foodItem = FoodItem.fromJson(foodItemData);
        print('Adding food item to log: ${foodItem.name}');
        _logic.addFoodItem(foodItem);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to your food log'),
            backgroundColor: Color(0xFF2DCCA7),
          ),
        );

        // Navigate back to home
        Navigator.pop(context);
      } catch (e) {
        print('Error adding product to log: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera scan button (only for mobile)
            if (!kIsWeb)
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text('Scan Barcode with Camera', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _scanBarcodeWithCamera,
              ),
              
            if (!kIsWeb)
              const SizedBox(height: 20),
              
            // Manual entry field
            Card(
              color: Theme.of(context).colorScheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Barcode Manually',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 5000112637922',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.background.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _searchManualBarcode,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _searchManualBarcode(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _searchManualBarcode,
                        child: const Text('Search Product'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb 
                          ? 'Note: Camera scanning is not available in web browsers. Please enter the barcode manually.'
                          : 'Note: Enter the barcode number printed below the barcode on the product package.',
                      style: TextStyle(
                        color: kIsWeb ? Colors.amber : Colors.white70, 
                        fontSize: 12
                      ),
                    ),
                  ],
                ),
              ),
            ),
              
            // Display scan status
            if (_scanBarcode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Text(
                  'Barcode: $_scanBarcode',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              
            // Show loader while fetching
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text('Looking up product details...', 
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Show error message
            if (_errorMessage.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              
            // Show product details if found
            if (_scannedProduct != null && !_isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    color: Theme.of(context).colorScheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          if (_scannedProduct!.imageUrl != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: _scannedProduct!.imageUrl!,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: const Color(0xFF1E1E1E),
                                    highlightColor: const Color(0xFF2D2D2D),
                                    child: Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Product name and brand
                          Text(
                            _scannedProduct!.productName ?? 'Unknown Product',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_scannedProduct!.brands != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _scannedProduct!.brands!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2D2D2D)),
                          const SizedBox(height: 16),
                          
                          // Nutrition facts
                          const Text(
                            'Nutrition Facts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          if (_scannedProduct!.nutriments != null) ...[
                            _buildNutrientRow('Calories', '${_scannedProduct!.nutriments!['energy-kcal'] ?? (_scannedProduct!.nutriments!['energy-kj'] != null ? ((_scannedProduct!.nutriments!['energy-kj'] / 4.184).round()) : 'N/A')}${_scannedProduct!.nutriments!.containsKey('energy-kcal') ? ' kcal' : ' kcal*'}'),
                            _buildNutrientRow('Fat', '${_scannedProduct!.nutriments!['fat'] ?? 'N/A'} g'),
                            _buildNutrientRow('Saturated Fat', '${_scannedProduct!.nutriments!['saturated-fat'] ?? 'N/A'} g'),
                            _buildNutrientRow('Carbohydrates', '${_scannedProduct!.nutriments!['carbohydrates'] ?? 'N/A'} g'),
                            _buildNutrientRow('Sugars', '${_scannedProduct!.nutriments!['sugars'] ?? 'N/A'} g'),
                            _buildNutrientRow('Fiber', '${_scannedProduct!.nutriments!['fiber'] ?? 'N/A'} g'),
                            _buildNutrientRow('Proteins', '${_scannedProduct!.nutriments!['proteins'] ?? 'N/A'} g'),
                            _buildNutrientRow('Salt', '${_scannedProduct!.nutriments!['salt'] ?? 'N/A'} g'),
                          ] else
                            const Text(
                              'No nutrition information available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2D2D2D)),
                          const SizedBox(height: 16),
                          
                          // Ingredients
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            _scannedProduct!.ingredientsText ?? 'No ingredients information available',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          
                          if (_scannedProduct!.allergens != null && _scannedProduct!.allergens!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Allergens',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _scannedProduct!.allergens!.map((allergen) => Chip(
                                label: Text(allergen),
                                backgroundColor: Colors.red.shade800,
                                labelStyle: const TextStyle(color: Colors.white),
                              )).toList(),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Add to log button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _addProductToLog,
                              child: const Text('Add to Food Log'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 