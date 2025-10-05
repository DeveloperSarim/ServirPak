import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // EmailJS configuration
  static const String serviceId = 'service_servipak';
  static const String templateId = 'template_consultation';
  static const String publicKey = 'your_emailjs_public_key';
  static const String baseUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Send consultation booking email
  static Future<bool> sendConsultationEmail({
    required String toEmail,
    required String toName,
    required String lawyerName,
    required String lawyerEmail,
    required String consultationDate,
    required String consultationTime,
    required String consultationType,
    required String consultationFee,
    required String platformFee,
    required String totalAmount,
    required String meetingLink,
    required String userEmail,
    required String userName,
  }) async {
    try {
      print('📧 Sending consultation email to: $toEmail');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'lawyer_name': lawyerName,
            'lawyer_email': lawyerEmail,
            'consultation_date': consultationDate,
            'consultation_time': consultationTime,
            'consultation_type': consultationType,
            'consultation_fee': consultationFee,
            'platform_fee': platformFee,
            'total_amount': totalAmount,
            'meeting_link': meetingLink,
            'user_email': userEmail,
            'user_name': userName,
            'booking_date': DateTime.now().toString().split(' ')[0],
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully to: $toEmail');
        return true;
      } else {
        print('❌ Email failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }

  // Send email to lawyer
  static Future<bool> sendLawyerEmail({
    required String lawyerEmail,
    required String lawyerName,
    required String userName,
    required String userEmail,
    required String consultationDate,
    required String consultationTime,
    required String consultationType,
    required String consultationFee,
    required String platformFee,
    required String totalAmount,
    required String meetingLink,
  }) async {
    return await sendConsultationEmail(
      toEmail: lawyerEmail,
      toName: lawyerName,
      lawyerName: lawyerName,
      lawyerEmail: lawyerEmail,
      consultationDate: consultationDate,
      consultationTime: consultationTime,
      consultationType: consultationType,
      consultationFee: consultationFee,
      platformFee: platformFee,
      totalAmount: totalAmount,
      meetingLink: meetingLink,
      userEmail: userEmail,
      userName: userName,
    );
  }

  // Send email to admin
  static Future<bool> sendAdminEmail({
    required String adminEmail,
    required String lawyerName,
    required String lawyerEmail,
    required String userName,
    required String userEmail,
    required String consultationDate,
    required String consultationTime,
    required String consultationType,
    required String consultationFee,
    required String platformFee,
    required String totalAmount,
    required String meetingLink,
  }) async {
    return await sendConsultationEmail(
      toEmail: adminEmail,
      toName: 'Admin',
      lawyerName: lawyerName,
      lawyerEmail: lawyerEmail,
      consultationDate: consultationDate,
      consultationTime: consultationTime,
      consultationType: consultationType,
      consultationFee: consultationFee,
      platformFee: platformFee,
      totalAmount: totalAmount,
      meetingLink: meetingLink,
      userEmail: userEmail,
      userName: userName,
    );
  }

  // Generate meeting link
  static String generateMeetingLink({
    required String lawyerId,
    required String userId,
    required String consultationId,
    required String date,
    required String time,
  }) {
    try {
      // Generate a shorter, valid meeting ID
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String shortLawyerId = lawyerId.replaceAll('_', '').substring(0, 3);
      String shortUserId = userId.replaceAll('_', '').substring(0, 3);

      // Create a valid Google Meet ID (alphanumeric, 10-11 characters)
      String meetingId =
          '${shortLawyerId}${shortUserId}${timestamp.substring(timestamp.length - 4)}';

      // Ensure meeting ID is valid length (10-11 characters)
      if (meetingId.length > 11) {
        meetingId = meetingId.substring(0, 11);
      } else if (meetingId.length < 10) {
        meetingId = meetingId.padRight(10, '0');
      }

      // Create Google Meet link
      String meetLink = 'https://meet.google.com/$meetingId';

      print('🔗 Generated meeting link: $meetLink');
      print('🔗 Meeting ID: $meetingId');

      return meetLink;
    } catch (e) {
      print('❌ Error generating meeting link: $e');
      // Fallback to a simple meeting link
      String fallbackId = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7);
      return 'https://meet.google.com/$fallbackId';
    }
  }

  // Alternative: Use Firebase Functions for email sending
  static Future<bool> sendEmailViaFirebase({
    required String toEmail,
    required String toName,
    required String lawyerName,
    required String lawyerEmail,
    required String consultationDate,
    required String consultationTime,
    required String consultationType,
    required String consultationFee,
    required String platformFee,
    required String totalAmount,
    required String meetingLink,
    required String userEmail,
    required String userName,
  }) async {
    try {
      print('📧 Sending email via Firebase Functions...');

      // Call Firebase Function for email sending
      final response = await http.post(
        Uri.parse('https://your-firebase-project.cloudfunctions.net/sendEmail'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'toEmail': toEmail,
          'toName': toName,
          'lawyerName': lawyerName,
          'lawyerEmail': lawyerEmail,
          'consultationDate': consultationDate,
          'consultationTime': consultationTime,
          'consultationType': consultationType,
          'consultationFee': consultationFee,
          'platformFee': platformFee,
          'totalAmount': totalAmount,
          'meetingLink': meetingLink,
          'userEmail': userEmail,
          'userName': userName,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Firebase email sent successfully');
        return true;
      } else {
        print('❌ Firebase email failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Firebase email error: $e');
      return false;
    }
  }
}
