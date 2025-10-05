import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SMTPEmailService {
  // SMTP Configuration - Your actual SMTP settings
  static const String smtpHost = 'smtp.titan.email';
  static const int smtpPort = 587; // Try TLS first
  static const String smtpUsername = 'noreply@sarimtools.com';
  static const String smtpPassword = 'ConnectSarim1@';

  // Send consultation booking email via SMTP
  static Future<bool> sendConsultationEmailSMTP({
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
      print('📧 Sending SMTP email to: $toEmail');

      // Create beautiful HTML email template
      String htmlContent = _createEmailTemplate(
        toName: toName,
        toEmail: toEmail,
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

      // Send via real SMTP
      return await _sendViaSMTP(
        toEmail: toEmail,
        toName: toName,
        htmlContent: htmlContent,
        subject: 'Consultation Booking Confirmation - ServirPak',
      );
    } catch (e) {
      print('❌ SMTP Email error: $e');
      return false;
    }
  }

  // Send via real SMTP
  static Future<bool> _sendViaSMTP({
    required String toEmail,
    required String toName,
    required String htmlContent,
    required String subject,
  }) async {
    try {
      print('📧 SMTP Configuration:');
      print('📧 Host: $smtpHost');
      print('📧 Port: $smtpPort');
      print('📧 Username: $smtpUsername');
      print('📧 To: $toEmail');
      print('📧 Subject: $subject');

      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword,
        allowInsecure: false,
        ssl: false, // Use TLS for port 587
        ignoreBadCertificate: true,
      );

      // Create email message
      final message = Message()
        ..from = Address(smtpUsername, 'ServirPak')
        ..recipients.add(toEmail)
        ..subject = subject
        ..html = htmlContent;

      // Send email
      final sendReport = await send(message, smtpServer);

      print('✅ SMTP Email sent successfully to: $toEmail');
      print('📧 Send Report: ${sendReport.toString()}');

      return true;
    } catch (e) {
      print('❌ SMTP error: $e');

      // Fallback: Try with different SMTP settings
      try {
        print('🔄 Trying fallback SMTP configuration...');

        final fallbackSmtpServer = SmtpServer(
          smtpHost,
          port: 465, // Try SSL port
          username: smtpUsername,
          password: smtpPassword,
          allowInsecure: false,
          ssl: true,
          ignoreBadCertificate: true,
        );

        final message = Message()
          ..from = Address(smtpUsername, 'ServirPak')
          ..recipients.add(toEmail)
          ..subject = subject
          ..html = htmlContent;

        final sendReport = await send(message, fallbackSmtpServer);

        print('✅ Fallback SMTP Email sent successfully to: $toEmail');
        print('📧 Send Report: ${sendReport.toString()}');

        return true;
      } catch (fallbackError) {
        print('❌ Fallback SMTP error: $fallbackError');
        return false;
      }
    }
  }

  // Create beautiful HTML email template
  static String _createEmailTemplate({
    required String toName,
    required String toEmail,
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
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Consultation Booking Confirmation</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f4f4f4;
            }
            .container {
                background-color: #ffffff;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #8B4513 0%, #A0522D 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: bold;
            }
            .header p {
                margin: 10px 0 0 0;
                font-size: 16px;
                opacity: 0.9;
            }
            .content {
                padding: 30px 20px;
            }
            .greeting {
                font-size: 18px;
                margin-bottom: 20px;
                color: #8B4513;
            }
            .info-card {
                background-color: #f8f9fa;
                border-left: 4px solid #8B4513;
                padding: 20px;
                margin: 20px 0;
                border-radius: 5px;
            }
            .info-row {
                display: flex;
                justify-content: space-between;
                margin: 10px 0;
                padding: 8px 0;
                border-bottom: 1px solid #e9ecef;
            }
            .info-row:last-child {
                border-bottom: none;
            }
            .info-label {
                font-weight: bold;
                color: #8B4513;
            }
            .info-value {
                color: #333;
            }
            .meeting-link {
                background-color: #e8f5e8;
                border: 2px solid #28a745;
                border-radius: 8px;
                padding: 20px;
                text-align: center;
                margin: 20px 0;
            }
            .meeting-link a {
                color: #28a745;
                text-decoration: none;
                font-weight: bold;
                font-size: 18px;
            }
            .meeting-link a:hover {
                text-decoration: underline;
            }
            .fee-breakdown {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 8px;
                padding: 20px;
                margin: 20px 0;
            }
            .fee-row {
                display: flex;
                justify-content: space-between;
                margin: 8px 0;
            }
            .fee-total {
                font-weight: bold;
                font-size: 18px;
                color: #8B4513;
                border-top: 2px solid #8B4513;
                padding-top: 10px;
                margin-top: 10px;
            }
            .footer {
                background-color: #8B4513;
                color: white;
                padding: 20px;
                text-align: center;
                font-size: 14px;
            }
            .footer a {
                color: #ffd700;
                text-decoration: none;
            }
            .footer a:hover {
                text-decoration: underline;
            }
            .success-icon {
                color: #28a745;
                font-size: 24px;
                margin-right: 10px;
            }
            @media (max-width: 600px) {
                body {
                    padding: 10px;
                }
                .content {
                    padding: 20px 15px;
                }
                .info-row {
                    flex-direction: column;
                }
                .info-label {
                    margin-bottom: 5px;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Consultation Booked Successfully!</h1>
                <p>Your legal consultation has been confirmed</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    <span class="success-icon">✅</span>
                    Dear $toName,
                </div>
                
                <p>We're excited to confirm your consultation booking with <strong>$lawyerName</strong>. Here are all the details:</p>
                
                <div class="info-card">
                    <h3 style="color: #8B4513; margin-top: 0;">📅 Consultation Details</h3>
                    <div class="info-row">
                        <span class="info-label">Lawyer:</span>
                        <span class="info-value">$lawyerName</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Email:</span>
                        <span class="info-value">$lawyerEmail</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Date:</span>
                        <span class="info-value">$consultationDate</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Time:</span>
                        <span class="info-value">$consultationTime</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Type:</span>
                        <span class="info-value">$consultationType</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Client:</span>
                        <span class="info-value">$userName ($userEmail)</span>
                    </div>
                </div>
                
                <div class="meeting-link">
                    <h3 style="color: #28a745; margin-top: 0;">🔗 Meeting Link</h3>
                    <p>Click the link below to join your consultation:</p>
                    <a href="$meetingLink" target="_blank">Join Consultation Meeting</a>
                    <p style="font-size: 12px; margin-top: 10px; color: #666;">
                        Meeting ID: ${meetingLink.split('/').last}
                    </p>
                </div>
                
                <div class="fee-breakdown">
                    <h3 style="color: #8B4513; margin-top: 0;">💰 Fee Breakdown</h3>
                    <div class="fee-row">
                        <span>Consultation Fee:</span>
                        <span>$consultationFee</span>
                    </div>
                    <div class="fee-row">
                        <span>Platform Fee (5%):</span>
                        <span>$platformFee</span>
                    </div>
                    <div class="fee-row fee-total">
                        <span>Total Amount:</span>
                        <span>$totalAmount</span>
                    </div>
                </div>
                
                <div style="background-color: #d1ecf1; border: 1px solid #bee5eb; border-radius: 8px; padding: 20px; margin: 20px 0;">
                    <h3 style="color: #0c5460; margin-top: 0;">📋 Important Notes</h3>
                    <ul style="margin: 0; padding-left: 20px;">
                        <li>Please join the meeting 5 minutes before the scheduled time</li>
                        <li>Ensure you have a stable internet connection</li>
                        <li>Have your legal documents ready for discussion</li>
                        <li>If you need to reschedule, contact us at least 24 hours in advance</li>
                    </ul>
                </div>
                
                <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
                
                <p>Best regards,<br>
                <strong>The ServirPak Team</strong></p>
            </div>
            
            <div class="footer">
                <p>© 2024 ServirPak - Your Trusted Legal Partner</p>
                <p>
                    <a href="mailto:support@servipak.com">support@servipak.com</a> | 
                    <a href="tel:+92-300-0000000">+92-300-0000000</a>
                </p>
                <p style="font-size: 12px; opacity: 0.8;">
                    This email was sent to $toEmail. If you didn't book this consultation, please ignore this email.
                </p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Send email to lawyer
  static Future<bool> sendLawyerEmailSMTP({
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
    return await sendConsultationEmailSMTP(
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
  static Future<bool> sendAdminEmailSMTP({
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
    return await sendConsultationEmailSMTP(
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

  // Simple email test method
  static Future<bool> sendSimpleTestEmail(String toEmail) async {
    try {
      print('📧 Sending simple test email to: $toEmail');

      final smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword,
        allowInsecure: false,
        ssl: false,
        ignoreBadCertificate: true,
      );

      final message = Message()
        ..from = Address(smtpUsername, 'ServirPak')
        ..recipients.add(toEmail)
        ..subject = 'Test Email - ServirPak'
        ..html = '''
        <h1>Test Email</h1>
        <p>This is a test email from ServirPak.</p>
        <p>If you receive this email, SMTP is working correctly!</p>
        <p>Best regards,<br>ServirPak Team</p>
        ''';

      final sendReport = await send(message, smtpServer);

      print('✅ Simple test email sent successfully to: $toEmail');
      print('📧 Send Report: ${sendReport.toString()}');

      return true;
    } catch (e) {
      print('❌ Simple test email failed: $e');

      // Try fallback configuration
      try {
        print('🔄 Trying fallback configuration for simple test...');

        final fallbackSmtpServer = SmtpServer(
          smtpHost,
          port: 465,
          username: smtpUsername,
          password: smtpPassword,
          allowInsecure: false,
          ssl: true,
          ignoreBadCertificate: true,
        );

        final message = Message()
          ..from = Address(smtpUsername, 'ServirPak')
          ..recipients.add(toEmail)
          ..subject = 'Test Email - ServirPak (Fallback)'
          ..html = '''
          <h1>Test Email (Fallback)</h1>
          <p>This is a test email from ServirPak using fallback configuration.</p>
          <p>If you receive this email, SMTP is working correctly!</p>
          <p>Best regards,<br>ServirPak Team</p>
          ''';

        final sendReport = await send(message, fallbackSmtpServer);

        print('✅ Fallback simple test email sent successfully to: $toEmail');
        print('📧 Send Report: ${sendReport.toString()}');

        return true;
      } catch (fallbackError) {
        print('❌ Fallback simple test email failed: $fallbackError');
        return false;
      }
    }
  }

  // Test SMTP connection
  static Future<bool> testSMTPConnection() async {
    try {
      print('🧪 Testing SMTP connection...');

      final smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword,
        allowInsecure: false,
        ssl: false, // Use TLS for port 587
        ignoreBadCertificate: true,
      );

      // Create a simple test message
      final message = Message()
        ..from = Address(smtpUsername, 'ServirPak Test')
        ..recipients.add('test@example.com')
        ..subject = 'SMTP Test - ServirPak'
        ..html =
            '<h1>SMTP Test Email</h1><p>This is a test email to verify SMTP configuration.</p>';

      // Try to send (this will test connection)
      final sendReport = await send(message, smtpServer);

      print('✅ SMTP Test successful!');
      print('📧 Send Report: ${sendReport.toString()}');

      return true;
    } catch (e) {
      print('❌ SMTP Test failed: $e');
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
}
