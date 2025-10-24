import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import '../../core/models/deal_offer.dart';
import '../../services/deal_negotiation_service.dart';
import '../../widgets/offers/offer_card_widget.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';

class OffersTabScreen extends StatefulWidget {
  const OffersTabScreen({Key? key}) : super(key: key);

  @override
  State<OffersTabScreen> createState() => _OffersTabScreenState();
}

class _OffersTabScreenState extends State<OffersTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DealNegotiationService _dealService = DealNegotiationService();

  List<DealOffer> _allOffers = [];
  bool _isLoading = false;
  StreamSubscription<List<DealOffer>>? _offersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupOffersStream();
  }

  void _setupOffersStream() {
    setState(() {
      _isLoading = true;
    });

    // Cancel existing subscription
    _offersSubscription?.cancel();

    // Stream all offers for current user
    _offersSubscription = _dealService.streamReceivedOffers().listen((offers) {
      if (mounted) {
        debugPrint('📦 Offers stream update: ${offers.length} offers received');
        for (var offer in offers) {
          debugPrint('  - Offer ${offer.id}: status=${offer.status.name}');
        }
        setState(() {
          _allOffers = offers;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error in offers stream: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Set timeout to stop loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Streams will auto-update
    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tab bar for offers
        Container(
          color: const Color(0xFF215C5C),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            tabs: [
              Tab(text: 'offers.new_offers'.tr()),
              Tab(text: 'offers.accepted'.tr()),
              Tab(text: 'Declined/Expired'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOffersList(
                filter: (offer) =>
                    offer.status == DealStatus.pending && !offer.isExpired,
                emptyTitle: 'offers.no_new_offers'.tr(),
                emptyMessage: 'offers.no_new_offers_message'.tr(),
              ),
              _buildOffersList(
                filter: (offer) => offer.status == DealStatus.accepted,
                emptyTitle: 'offers.no_accepted_offers'.tr(),
                emptyMessage: 'offers.no_accepted_offers_message'.tr(),
              ),
              _buildOffersList(
                filter: (offer) =>
                    offer.status == DealStatus.rejected ||
                    offer.status == DealStatus.expired ||
                    (offer.status == DealStatus.pending && offer.isExpired),
                emptyTitle: 'offers.no_rejected_offers'.tr(),
                emptyMessage: 'offers.no_rejected_offers_message'.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersList({
    required bool Function(DealOffer) filter,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    return LiquidRefreshIndicator(
      onRefresh: _handleRefresh,
      child: Builder(
        builder: (context) {
          // Show loading state
          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiquidLoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'common.loading_offers'.tr(),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Apply filter
          final filteredOffers = _allOffers.where(filter).toList();

          // Show empty state
          if (filteredOffers.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                _buildEmptyState(emptyTitle, emptyMessage),
              ],
            );
          }

          // Show offers list
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredOffers.length,
            itemBuilder: (context, index) {
              final offer = filteredOffers[index];
              return OfferCardWidget(
                key: ValueKey('${offer.id}_${offer.status.name}'),
                offer: offer,
                isReceivedOffer: true,
                onOfferUpdated: () {
                  // Refresh will happen automatically via stream
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF215C5C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 60,
                color: Color(0xFF215C5C),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
