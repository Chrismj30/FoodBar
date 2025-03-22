import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/food_facts_service.dart';
import '../models/open_food_facts_product.dart';
import '../models/food_item.dart';
import '../logic.dart';
import '../utils/custom_colors.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({Key? key}) : super(key: key);

  @override
  _FoodSearchScreenState createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final FoodFactsService _foodFactsService = FoodFactsService();
  final Logic _logic = Logic();
  final TextEditingController _searchController = TextEditingController();
  List<OpenFoodFactsProduct> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _searchResults = []; // Clear previous results
    });

    try {
      print('Searching for products with query: $query');
      
      // Show a temporary message to the user while searching
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for "$query" in Indian product database...'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Try the main search method first
      var results = await _foodFactsService.searchProducts(query);
      
      // If main search fails or returns no results, try the legacy search as fallback
      if (results.isEmpty) {
        print('Main search returned no results, trying alternative search');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trying alternative search method for "$query"...'),
            duration: const Duration(seconds: 2),
          ),
        );
        results = await _foodFactsService.legacySearchProducts(query);
        
        // If second approach also returns no results, try direct product query
        if (results.isEmpty) {
          print('Alternative search returned no results, trying direct product query');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Searching product name: "$query"...'),
              duration: const Duration(seconds: 2),
            ),
          );
          results = await _foodFactsService.searchByDirectQuery(query);
        }
      }
      
      print('Final search results: ${results.length} products found');
      
      if (results.isNotEmpty) {
        // Log the first product for debugging
        print('First product: ${results[0].productName}, Barcode: ${results[0].barcode}');
      }
      
      // Filter out products with null names for extra safety
      results = results.where((product) => product.productName != null).toList();
      
      // Check if state is still mounted before updating it
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = 'No products found matching "$query". Try a different search term or check your network connection.';
            
            // Show more helpful message in a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No results found for "$query". Try searching using brand names like "Lays", "Maggi", or "Amul".'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: _searchProducts,
                ),
              ),
            );
          } else {
            // Show success message with count of results
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found ${results.length} products matching "${query}"'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error searching products: $e');
      // Check if state is still mounted before updating it
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during search. Please check your network connection and try again.';
          _isLoading = false;
        });
      }
      
      // Show more detailed error in a snackbar for debugging
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _searchProducts,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _addProductToLog(OpenFoodFactsProduct product) {
    try {
      print('Converting product to food item: ${product.productName}');
      // Convert to food item format and add to log
      final foodItemData = product.toFoodItem();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          'Search Food Products',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search input field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter brand or product name (e.g., Maggi, Lays, Amul)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _searchProducts,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _searchProducts(),
            ),
            
            const SizedBox(height: 16),
            
            // Search button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _searchProducts,
              child: const Text('Search Food Database'),
            ),
            
            const SizedBox(height: 20),
            
            // Show loader while searching
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text('Searching products...', 
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
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
              
            // Show search results
            if (!_isLoading && _searchResults.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Found ${_searchResults.length} results',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Theme.of(context).colorScheme.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: const Color(0xFF1E1E1E),
                                          highlightColor: const Color(0xFF2D2D2D),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 60,
                                          height: 60,
                                          color: const Color(0xFF2D2D2D),
                                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0xFF2D2D2D),
                                      child: const Icon(Icons.no_food, color: Colors.grey),
                                    ),
                              title: Text(
                                product.productName ?? 'Unknown Product',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.brands != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        product.brands!,
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                    ),
                                  if (product.nutriments != null && product.nutriments!.containsKey('energy-kcal'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '${product.nutriments!['energy-kcal']} kcal per 100g',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF2DCCA7), size: 36),
                                onPressed: () => _addProductToLog(product),
                              ),
                              onTap: () {
                                // Show more details if needed
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
              else if (_hasSearched && !_isLoading && _searchResults.isEmpty && _errorMessage.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'No products found. Try a different search term.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
} 