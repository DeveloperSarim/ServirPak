import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class DebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debug cities collection
  static Future<void> debugCitiesCollection() async {
    try {
      print('🔍 Debugging cities collection...');
      
      // Get all cities without filters
      QuerySnapshot allCities = await _firestore
          .collection(AppConstants.citiesCollection)
          .get();
      
      print('📊 Total cities in collection: ${allCities.docs.length}');
      
      if (allCities.docs.isEmpty) {
        print('❌ No cities found in collection');
        return;
      }
      
      for (var doc in allCities.docs) {
        print('  📍 City: ${doc.data()}');
      }
      
      // Get active cities
      QuerySnapshot activeCities = await _firestore
          .collection(AppConstants.citiesCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('✅ Active cities: ${activeCities.docs.length}');
      
    } catch (e) {
      print('❌ Error debugging cities: $e');
    }
  }

  // Force seed cities
  static Future<void> forceSeedCities() async {
    try {
      print('🌱 Force seeding cities...');
      
      // Clear existing cities first
      QuerySnapshot existing = await _firestore
          .collection(AppConstants.citiesCollection)
          .get();
      
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }
      
      print('🗑️ Cleared ${existing.docs.length} existing cities');
      
      // Add cities directly
      List<Map<String, dynamic>> cities = [
        {'name': 'Lahore', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Karachi', 'province': 'Sindh', 'country': 'Pakistan'},
        {'name': 'Islamabad', 'province': 'Federal', 'country': 'Pakistan'},
        {'name': 'Rawalpindi', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Faisalabad', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Multan', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Peshawar', 'province': 'KPK', 'country': 'Pakistan'},
        {'name': 'Quetta', 'province': 'Balochistan', 'country': 'Pakistan'},
        {'name': 'Gujranwala', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Sialkot', 'province': 'Punjab', 'country': 'Pakistan'},
      ];
      
      for (var cityData in cities) {
        await _firestore.collection(AppConstants.citiesCollection).add({
          'name': cityData['name'],
          'province': cityData['province'],
          'country': cityData['country'],
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        print('✅ Added: ${cityData['name']}, ${cityData['province']}');
      }
      
      print('🎉 Force seeding completed!');
      
    } catch (e) {
      print('❌ Error force seeding: $e');
    }
  }
}

