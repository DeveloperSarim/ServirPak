import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';
import '../constants/app_constants.dart';

class CityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active cities
  static Future<List<CityModel>> getActiveCities() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.citiesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => CityModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting cities: $e');
      return [];
    }
  }

  // Get cities by province
  static Future<List<CityModel>> getCitiesByProvince(String province) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.citiesCollection)
          .where('province', isEqualTo: province)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => CityModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting cities by province: $e');
      return [];
    }
  }

  // Get city by ID
  static Future<CityModel?> getCityById(String cityId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.citiesCollection)
          .doc(cityId)
          .get();

      if (doc.exists) {
        return CityModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting city by ID: $e');
      return null;
    }
  }

  // Create new city (Admin only)
  static Future<void> createCity({
    required String name,
    required String province,
    required String country,
  }) async {
    try {
      CityModel city = CityModel(
        id: '', // Will be set by Firestore
        name: name,
        province: province,
        country: country,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.citiesCollection)
          .add(city.toFirestore());

      print('City created successfully: $name');
    } catch (e) {
      print('Error creating city: $e');
      rethrow;
    }
  }

  // Update city (Admin only)
  static Future<void> updateCity({
    required String cityId,
    String? name,
    String? province,
    String? country,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (province != null) updateData['province'] = province;
      if (country != null) updateData['country'] = country;
      if (isActive != null) updateData['isActive'] = isActive;

      await _firestore
          .collection(AppConstants.citiesCollection)
          .doc(cityId)
          .update(updateData);

      print('City updated successfully: $cityId');
    } catch (e) {
      print('Error updating city: $e');
      rethrow;
    }
  }

  // Delete city (Admin only)
  static Future<void> deleteCity(String cityId) async {
    try {
      await _firestore
          .collection(AppConstants.citiesCollection)
          .doc(cityId)
          .delete();

      print('City deleted successfully: $cityId');
    } catch (e) {
      print('Error deleting city: $e');
      rethrow;
    }
  }

  // Seed default cities
  static Future<void> seedDefaultCities() async {
    try {
      print('🌱 Starting city seeding...');
      
      List<Map<String, dynamic>> defaultCities = [
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

      int citiesAdded = 0;
      for (var cityData in defaultCities) {
        try {
          // Check if city already exists
          QuerySnapshot existing = await _firestore
              .collection(AppConstants.citiesCollection)
              .where('name', isEqualTo: cityData['name'])
              .where('province', isEqualTo: cityData['province'])
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection(AppConstants.citiesCollection).add({
              'name': cityData['name'],
              'province': cityData['province'],
              'country': cityData['country'],
              'isActive': true,
              'createdAt': Timestamp.fromDate(DateTime.now()),
            });
            citiesAdded++;
            print('✅ Added city: ${cityData['name']}, ${cityData['province']}');
          } else {
            print('⏭️ City already exists: ${cityData['name']}, ${cityData['province']}');
          }
        } catch (e) {
          print('❌ Error adding city ${cityData['name']}: $e');
        }
      }

      print('✅ City seeding completed. Added $citiesAdded new cities.');
    } catch (e) {
      print('❌ Error seeding default cities: $e');
    }
  }
}
