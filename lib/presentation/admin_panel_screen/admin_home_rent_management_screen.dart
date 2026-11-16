import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminHomeRentManagementScreen extends StatefulWidget {
  const AdminHomeRentManagementScreen({super.key});

  @override
  State<AdminHomeRentManagementScreen> createState() =>
      _AdminHomeRentManagementScreenState();
}

class _AdminHomeRentManagementScreenState
    extends State<AdminHomeRentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _enquiries = [];
  String _cityFilter = 'ALL';
  List<String> _availableCities = ['ALL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cities = await SupabaseService.instance.getManagedAreas();
      final effectiveCity = SupabaseService.instance.isSuperAdmin
          ? (_cityFilter == 'ALL' ? null : _cityFilter)
          : SupabaseService.instance.currentAdminArea;

      final listings = await SupabaseService.instance.getHomeRentListings(
        city: effectiveCity,
      );
      final enquiries = await SupabaseService.instance.getHomeRentEnquiries();

      if (mounted) {
        setState(() {
          _availableCities = ['ALL', ...cities];
          _listings = listings;
          _enquiries = enquiries;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status, {bool? isAvailable}) async {
    final success = await SupabaseService.instance.updateHomeRentListingStatus(
      listingId: id,
      status: status,
      isAvailable: isAvailable,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Listing updated successfully!' : 'Failed to update listing.'),
          backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
    _loadData();
  }

  Future<void> _deleteListing(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Property Listing?'),
        content: const Text('Are you sure you want to permanently delete this home rental listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.instance.deleteHomeRentListing(id);
      _loadData();
    }
  }

  void _showEnquiryDetails(Map<String, dynamic> enquiry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Tenant Enquiry Details',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tenant Name: ${enquiry['customer_name'] ?? 'Guest'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Phone: ${enquiry['customer_phone'] ?? '-'}'),
            const SizedBox(height: 6),
            Text('Email: ${enquiry['customer_email'] ?? '-'}'),
            const SizedBox(height: 12),
            const Text('Message / Inquiry:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(enquiry['message'] ?? 'Interested in this rental property.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          SupabaseService.instance.isSuperAdmin
              ? 'Home for Rent Management'
              : 'Area Home Rentals (${SupabaseService.instance.currentAdminArea})',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Listings (${_listings.length})'),
            Tab(text: 'Tenant Inquiries (${_enquiries.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListingsTab(),
                _buildEnquiriesTab(),
              ],
            ),
    );
  }

  Widget _buildListingsTab() {
    return Column(
      children: [
        if (SupabaseService.instance.isSuperAdmin) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0288D1)),
                const SizedBox(width: 8),
                const Text('Filter by Area: ', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<String>(
                  value: _cityFilter,
                  items: _availableCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _cityFilter = val);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: _listings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No home rental listings found.',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listings.length,
                  itemBuilder: (ctx, i) {
                    final item = _listings[i];
                    final isAvailable = item['is_available'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                          color: isAvailable ? const Color(0xFFE0E0E0) : Colors.red.shade100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.home_rounded, color: Color(0xFF0288D1), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['bedrooms']} ${item['property_type']} • ₹${item['monthly_rent']}/mo',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['area_locality']}, ${item['city']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvailable ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAvailable ? 'AVAILABLE' : 'DEACTIVATED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isAvailable ? const Color(0xFF2E7D32) : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Owner: ${item['owner_name']} (${item['owner_phone']})',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if ((item['description'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Notes: ${item['description']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  isAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 16,
                                ),
                                label: Text(isAvailable ? 'Deactivate' : 'Activate'),
                                onPressed: () => _updateStatus(
                                  item['id'],
                                  isAvailable ? 'deactivated' : 'approved',
                                  isAvailable: !isAvailable,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () => _deleteListing(item['id']),
                                tooltip: 'Delete Listing',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEnquiriesTab() {
    if (_enquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No tenant inquiries recorded yet.',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enquiries.length,
      itemBuilder: (ctx, i) {
        final enq = _enquiries[i];
        final listing = enq['listing'] as Map<String, dynamic>?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE1F5FE),
              child: Icon(Icons.person_rounded, color: Color(0xFF0288D1)),
            ),
            title: Text(
              enq['customer_name'] ?? 'Interested Tenant',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Phone: ${enq['customer_phone'] ?? '-'}'),
                if (listing != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Property: ${listing['bedrooms']} ${listing['property_type']} in ${listing['city']}',
                    style: const TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showEnquiryDetails(enq),
          ),
        );
      },
    );
  }
}

