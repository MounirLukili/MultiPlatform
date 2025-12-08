import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceContactInfo extends StatelessWidget {
  final String description;
  final String? phoneNumber;
  final String? website;
  final bool isLoading;
  final bool isOpenNow;

  const PlaceContactInfo({
    super.key,
    required this.description,
    this.phoneNumber,
    this.website,
    required this.isLoading,
    required this.isOpenNow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLoading && isOpenNow)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: const Text("OUVERT ACTUELLEMENT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

        const Divider(),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on, color: Colors.blue),
          title: Text(description),
        ),

        if (isLoading)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
        else ...[
          if (phoneNumber != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(phoneNumber!),
              onTap: () async {
                final Uri url = Uri.parse("tel:$phoneNumber");
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
          if (website != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public, color: Colors.purple),
              title: Text(website!, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
              onTap: () async {
                final Uri url = Uri.parse(website!);
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
        ],
      ],
    );
  }
}