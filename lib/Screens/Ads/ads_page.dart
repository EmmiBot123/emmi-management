import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/Ads/AdsProvider.dart';
import '../../Model/Ads/user_ad_model.dart';
import 'add_ad_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../GenericTeamPage.dart';

class AdsPage extends StatelessWidget {
  const AdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Ads"),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Pull to refresh is automatic via Stream")),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: "View Team Members",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GenericTeamPage(
                    role: "ADS",
                    title: "Ads Team",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddAdDialog(),
        ),
        label: const Text("Add Ad"),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: provider.adsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final ads = snapshot.data ?? [];

          if (ads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No ads found. Add a YouTube link to get started."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.thumbnailUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _launchURL(ad.youtubeUrl),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(ad.thumbnailUrl),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 50, color: Colors.white70),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad.title?.isNotEmpty == true
                                      ? ad.title!
                                      : "No Title",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ad.youtubeUrl ?? "",
                                  style: const TextStyle(color: Colors.blue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, ad),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ad?"),
        content: const Text("Are you sure you want to delete this ad?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<AdsProvider>().deleteAd(ad.id!);
              Navigator.pop(context);
            }, // Provider handles deletion
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _launchURL(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
