import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/open_food_facts_product.dart';

class FoodFactsService {
  // Use the India database which will be more relevant for local products
  static const String baseUrl = 'https://in.openfoodfacts.org/api/v2';

  // Get product by barcode
  Future<OpenFoodFactsProduct?> getProductByBarcode(String barcode) async {
    try {
      print('Making API request to get product by barcode: $barcode');
      final response = await http.get(
        Uri.parse('$baseUrl/product/$barcode'),
      );

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 1) {
          print('Product found with barcode: $barcode');
          try {
            return OpenFoodFactsProduct.fromJson(jsonData);
          } catch (e) {
            print('Error parsing product data: $e');
            print('Response body: ${response.body.substring(0, 200)}...'); // Show part of the response
            return null;
          }
        } else {
          print('Product not found');
          return null;
        }
      } else {
        print('Error fetching product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching product: $e');
      return null;
    }
  }

  // Search products by name or description using the India database
  Future<List<OpenFoodFactsProduct>> searchProducts(String query) async {
    try {
      print('Making API request to search products: $query');
      final lowerQuery = query.toLowerCase();
      
      // Use direct search URL format for the Indian database which often works better
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://in.openfoodfacts.org/cgi/search.pl?search_terms=$encodedQuery&json=1&page_size=50';
      
      print('Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FoodScan App - Flutter - Version 1.0',
        },
      );

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<OpenFoodFactsProduct> products = [];

        if (jsonData['products'] != null && jsonData['products'] is List) {
          final List rawProducts = jsonData['products'] as List;
          print('Found ${rawProducts.length} products from Indian database');
          
          // Log first product structure for debugging
          if (rawProducts.isNotEmpty) {
            print('First product sample structure: ${json.encode(rawProducts[0]).substring(0, 200)}...');
          }
          
          // Score products based on relevance
          List<Map<String, dynamic>> scoredProducts = [];
          
          for (var product in rawProducts) {
            try {
              String productName = (product['product_name'] ?? '').toString().toLowerCase();
              String brandName = (product['brands'] ?? '').toString().toLowerCase();
              
              // Skip products without a name
              if (productName.isEmpty) continue;
              
              // Calculate relevance score
              int relevanceScore = 0;
              
              // Exact matches in product name get highest score
              if (productName == lowerQuery) {
                relevanceScore += 100;
              }
              // Product name contains the query term
              else if (productName.contains(lowerQuery)) {
                relevanceScore += 50;
              }
              
              // Brand matches exactly (e.g., "Lay's")
              if (brandName == lowerQuery) {
                relevanceScore += 75;
              }
              // Brand contains the query
              else if (brandName.contains(lowerQuery)) {
                relevanceScore += 40;
              }
              
              // Boost score for complete products (with images, etc.)
              if (product['image_url'] != null) {
                relevanceScore += 10;
              }
              
              // Only include products with a minimum relevance score
              if (relevanceScore > 0) {
                scoredProducts.add({
                  'product': product,
                  'score': relevanceScore
                });
              }
            } catch (e) {
              print('Error scoring product: $e');
              continue;
            }
          }
          
          print('Found ${scoredProducts.length} relevant products after filtering');
          
          // Sort products by relevance score (highest first)
          scoredProducts.sort((a, b) => b['score'].compareTo(a['score']));
          
          // Convert top scored products to OpenFoodFactsProduct objects
          for (var scoredProduct in scoredProducts) {
            try {
              final product = OpenFoodFactsProduct.fromJson({'product': scoredProduct['product']});
              products.add(product);
              print('Added product: ${product.productName} (${product.barcode}) - Score: ${scoredProduct['score']}');
            } catch (e) {
              print('Error parsing product: $e');
              continue;
            }
          }
          
          // If we still have no results, try using broader criteria
          if (products.isEmpty && rawProducts.isNotEmpty) {
            print('No relevant products found, trying broader criteria');
            for (var product in rawProducts) {
              if (product['product_name'] != null) {
                try {
                  final offProduct = OpenFoodFactsProduct.fromJson({'product': product});
                  products.add(offProduct);
                  print('Added product using broader criteria: ${offProduct.productName}');
                  
                  // Only add up to 10 products in fallback mode to avoid irrelevant results
                  if (products.length >= 10) break;
                } catch (e) {
                  print('Error parsing product: $e');
                  continue;
                }
              }
            }
          }
        } else {
          print('No products array found in response or empty array');
          print('Response structure: ${jsonData.keys.join(', ')}');
        }

        return products;
      } else {
        print('Error searching products: ${response.statusCode}');
        print('Response body: ${response.body.substring(0, 200)}...');
        return [];
      }
    } catch (e) {
      print('Exception while searching products: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Try searching using alternative search method with India database
  Future<List<OpenFoodFactsProduct>> legacySearchProducts(String query) async {
    try {
      print('Trying alternative search for: $query');
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://in.openfoodfacts.org/brand/$encodedQuery.json';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<OpenFoodFactsProduct> products = [];
        
        if (jsonData['products'] != null && jsonData['products'] is List) {
          final productsList = jsonData['products'] as List;
          print('Found ${productsList.length} products in brand search');
          
          for (var product in productsList) {
            // Make sure product has basic data
            if (product['product_name'] != null) {
              try {
                products.add(OpenFoodFactsProduct.fromJson({'product': product}));
              } catch (e) {
                print('Error parsing legacy product: $e');
                continue;
              }
            }
          }
        }
        return products;
      }
      return [];
    } catch (e) {
      print('Legacy search error: $e');
      return [];
    }
  }

  // Try a third search approach using direct product query
  Future<List<OpenFoodFactsProduct>> searchByDirectQuery(String query) async {
    try {
      print('Trying direct product name search for: $query');
      final encodedQuery = Uri.encodeComponent(query);
      // Use the direct product search endpoint
      final url = 'https://in.openfoodfacts.org/product-name/$encodedQuery.json';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<OpenFoodFactsProduct> products = [];
        
        if (jsonData['products'] != null && jsonData['products'] is List) {
          final productsList = jsonData['products'] as List;
          print('Found ${productsList.length} products in direct name search');
          
          for (var product in productsList) {
            // Make sure product has basic data
            if (product['product_name'] != null) {
              try {
                final p = OpenFoodFactsProduct.fromJson({'product': product});
                products.add(p);
                print('Added direct product: ${p.productName}');
              } catch (e) {
                print('Error parsing direct search product: $e');
                continue;
              }
            }
          }
        }
        return products;
      }
      return [];
    } catch (e) {
      print('Direct search error: $e');
      return [];
    }
  }

  // Get product by scanning label (OCR) - returns closest matches
  Future<List<OpenFoodFactsProduct>> getProductsByLabel(String text) async {
    // This is a simplified approach - extracting key terms from label text
    // and searching with those terms
    final keywords = _extractKeywords(text);
    if (keywords.isEmpty) {
      print('No valid keywords extracted from label text');
      return [];
    }
    
    print('Extracted keywords from label: ${keywords.join(", ")}');
    return searchProducts(keywords.join(' '));
  }

  // Helper method to extract potentially useful keywords from label text
  List<String> _extractKeywords(String text) {
    // Split by common separators
    final words = text.split(RegExp(r'[,;:\s]+'));
    
    // Filter out very short words and numbers-only words
    final filteredWords = words.where((word) {
      return word.length > 3 && !RegExp(r'^\d+$').hasMatch(word);
    }).toList();
    
    // Take up to 5 keywords to keep search precise but not too narrow
    return filteredWords.take(5).toList();
  }
} 