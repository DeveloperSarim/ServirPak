import 'dart:convert';
import 'package:http/http.dart' as http;

class HTTPEmailService {
  // Email service configuration
  static const String emailApiUrl =
      'https://api.emailjs.com/api/v1.0/email/send';
  static const String serviceId = 'service_7vnwlh8';
  static const String templateId = 'template_consultation';
  static const String publicKey = '0gOUB0YfG5R0KJGip';

  // Alternative: Use a custom email API endpoint
  static const String customEmailApiUrl =
      'https://your-custom-api.com/send-email';

  // Send consultation booking email via HTTP API
  static Future<bool> sendConsultationEmailHTTP({
    required String toEmail,
    required String toName,
    required String lawyerName,
    required String lawyerEmail,
    required String consultationId,
    required String category,
    required String description,
    required String date,
    required String time,
    required double baseFee,
    required double platformFee,
    required double totalAmount,
    required String meetingLink,
    required String userEmail,
    required String userName,
  }) async {
    try {
      print('📧 Sending consultation email via HTTP to: $toEmail');
      print('📧 Lawyer: $lawyerName ($lawyerEmail)');
      print('📧 Consultation ID: $consultationId');
      print('📧 Date: $date, Time: $time');
      print('📧 Total Amount: PKR $totalAmount');

      // Create email data
      final emailData = {
        'to_email': toEmail,
        'to_name': toName,
        'lawyer_name': lawyerName,
        'lawyer_email': lawyerEmail,
        'consultation_id': consultationId,
        'category': category,
        'description': description,
        'date': date,
        'time': time,
        'base_fee': baseFee.toString(),
        'platform_fee': platformFee.toString(),
        'total_amount': totalAmount.toString(),
        'meeting_link': meetingLink,
        'user_email': userEmail,
        'user_name': userName,
        'subject': 'Consultation Booking Confirmation - ServirPak',
      };

      // Try custom API first
      bool success = await _sendViaCustomAPI(emailData);

      if (!success) {
        // Fallback to EmailJS
        success = await _sendViaEmailJS(emailData);
      }

      if (success) {
        print('✅ HTTP Email sent successfully to: $toEmail');
        return true;
      } else {
        print('❌ HTTP Email failed for: $toEmail');
        return false;
      }
    } catch (e) {
      print('❌ HTTP Email error: $e');
      return false;
    }
  }

  // Send via custom API endpoint
  static Future<bool> _sendViaCustomAPI(Map<String, dynamic> emailData) async {
    try {
      print('🔄 Trying custom API endpoint...');

      final response = await http.post(
        Uri.parse(customEmailApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your_api_token_here',
        },
        body: jsonEncode({
          'to': emailData['to_email'],
          'subject': emailData['subject'],
          'html': _createEmailTemplate(emailData),
          'from': 'noreply@sarimtools.com',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Custom API email sent successfully');
        return true;
      } else {
        print('❌ Custom API failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Custom API error: $e');
      return false;
    }
  }

  // Send via EmailJS (fallback)
  static Future<bool> _sendViaEmailJS(Map<String, dynamic> emailData) async {
    try {
      print('🔄 Trying EmailJS fallback...');

      final response = await http.post(
        Uri.parse(emailApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': emailData,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ EmailJS email sent successfully');
        return true;
      } else {
        print('❌ EmailJS failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS error: $e');
      return false;
    }
  }

  // Create HTML email template
  static String _createEmailTemplate(Map<String, dynamic> data) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Consultation Booking Confirmation</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #8B4513, #A0522D); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .fee-breakdown { background: #e8f5e8; padding: 15px; border-radius: 8px; margin: 15px 0; }
            .meeting-link { background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 15px 0; text-align: center; }
            .button { display: inline-block; background: #8B4513; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .highlight { color: #8B4513; font-weight: bold; }
            .success { color: #4CAF50; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Consultation Booked Successfully!</h1>
                <p>ServirPak - Your Legal Partner</p>
            </div>
            
            <div class="content">
                <h2>Dear ${data['to_name']},</h2>
                
                <p>Congratulations! Your consultation has been successfully booked with <span class="highlight">${data['lawyer_name']}</span>.</p>
                
                <div class="booking-details">
                    <h3>📋 Booking Details</h3>
                    <p><strong>Consultation ID:</strong> ${data['consultation_id']}</p>
                    <p><strong>Lawyer:</strong> ${data['lawyer_name']}</p>
                    <p><strong>Category:</strong> ${data['category']}</p>
                    <p><strong>Date:</strong> ${data['date']}</p>
                    <p><strong>Time:</strong> ${data['time']}</p>
                    <p><strong>Description:</strong> ${data['description']}</p>
                </div>
                
                <div class="fee-breakdown">
                    <h3>💰 Fee Breakdown</h3>
                    <p><strong>Base Fee:</strong> PKR ${data['base_fee']}</p>
                    <p><strong>Platform Fee (5%):</strong> PKR ${data['platform_fee']}</p>
                    <p><strong>Total Amount:</strong> <span class="highlight">PKR ${data['total_amount']}</span></p>
                </div>
                
                <div class="meeting-link">
                    <h3>🔗 Meeting Link</h3>
                    <p>Your consultation will be conducted via Google Meet:</p>
                    <a href="${data['meeting_link']}" class="button">Join Meeting</a>
                    <p><small>Meeting Link: ${data['meeting_link']}</small></p>
                </div>
                
                <div style="margin: 30px 0;">
                    <h3>📞 Contact Information</h3>
                    <p><strong>Lawyer Email:</strong> ${data['lawyer_email']}</p>
                    <p><strong>Your Email:</strong> ${data['user_email']}</p>
                </div>
                
                <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <h3>⚠️ Important Notes</h3>
                    <ul>
                        <li>Please join the meeting 5 minutes before the scheduled time</li>
                        <li>Ensure you have a stable internet connection</li>
                        <li>Have your questions and documents ready</li>
                        <li>If you need to reschedule, contact the lawyer directly</li>
                    </ul>
                </div>
            </div>
            
            <div class="footer">
                <p>Thank you for choosing ServirPak!</p>
                <p>For support, contact us at support@servipak.com</p>
                <p>© 2024 ServirPak. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Send lawyer email
  static Future<bool> sendLawyerEmailHTTP({
    required String lawyerEmail,
    required String lawyerName,
    required String userEmail,
    required String userName,
    required String consultationId,
    required String category,
    required String description,
    required String date,
    required String time,
    required double totalAmount,
    required String meetingLink,
  }) async {
    return await sendConsultationEmailHTTP(
      toEmail: lawyerEmail,
      toName: lawyerName,
      lawyerName: lawyerName,
      lawyerEmail: lawyerEmail,
      consultationId: consultationId,
      category: category,
      description: description,
      date: date,
      time: time,
      baseFee: totalAmount * 0.95, // 95% of total (before platform fee)
      platformFee: totalAmount * 0.05, // 5% platform fee
      totalAmount: totalAmount,
      meetingLink: meetingLink,
      userEmail: userEmail,
      userName: userName,
    );
  }

  // Send admin email
  static Future<bool> sendAdminEmailHTTP({
    required String adminEmail,
    required String lawyerName,
    required String lawyerEmail,
    required String userEmail,
    required String userName,
    required String consultationId,
    required String category,
    required String description,
    required String date,
    required String time,
    required double totalAmount,
    required String meetingLink,
  }) async {
    return await sendConsultationEmailHTTP(
      toEmail: adminEmail,
      toName: 'Admin',
      lawyerName: lawyerName,
      lawyerEmail: lawyerEmail,
      consultationId: consultationId,
      category: category,
      description: description,
      date: date,
      time: time,
      baseFee: totalAmount * 0.95,
      platformFee: totalAmount * 0.05,
      totalAmount: totalAmount,
      meetingLink: meetingLink,
      userEmail: userEmail,
      userName: userName,
    );
  }

  // Simple email test method
  static Future<bool> sendSimpleTestEmailHTTP(String toEmail) async {
    try {
      print('📧 Sending simple test email via HTTP to: $toEmail');

      final emailData = {
        'to_email': toEmail,
        'to_name': 'Test User',
        'subject': 'Test Email - ServirPak',
        'message': 'This is a test email from ServirPak HTTP service.',
      };

      // Try custom API first
      bool success = await _sendViaCustomAPI(emailData);

      if (!success) {
        // Fallback to EmailJS
        success = await _sendViaEmailJS(emailData);
      }

      if (success) {
        print('✅ Simple HTTP test email sent successfully to: $toEmail');
        return true;
      } else {
        print('❌ Simple HTTP test email failed for: $toEmail');
        return false;
      }
    } catch (e) {
      print('❌ Simple HTTP test email error: $e');
      return false;
    }
  }

  // Generate meeting link (same as before)
  static String generateMeetingLink({
    required String lawyerId,
    required String userId,
    required String consultationId,
    required String date,
    required String time,
  }) {
    // Create a unique meeting ID
    final meetingId =
        'servipak-${lawyerId.substring(0, 4)}-${userId.substring(0, 4)}-${consultationId.substring(0, 4)}';

    // Generate Google Meet link
    return 'https://meet.google.com/$meetingId';
  }
}
