import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';
import '../../data/providers/ad_provider.dart';
import '../widgets/channel_card.dart';
import '../widgets/shimmer_loader.dart';

class CountryChannelsScreen extends ConsumerWidget {
  final String country;

  const CountryChannelsScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(country),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildBody(context, ref),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<ChannelModel>>(
      future: FirebaseFirestore.instance
          .collection('zyvi_channels')
          .where('country', isEqualTo: country)
          .orderBy('name')
          .get()
          .then((snapshot) => snapshot.docs
              .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
              .toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoader();
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Failed to load channels',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }
        final channels = snapshot.data ?? [];
        if (channels.isEmpty) {
          return const Center(
            child: Text(
              'No channels from this country',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: channels.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ChannelCard(
              channel: channel,
              onTap: () {
                if (channel.sources.isEmpty) return;
                final source = channel.sources.first;
                final adManager = ref.read(adManagerProvider);
                adManager.showInterstitialIfAvailable(
                  onDismissed: () {
                    Navigator.pushNamed(context, '/player',
                        arguments: source);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
