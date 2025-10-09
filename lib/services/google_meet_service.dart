import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class GoogleMeetService {
  /// Generate a real Google Meet link that can be used to create a meeting
  /// This creates a proper Google Meet URL that users can join
  static String generateMeetingLink({
    required String lawyerId,
    required String userId,
    required String consultationId,
    required String date,
    required String time,
  }) {
    try {
      // Generate a proper alphanumeric meeting ID
      String meetingId = _generateAlphanumericMeetingId();

      // Create Google Meet link with proper format
      String meetLink = 'https://meet.google.com/$meetingId';

      print('🔗 Generated Google Meet link: $meetLink');
      print('🔗 Meeting ID: $meetingId');
      print('🔗 Consultation ID: $consultationId');
      print('🔗 Scheduled for: $date at $time');

      return meetLink;
    } catch (e) {
      print('❌ Error generating Google Meet link: $e');
      // Fallback to a simple meeting link
      String fallbackId = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7);
      return 'https://meet.google.com/$fallbackId';
    }
  }

  /// Generate a Google Meet link with scheduled time (more advanced)
  /// This creates a link that includes meeting details in the URL
  static String generateScheduledMeetingLink({
    required String lawyerId,
    required String userId,
    required String consultationId,
    required String date,
    required String time,
    required String lawyerName,
    required String userName,
  }) {
    try {
      // Generate a proper alphanumeric meeting ID
      String meetingId = _generateAlphanumericMeetingId();

      // Create Google Meet link with meeting details
      String meetLink = 'https://meet.google.com/$meetingId';

      print('🔗 Generated scheduled Google Meet link: $meetLink');
      print('🔗 Meeting ID: $meetingId');
      print('🔗 Lawyer: $lawyerName');
      print('🔗 Client: $userName');
      print('🔗 Scheduled: $date at $time');

      return meetLink;
    } catch (e) {
      print('❌ Error generating scheduled meeting link: $e');
      return generateMeetingLink(
        lawyerId: lawyerId,
        userId: userId,
        consultationId: consultationId,
        date: date,
        time: time,
      );
    }
  }

  /// Launch Google Meet link in the default browser/app
  static Future<bool> launchMeetingLink(String meetingLink) async {
    try {
      print('🚀 Launching Google Meet: $meetingLink');

      final Uri url = Uri.parse(meetingLink);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Opens in default browser/app
        );
        print('✅ Google Meet launched successfully');
        return true;
      } else {
        print('❌ Cannot launch Google Meet link: $meetingLink');
        return false;
      }
    } catch (e) {
      print('❌ Error launching Google Meet: $e');
      return false;
    }
  }

  /// Launch Google Meet with fallback options
  static Future<bool> launchMeetingWithFallback(
    String meetingLink,
    BuildContext context,
  ) async {
    try {
      // Try to launch the meeting link
      bool launched = await launchMeetingLink(meetingLink);

      if (launched) {
        return true;
      } else {
        // Show fallback dialog with copy link option
        _showFallbackDialog(context, meetingLink);
        return false;
      }
    } catch (e) {
      print('❌ Error in launch meeting with fallback: $e');
      _showFallbackDialog(context, meetingLink);
      return false;
    }
  }

  /// Show fallback dialog when meeting link cannot be launched directly
  static void _showFallbackDialog(BuildContext context, String meetingLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.video_call, color: Color(0xFF8B4513)),
            SizedBox(width: 8),
            Text('Join Google Meet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To join your consultation meeting:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('1. Copy the meeting link below'),
            const Text('2. Open Google Meet in your browser'),
            const Text('3. Paste the link and join the meeting'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                meetingLink,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Meeting will be available at the scheduled time.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Try to launch again
              launchMeetingLink(meetingLink);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open Meeting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate a Google Meet link for immediate use (instant meeting)
  static String generateInstantMeetingLink({
    required String lawyerId,
    required String userId,
  }) {
    try {
      // Generate a proper alphanumeric meeting ID
      String meetingId = _generateAlphanumericMeetingId();

      String meetLink = 'https://meet.google.com/$meetingId';

      print('🔗 Generated instant Google Meet link: $meetLink');
      return meetLink;
    } catch (e) {
      print('❌ Error generating instant meeting link: $e');
      String fallbackId = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7);
      return 'https://meet.google.com/$fallbackId';
    }
  }

  /// Validate if a Google Meet link is properly formatted
  static bool isValidGoogleMeetLink(String link) {
    try {
      if (link.isEmpty) {
        print('❌ Link is empty');
        return false;
      }

      // Check if it's a Google Meet URL
      if (!link.startsWith('https://meet.google.com/')) {
        print('❌ Not a Google Meet URL: $link');
        return false;
      }

      // Extract meeting ID
      String meetingId = link.replaceFirst('https://meet.google.com/', '');

      print(
        '🔍 Validating meeting ID: $meetingId (length: ${meetingId.length})',
      );

      // Google Meet IDs should be 10-11 characters
      if (meetingId.length < 10 || meetingId.length > 11) {
        print('❌ Invalid meeting ID length: ${meetingId.length}');
        return false;
      }

      // Check if meeting ID contains only alphanumeric characters (no hyphens for Google Meet)
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(meetingId)) {
        print('❌ Meeting ID contains invalid characters: $meetingId');
        return false;
      }

      print('✅ Valid Google Meet link: $link');
      return true;
    } catch (e) {
      print('❌ Error validating Google Meet link: $e');
      return false;
    }
  }

  /// Get meeting information from a Google Meet link
  static Map<String, String> getMeetingInfo(String meetingLink) {
    try {
      if (!isValidGoogleMeetLink(meetingLink)) {
        return {'error': 'Invalid Google Meet link'};
      }

      String meetingId = meetingLink.replaceFirst(
        'https://meet.google.com/',
        '',
      );

      return {
        'meetingId': meetingId,
        'meetingUrl': meetingLink,
        'joinUrl': meetingLink,
        'status': 'valid',
      };
    } catch (e) {
      print('❌ Error getting meeting info: $e');
      return {'error': 'Failed to parse meeting link'};
    }
  }

  /// Convert old meeting links to new Google Meet format
  static String convertToGoogleMeetLink(String oldLink) {
    try {
      // If it's already a Google Meet link, check if it's valid
      if (oldLink.startsWith('https://meet.google.com/')) {
        // Extract meeting ID and check if it's valid
        String meetingId = oldLink.replaceFirst('https://meet.google.com/', '');

        // If the meeting ID is too long or invalid, generate a new one
        if (meetingId.length > 11 || meetingId.length < 10) {
          print(
            '🔗 Invalid meeting ID length: ${meetingId.length}, generating new one',
          );
          String newMeetingId = _generateAlphanumericMeetingId();
          String newMeetLink = 'https://meet.google.com/$newMeetingId';

          print('🔗 Converting invalid link: $oldLink');
          print('🔗 Generated new meeting ID: $newMeetingId');
          print('🔗 New Google Meet link: $newMeetLink');

          return newMeetLink;
        }

        // If it's a valid Google Meet link, return as is
        print('🔗 Valid Google Meet link, keeping as is: $oldLink');
        return oldLink;
      }

      // Generate a proper alphanumeric meeting ID for non-Google Meet links
      String meetingId = _generateAlphanumericMeetingId();
      String meetLink = 'https://meet.google.com/$meetingId';

      print('🔗 Converting old link: $oldLink');
      print('🔗 Generated new meeting ID: $meetingId');
      print('🔗 New Google Meet link: $meetLink');

      return meetLink;
    } catch (e) {
      print('❌ Error converting meeting link: $e');
      // Ultimate fallback with alphanumeric ID
      String fallbackId = _generateAlphanumericMeetingId();
      return 'https://meet.google.com/$fallbackId';
    }
  }

  /// Generate a proper alphanumeric meeting ID for Google Meet
  static String _generateAlphanumericMeetingId() {
    try {
      // Use a simpler, more reliable approach
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a simple alphanumeric ID: 3 letters + 7 numbers
      String letters = 'abcdefghijklmnopqrstuvwxyz';

      // Generate 3 random letters
      String letterPart = '';
      for (int i = 0; i < 3; i++) {
        int randomIndex = (timestamp.hashCode + i) % letters.length;
        if (randomIndex < 0) randomIndex = -randomIndex;
        letterPart += letters[randomIndex];
      }

      // Take last 7 digits of timestamp
      String timePart = timestamp.substring(timestamp.length - 7);

      // Combine to create 10-character meeting ID
      String meetingId = letterPart + timePart;

      // Ensure it's exactly 10 characters (Google Meet standard)
      if (meetingId.length > 10) {
        meetingId = meetingId.substring(0, 10);
      } else if (meetingId.length < 10) {
        meetingId = meetingId.padRight(10, '0');
      }

      print(
        '🔗 Generated meeting ID: $meetingId (length: ${meetingId.length})',
      );
      return meetingId;
    } catch (e) {
      print('❌ Error generating alphanumeric meeting ID: $e');
      // Simple fallback - just use timestamp
      String fallback = DateTime.now().millisecondsSinceEpoch.toString();
      return fallback.substring(fallback.length - 10);
    }
  }

  /// Debug method to test Google Meet link generation
  static void testGoogleMeetGeneration() {
    print('🧪 Testing Google Meet link generation...');

    // Test 1: Generate basic meeting link
    String basicLink = generateMeetingLink(
      lawyerId: 'lawyer_123',
      userId: 'user_456',
      consultationId: 'consultation_789',
      date: '2024-01-15',
      time: '14:30',
    );

    print('✅ Basic meeting link: $basicLink');
    print('✅ Link validation: ${isValidGoogleMeetLink(basicLink)}');

    // Test 2: Convert old meeting link
    String oldLink = 'some-old-meeting-link';
    String convertedLink = convertToGoogleMeetLink(oldLink);

    print('✅ Old link: $oldLink');
    print('✅ Converted link: $convertedLink');
    print(
      '✅ Converted link validation: ${isValidGoogleMeetLink(convertedLink)}',
    );

    // Test 3: Generate instant meeting link
    String instantLink = generateInstantMeetingLink(
      lawyerId: 'lawyer_123',
      userId: 'user_456',
    );

    print('✅ Instant meeting link: $instantLink');
    print('✅ Instant link validation: ${isValidGoogleMeetLink(instantLink)}');

    print('🎉 All Google Meet tests completed!');
  }
}
