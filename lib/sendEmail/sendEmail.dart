import 'package:url_launcher/url_launcher.dart';


void sendEmail(String email) async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: email,
    query: 'subject=Service Inquiry&body=Hello, I want to ask about your service.',
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    print("Could not launch email app");
  }
}
