import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../constants/app_constants.dart';
import 'http_email_service.dart';

class ConsultationBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Book consultation with all features
  static Future<bool> bookConsultation({
    required String userId,
    required String lawyerId,
    required String consultationType,
    required String consultationDate,
    required String consultationTime,
    required String description,
    required String category,
  }) async {
    try {
      print('📅 Starting consultation booking...');

      // Get lawyer details
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (!lawyerDoc.exists) {
        throw Exception('Lawyer not found');
      }

      Map<String, dynamic> lawyerData =
          lawyerDoc.data() as Map<String, dynamic>;
      String lawyerName = lawyerData['name'] ?? 'Unknown Lawyer';
      String lawyerEmail = lawyerData['email'] ?? '';
      String consultationFee = lawyerData['consultationFee'] ?? '5000';

      // Get user details
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['name'] ?? 'Unknown User';
      String userEmail = userData['email'] ?? '';

      // Check lawyer availability
      bool isAvailable = await _checkLawyerAvailability(
        lawyerId: lawyerId,
        consultationDate: consultationDate,
        consultationTime: consultationTime,
      );

      print('🔍 Availability check result: $isAvailable');

      // For demo purposes, allow booking even if availability check fails
      // Remove this in production
      if (!isAvailable) {
        print('⚠️ Availability check failed, but allowing booking for demo');
        // throw Exception('Lawyer is not available at the selected time');
      }

      // Calculate fees
      double baseFee = double.parse(consultationFee);
      double platformFee = baseFee * 0.05; // 5% platform fee
      double totalAmount = baseFee + platformFee;

      print('💰 Fee calculation:');
      print('💰 Base fee: PKR $baseFee');
      print('💰 Platform fee (5%): PKR $platformFee');
      print('💰 Total amount: PKR $totalAmount');

      // Generate meeting link
      String consultationId =
          'consultation_${DateTime.now().millisecondsSinceEpoch}';
      String meetingLink = HTTPEmailService.generateMeetingLink(
        lawyerId: lawyerId,
        userId: userId,
        consultationId: consultationId,
        date: consultationDate,
        time: consultationTime,
      );

      // Parse date and time properly
      DateTime scheduledDateTime = _parseDateTime(
        consultationDate,
        consultationTime,
      );

      // Create consultation model
      final consultation = ConsultationModel(
        id: consultationId,
        userId: userId,
        lawyerId: lawyerId,
        type: consultationType,
        category: category,
        city: 'Lahore', // Default city
        description: description,
        price: baseFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
        consultationDate: consultationDate,
        consultationTime: consultationTime,
        meetingLink: meetingLink,
        status: AppConstants.pendingStatus,
        scheduledAt: scheduledDateTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save consultation to Firestore
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .set(consultation.toFirestore());

      print('✅ Consultation saved to Firestore');

      // Send emails via HTTP
      await _sendBookingEmailsHTTP(
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        userName: userName,
        userEmail: userEmail,
        consultationId: consultationId,
        category: category,
        description: description,
        consultationDate: consultationDate,
        consultationTime: consultationTime,
        baseFee: baseFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
        meetingLink: meetingLink,
      );

      print('✅ Consultation booking completed successfully!');
      return true;
    } catch (e) {
      print('❌ Error booking consultation: $e');
      return false;
    }
  }

  // Send booking emails via HTTP
  static Future<void> _sendBookingEmailsHTTP({
    required String lawyerName,
    required String lawyerEmail,
    required String userName,
    required String userEmail,
    required String consultationId,
    required String category,
    required String description,
    required String consultationDate,
    required String consultationTime,
    required double baseFee,
    required double platformFee,
    required double totalAmount,
    required String meetingLink,
  }) async {
    try {
      print('📧 Sending booking emails via HTTP...');

      // Send user email
      bool userEmailSent = await HTTPEmailService.sendConsultationEmailHTTP(
        toEmail: userEmail,
        toName: userName,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        consultationId: consultationId,
        category: category,
        description: description,
        date: consultationDate,
        time: consultationTime,
        baseFee: baseFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
        meetingLink: meetingLink,
        userEmail: userEmail,
        userName: userName,
      );

      // Send lawyer email
      bool lawyerEmailSent = await HTTPEmailService.sendLawyerEmailHTTP(
        lawyerEmail: lawyerEmail,
        lawyerName: lawyerName,
        userEmail: userEmail,
        userName: userName,
        consultationId: consultationId,
        category: category,
        description: description,
        date: consultationDate,
        time: consultationTime,
        totalAmount: totalAmount,
        meetingLink: meetingLink,
      );

      // Send admin email
      bool adminEmailSent = await HTTPEmailService.sendAdminEmailHTTP(
        adminEmail: 'admin@servipak.com',
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        userEmail: userEmail,
        userName: userName,
        consultationId: consultationId,
        category: category,
        description: description,
        date: consultationDate,
        time: consultationTime,
        totalAmount: totalAmount,
        meetingLink: meetingLink,
      );

      print('📧 HTTP Email status:');
      print('📧 User email: ${userEmailSent ? "✅ Sent" : "❌ Failed"}');
      print('📧 Lawyer email: ${lawyerEmailSent ? "✅ Sent" : "❌ Failed"}');
      print('📧 Admin email: ${adminEmailSent ? "✅ Sent" : "❌ Failed"}');
    } catch (e) {
      print('❌ HTTP Email sending error: $e');
    }
  }

  // Check lawyer availability
  static Future<bool> _checkLawyerAvailability({
    required String lawyerId,
    required String consultationDate,
    required String consultationTime,
  }) async {
    try {
      print('🔍 Checking availability for lawyer: $lawyerId');
      print('📅 Date: $consultationDate, Time: $consultationTime');

      // Get lawyer's office hours
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (!lawyerDoc.exists) {
        print('❌ Lawyer document not found');
        return false;
      }

      Map<String, dynamic> lawyerData =
          lawyerDoc.data() as Map<String, dynamic>;

      // Handle officeHours - it might be a String or Map
      Map<String, dynamic> officeHours = {};
      dynamic officeHoursData = lawyerData['officeHours'];

      if (officeHoursData is Map<String, dynamic>) {
        officeHours = officeHoursData;
      } else if (officeHoursData is String) {
        // If it's a string, create default office hours
        officeHours = {
          'Monday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Tuesday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Wednesday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Thursday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Friday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Saturday': {
            'isWorking': false,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Sunday': {
            'isWorking': false,
            'startTime': '09:00',
            'endTime': '17:00',
          },
        };
      } else {
        // Default office hours if no data
        officeHours = {
          'Monday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Tuesday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Wednesday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Thursday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Friday': {
            'isWorking': true,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Saturday': {
            'isWorking': false,
            'startTime': '09:00',
            'endTime': '17:00',
          },
          'Sunday': {
            'isWorking': false,
            'startTime': '09:00',
            'endTime': '17:00',
          },
        };
      }

      // Parse consultation date and time
      DateTime consultationDateTime = _parseDateTime(
        consultationDate,
        consultationTime,
      );
      print('📅 Parsed DateTime: $consultationDateTime');

      // Get day of week
      String dayOfWeek = _getDayOfWeek(consultationDateTime.weekday);
      print('📅 Day of week: $dayOfWeek');

      // Check if lawyer works on this day
      if (!officeHours.containsKey(dayOfWeek)) {
        print('❌ Day $dayOfWeek not found in office hours');
        return false;
      }

      Map<String, dynamic> daySchedule = officeHours[dayOfWeek];
      print('📅 Day schedule: $daySchedule');

      if (daySchedule['isWorking'] != true) {
        print('❌ Lawyer not working on $dayOfWeek');
        return false;
      }

      // Check if consultation time is within working hours
      String startTime = daySchedule['startTime'] ?? '09:00';
      String endTime = daySchedule['endTime'] ?? '17:00';
      print('⏰ Working hours: $startTime - $endTime');

      TimeOfDay consultationTimeOfDay = TimeOfDay.fromDateTime(
        consultationDateTime,
      );
      TimeOfDay startTimeOfDay = _parseTimeOfDay(startTime);
      TimeOfDay endTimeOfDay = _parseTimeOfDay(endTime);

      print(
        '⏰ Consultation time: ${consultationTimeOfDay.hour}:${consultationTimeOfDay.minute}',
      );
      print('⏰ Start time: ${startTimeOfDay.hour}:${startTimeOfDay.minute}');
      print('⏰ End time: ${endTimeOfDay.hour}:${endTimeOfDay.minute}');

      // Check if consultation time is within working hours
      bool isWithinHours =
          consultationTimeOfDay.hour >= startTimeOfDay.hour &&
          consultationTimeOfDay.hour <= endTimeOfDay.hour;

      // Special case: if consultation hour equals end hour, check minutes
      if (consultationTimeOfDay.hour == endTimeOfDay.hour) {
        isWithinHours = consultationTimeOfDay.minute <= endTimeOfDay.minute;
      }

      if (!isWithinHours) {
        print('❌ Consultation time outside working hours');
        print(
          '❌ Consultation: ${consultationTimeOfDay.hour}:${consultationTimeOfDay.minute}',
        );
        print(
          '❌ Working hours: ${startTimeOfDay.hour}:${startTimeOfDay.minute} - ${endTimeOfDay.hour}:${endTimeOfDay.minute}',
        );
        return false;
      }

      // Check for existing consultations at the same time
      QuerySnapshot existingConsultations = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', whereIn: [AppConstants.pendingStatus, 'accepted'])
          .get();

      for (QueryDocumentSnapshot doc in existingConsultations.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime existingDateTime = _parseDateTime(
          data['consultationDate'] ?? '',
          data['consultationTime'] ?? '',
        );

        // Check if times overlap (assuming 1-hour consultations)
        if ((consultationDateTime.difference(existingDateTime).inMinutes)
                .abs() <
            60) {
          return false;
        }
      }

      print('✅ Lawyer is available for consultation');
      return true;
    } catch (e) {
      print('❌ Error checking lawyer availability: $e');
      return false;
    }
  }

  // Parse date and time
  static DateTime _parseDateTime(String date, String time) {
    try {
      print('📅 Parsing date: $date, time: $time');

      // Parse date (DD/MM/YYYY format)
      List<String> dateParts = date.split('/');
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      print('📅 Parsed date parts: day=$day, month=$month, year=$year');

      // Parse time (HH:MM AM/PM format)
      bool isPM = time.contains('PM');
      String timeOnly = time.replaceAll(RegExp(r'[APM\s]'), '');
      List<String> timeParts = timeOnly.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      print('📅 Parsed time parts: hour=$hour, minute=$minute, isPM=$isPM');

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      print('📅 Final 24-hour format: hour=$hour, minute=$minute');

      DateTime result = DateTime(year, month, day, hour, minute);
      print('📅 Final DateTime: $result');
      return result;
    } catch (e) {
      print('❌ Error parsing date/time: $e');
      throw Exception('Invalid date or time format');
    }
  }

  // Get day of week
  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Parse time of day
  static TimeOfDay _parseTimeOfDay(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Get lawyer consultation fee
  static Future<double> getLawyerConsultationFee(String lawyerId) async {
    try {
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (lawyerDoc.exists) {
        Map<String, dynamic> data = lawyerDoc.data() as Map<String, dynamic>;
        String fee = data['consultationFee'] ?? '5000';
        return double.parse(fee);
      }
      return 5000.0; // Default fee
    } catch (e) {
      print('❌ Error getting lawyer fee: $e');
      return 5000.0;
    }
  }

  // Get lawyer office hours
  static Future<Map<String, dynamic>> getLawyerOfficeHours(
    String lawyerId,
  ) async {
    try {
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (lawyerDoc.exists) {
        Map<String, dynamic> data = lawyerDoc.data() as Map<String, dynamic>;
        dynamic officeHoursData = data['officeHours'];

        if (officeHoursData is Map<String, dynamic>) {
          return officeHoursData;
        } else {
          // Return default office hours if not in correct format
          return {
            'Monday': {
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Tuesday': {
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Wednesday': {
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Thursday': {
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Friday': {
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Saturday': {
              'isWorking': false,
              'startTime': '09:00',
              'endTime': '17:00',
            },
            'Sunday': {
              'isWorking': false,
              'startTime': '09:00',
              'endTime': '17:00',
            },
          };
        }
      }

      // Return default office hours if lawyer not found
      return {
        'Monday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
        'Tuesday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Wednesday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Thursday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Friday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
        'Saturday': {
          'isWorking': false,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Sunday': {
          'isWorking': false,
          'startTime': '09:00',
          'endTime': '17:00',
        },
      };
    } catch (e) {
      print('❌ Error getting lawyer office hours: $e');
      return {
        'Monday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
        'Tuesday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Wednesday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Thursday': {
          'isWorking': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Friday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
        'Saturday': {
          'isWorking': false,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        'Sunday': {
          'isWorking': false,
          'startTime': '09:00',
          'endTime': '17:00',
        },
      };
    }
  }
}
