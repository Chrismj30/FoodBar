import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:read_the_label/logic.dart';
import 'package:read_the_label/screens/barcode_scanner_screen.dart';
import 'package:read_the_label/screens/food_search_screen.dart';
import 'package:rive/rive.dart' as rive;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/custom_colors.dart';

class FoodFeaturesScreen extends StatefulWidget {
  const FoodFeaturesScreen({Key? key}) : super(key: key);

  @override
  _FoodFeaturesScreenState createState() => _FoodFeaturesScreenState();
}

class _FoodFeaturesScreenState extends State<FoodFeaturesScreen> {
  final Logic _logic = Logic();
  rive.RiveAnimationController? _controller;
  bool _isAnimationLoaded = false;
  rive.Artboard? _riveArtboard;

  @override
  void initState() {
    super.initState();
    _loadRiveAnimation();
  }

  void _loadRiveAnimation() {
    rootBundle.load('assets/riveAssets/qr_code_scanner.riv').then(
      (data) {
        final file = rive.RiveFile.import(data);
        final artboard = file.mainArtboard;
        _controller = rive.SimpleAnimation('scan');
        artboard.addController(_controller!);
        setState(() {
          _riveArtboard = artboard;
          _isAnimationLoaded = true;
        });
      },
    ).catchError((error) {
      print('Error loading Rive animation: $error');
      setState(() {
        _isAnimationLoaded = false;
      });
    });
  }

  void _handleImageCapture(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: source);
      
      if (pickedImage != null) {
        // Process the image and update UI
        setState(() {
          // Set image to the logic class
          if (kIsWeb) {
            // Web implementation
            _logic.foodImage = pickedImage;
          } else {
            // Mobile implementation
            _logic.foodImage = File(pickedImage.path);
          }
        });
        
        // Navigate to nutrition label screen or perform label analysis
        // This depends on your app's flow and structure
        print('Image captured: ${pickedImage.name}');
        
        // You might want to navigate to another screen or process the image
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image captured successfully. Ready for analysis.'),
            backgroundColor: Color(0xFF2DCCA7),
          ),
        );
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          'Food Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animation area
              if (_isAnimationLoaded)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: rive.Rive(
                      artboard: _riveArtboard!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Info text
              const Text(
                'Choose a method to add food to your diary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Feature cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Barcode Scanner Feature
                  _buildFeatureCard(
                    title: 'Scan Barcode',
                    description: 'Scan product barcode to look up nutrition facts',
                    iconData: Icons.qr_code_scanner,
                    color: const Color(0xFF2DCCA7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Nutrition Label Scanner Feature
                  _buildFeatureCard(
                    title: 'Scan Label',
                    description: 'Take a photo of nutrition facts label',
                    iconData: Icons.document_scanner,
                    color: const Color(0xFFFF6B6B),
                    onTap: () => _handleImageCapture(ImageSource.camera),
                  ),
                  
                  // Food Search Feature
                  _buildFeatureCard(
                    title: 'Search Food',
                    description: 'Search food database by name',
                    iconData: Icons.search,
                    color: const Color(0xFFFFC857),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodSearchScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Daily Intake Feature
                  _buildFeatureCard(
                    title: 'Daily Intake',
                    description: 'View your daily nutrition summary',
                    iconData: Icons.bar_chart,
                    color: const Color(0xFF29B6F6),
                    onTap: () {
                      Navigator.pop(context); // Return to main screen with daily summary
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Additional options
              Card(
                color: Theme.of(context).colorScheme.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'More Options',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.photo_library, color: Colors.white),
                        title: const Text('Upload from Gallery', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Upload label image from gallery', style: TextStyle(color: Colors.white70)),
                        onTap: () => _handleImageCapture(ImageSource.gallery),
                      ),
                      const Divider(color: Color(0xFF2D2D2D)),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.white),
                        title: const Text('About Open Food Facts', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Learn about the food database', style: TextStyle(color: Colors.white70)),
                        onTap: () => _showAboutDialog(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  iconData,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.cardBackground,
        title: const Text('About Open Food Facts', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Open Food Facts is a free, online and crowdsourced food products database made by everyone, for everyone.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'The database contains information about:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Ingredients, allergens, nutrition facts'),
              _buildBulletPoint('Labels, certifications, awards'),
              _buildBulletPoint('Product categories and characteristics'),
              const SizedBox(height: 16),
              const Text(
                'Data is contributed and verified by users and is available under an open license.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 