import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// One heading + body block in a legal document.
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// A simple scrollable legal/content page (Privacy Policy, Terms, etc.).
class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.title,
    required this.updated,
    required this.sections,
  });

  final String title;
  final String updated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          Text('Last updated: $updated',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          for (final s in sections) ...[
            Text(s.heading, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(s.body, style: text.bodyMedium?.copyWith(height: 1.45)),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft content. These are practical templates for a health/fitness app in
// India — HAVE THEM REVIEWED BY A LAWYER before a public launch, especially the
// handling of health/medical data. Update the contact email as needed.
// ---------------------------------------------------------------------------

const String _contactEmail = 'dayjoyit@gmail.com';

const String _privacyUpdated = '1 August 2026';

const List<LegalSection> kPrivacyPolicy = [
  LegalSection(
    'Introduction',
    'Dayjoy Fit90 ("we", "us", "our") runs a 90-day health and weight-transformation programme. This Privacy Policy explains what personal information we collect through the app, how we use and protect it, and the choices you have. By using the app you agree to this policy.',
  ),
  LegalSection(
    'Information we collect',
    'Profile details you provide: name, mobile number, email, age, gender, city, and programme identifiers.\n\n'
        'Body & health information: height, weight, waist, activity level, food preference, medical conditions and medical history you choose to share.\n\n'
        'Activity data: daily task completion, meals you log, water intake, steps, points, streaks and progress photos.\n\n'
        'Device & usage data: app version, device type and basic diagnostics needed to run the service.',
  ),
  LegalSection(
    'Sensitive personal / health data',
    'Some information you provide (such as medical conditions and body measurements) is sensitive. We collect it only with your consent, use it solely to deliver and personalise your programme, and share it only with the coach and doctor assigned to your programme. You can decline to provide it, though some features may then be limited.',
  ),
  LegalSection(
    'How we use your information',
    'To create your profile and personalise your plan; to calculate your goals, points and progress; to let your assigned coach and doctor support you; to send reminders and programme announcements; to improve and secure the app; and to meet legal obligations.',
  ),
  LegalSection(
    'How we share information',
    'We share your information with the coach and doctor assigned to your programme, and with trusted service providers (for example, hosting and messaging) who process data on our behalf under confidentiality obligations. We do NOT sell your personal information. We may disclose information if required by law.',
  ),
  LegalSection(
    'Data storage & security',
    'Your data is stored on secured cloud infrastructure. We use reasonable technical and organisational measures to protect it. No method of transmission or storage is completely secure, so we cannot guarantee absolute security.',
  ),
  LegalSection(
    'Your rights',
    'You may request access to, correction of, or deletion of your personal information, and you may withdraw consent for optional data. To make a request, contact us at $_contactEmail. We will respond within a reasonable time.',
  ),
  LegalSection(
    'Data retention',
    'We keep your information for as long as your account is active or as needed to provide the programme, and afterwards only as required for legitimate business or legal purposes. You can ask us to delete your account and associated data.',
  ),
  LegalSection(
    'Children',
    'The programme is intended for adults aged 18 and above. We do not knowingly collect data from children.',
  ),
  LegalSection(
    'Changes to this policy',
    'We may update this policy from time to time. We will update the "Last updated" date above and, where appropriate, notify you in the app.',
  ),
  LegalSection(
    'Contact us',
    'For any privacy questions or requests, email us at $_contactEmail.',
  ),
];

const String _termsUpdated = '1 August 2026';

const List<LegalSection> kTermsOfService = [
  LegalSection(
    'Acceptance of terms',
    'By creating an account or using the Dayjoy Fit90 app, you agree to these Terms of Service. If you do not agree, please do not use the app.',
  ),
  LegalSection(
    'The programme',
    'Dayjoy Fit90 is a 90-day health, fitness and nutrition programme delivered through the app with support from coaches and doctors. Features include daily tasks, meal and water logging, progress tracking, diet plans, reminders and community features.',
  ),
  LegalSection(
    'Not medical advice',
    'Content in the app — including diet plans, calorie estimates and tips — is for general wellness and educational purposes and is not a substitute for professional medical advice, diagnosis or treatment. Always consult a qualified healthcare provider before starting any diet or exercise programme, particularly if you have a medical condition. Results vary from person to person and are not guaranteed.',
  ),
  LegalSection(
    'Eligibility',
    'You must be at least 18 years old and able to form a binding contract to use the app.',
  ),
  LegalSection(
    'Your account & conduct',
    'You are responsible for the accuracy of the information you provide and for activity under your account. Do not misuse the app, upload unlawful or infringing content, or attempt to disrupt the service.',
  ),
  LegalSection(
    'Points & rewards',
    'Points recognise your effort and consistency and have no cash value. Any rewards or recognition for top performers after the 90-day challenge are offered at the sole discretion of Dayjoy management and may change at any time.',
  ),
  LegalSection(
    'Your content & photos',
    'You retain ownership of photos and content you submit. By submitting them you grant us permission to store and use them solely to operate your programme (for example, showing your own progress to you and your assigned coach/doctor). We will not publish your photos publicly without your separate consent.',
  ),
  LegalSection(
    'Intellectual property',
    'The app, its design, content and trademarks (including "Dayjoy Fit90") are owned by us or our licensors and are protected by law. You may not copy or reuse them without permission.',
  ),
  LegalSection(
    'Limitation of liability',
    'To the maximum extent permitted by law, we are not liable for any indirect or consequential loss, or for outcomes arising from your use of the programme. The app is provided on an "as is" basis.',
  ),
  LegalSection(
    'Termination',
    'We may suspend or terminate access if these terms are breached. You may stop using the app and request account deletion at any time.',
  ),
  LegalSection(
    'Governing law',
    'These terms are governed by the laws of India, and disputes are subject to the jurisdiction of the courts at our principal place of business.',
  ),
  LegalSection(
    'Contact us',
    'Questions about these terms? Email us at $_contactEmail.',
  ),
];

/// Convenience builders for the two documents.
LegalPage privacyPolicyPage() => const LegalPage(
      title: 'Privacy Policy',
      updated: _privacyUpdated,
      sections: kPrivacyPolicy,
    );

LegalPage termsOfServicePage() => const LegalPage(
      title: 'Terms of Service',
      updated: _termsUpdated,
      sections: kTermsOfService,
    );
