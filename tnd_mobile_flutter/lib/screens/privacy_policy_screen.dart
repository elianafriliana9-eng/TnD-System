import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.update, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Last Updated: October 20, 2025',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              'Introduction',
              'Welcome to T&D Audit System. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            // Information We Collect
            _buildSection(
              '1. Information We Collect',
              null,
            ),
            _buildSubSection(
              '1.1 Personal Information',
              'When you use our app, we may collect:\n\n'
              '• Full name\n'
              '• Email address\n'
              '• Phone number\n'
              '• Employee ID\n'
              '• Division/Department information\n'
              '• Profile photo',
            ),
            _buildSubSection(
              '1.2 Audit Data',
              'During audit activities, we collect:\n\n'
              '• Outlet visit records\n'
              '• Checklist responses\n'
              '• Photos and images taken during audits\n'
              '• GPS location data for outlet verification\n'
              '• Visit timestamps\n'
              '• Audit findings and notes',
            ),
            _buildSubSection(
              '1.3 Device Information',
              'We automatically collect certain information:\n\n'
              '• Device model and operating system\n'
              '• App version\n'
              '• IP address\n'
              '• Usage statistics\n'
              '• Crash reports and performance data',
            ),

            // How We Use Information
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information for:\n\n'
              '• Authenticating users and maintaining account security\n'
              '• Facilitating audit activities and data collection\n'
              '• Generating reports and analytics\n'
              '• Improving app functionality and user experience\n'
              '• Communicating important updates and notifications\n'
              '• Complying with legal and regulatory requirements\n'
              '• Troubleshooting technical issues',
            ),

            // Information Sharing
            _buildSection(
              '3. Information Sharing',
              'We do not sell, trade, or rent your personal information. We may share your information only in the following circumstances:\n\n'
              '• With authorized team members within your organization\n'
              '• With system administrators for technical support\n'
              '• When required by law or legal process\n'
              '• To protect our rights and safety\n'
              '• With your explicit consent',
            ),

            // Data Security
            _buildSection(
              '4. Data Security',
              'We implement industry-standard security measures:\n\n'
              '• Encrypted data transmission (HTTPS/SSL)\n'
              '• Secure authentication system\n'
              '• Regular security audits\n'
              '• Access controls and user permissions\n'
              '• Secure cloud storage\n'
              '• Regular data backups\n\n'
              'However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),

            // Data Retention
            _buildSection(
              '5. Data Retention',
              'We retain your personal information for as long as:\n\n'
              '• Your account is active\n'
              '• Required for business purposes\n'
              '• Mandated by legal requirements\n\n'
              'When you delete your account, we will delete or anonymize your personal information within 90 days, except where retention is required by law.',
            ),

            // Your Rights
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Correct inaccurate data\n'
              '• Request deletion of your data\n'
              '• Export your data\n'
              '• Opt-out of certain data collection\n'
              '• Withdraw consent at any time\n\n'
              'To exercise these rights, please contact your system administrator.',
            ),

            // Camera and Storage Permissions
            _buildSection(
              '7. Permissions',
              'Our app requires the following permissions:\n\n'
              '• Camera: To capture audit photos\n'
              '• Storage: To save and access photos\n'
              '• Location: To verify outlet locations\n'
              '• Internet: To sync data with servers\n\n'
              'You can manage these permissions in your device settings.',
            ),

            // Children's Privacy
            _buildSection(
              '8. Children\'s Privacy',
              'Our app is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
            ),

            // Changes to Privacy Policy
            _buildSection(
              '9. Changes to This Policy',
              'We may update this Privacy Policy periodically. We will notify you of any significant changes through:\n\n'
              '• In-app notifications\n'
              '• Email notifications\n'
              '• Update notes in the app\n\n'
              'Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),

            // Contact Information
            _buildSection(
              '10. Contact Us',
              'If you have questions or concerns about this Privacy Policy, please contact:\n\n'
              '📧 Email: tndsrt@gmail.com\n'
              '📞 Phone: +62 822-9997-9713\n'
              '🏢 Address: Tangerang, Banten\n\n'
              'We will respond to your inquiry within 7 business days.',
            ),

            const SizedBox(height: 24),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.grey[600], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is important to us',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'T&D Audit System © 2025',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
