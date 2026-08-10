import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Previous Grocery Lists Screen
/// Shows customer's past grocery orders with edit/reorder functionality
class PreviousGroceryListsScreen extends StatefulWidget {
  const PreviousGroceryListsScreen({super.key});

  @override
  State<PreviousGroceryListsScreen> createState() =>
      _PreviousGroceryListsScreenState();
}

class _PreviousGroceryListsScreenState
    extends State<PreviousGroceryListsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _lists = [];
  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Grocery';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _subcategoryId = args['subcategoryId'] as String? ?? 'grocery';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Grocery';
    }
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final data = await _supabase
          .from('grocery_saved_lists')
          .select()
          .eq('customer_id', userId)
          .eq('shop_subcategory', _subcategoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _lists = (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _accentColor {
    switch (_subcategoryId) {
      case 'vegetables':
        return const Color(0xFF2E7D32);
      default:
        return AppTheme.catGrocery;
    }
  }

  void _openEditList(Map<String, dynamic> list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditGroceryListSheet(
          list: list,
          accentColor: _accentColor,
          subcategoryId: _subcategoryId,
          subcategoryName: _subcategoryName,
          onSaved: _loadLists,
          onReorder: _reorderList,
        ),
      ),
    );
  }

  Future<void> _reorderList(Map<String, dynamic> list) async {
    final items = (list['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (items.isEmpty) {
      _showSnack('This list has no items');
      return;
    }

    // Navigate to checkout with the list items
    Navigator.pushNamed(
      context,
      AppRoutes.shopCheckoutScreen,
      arguments: {
        'providerId': list['provider_id'] ?? '',
        'providerName': 'Grocery Shop',
        'subcategoryId': _subcategoryId,
        'subcategoryName': _subcategoryName,
        'cartItems': items,
        'cartTotal': (list['estimated_total'] as num?)?.toDouble() ?? 0.0,
      },
    );
  }

  Future<void> _deleteList(String listId) async {
    try {
      await _supabase
          .from('grocery_saved_lists')
          .update({'is_active': false})
          .eq('id', listId);
      _loadLists();
      _showSnack('List removed');
    } catch (e) {
      _showSnack('Failed to remove list');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _accentColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Text(
          'Previous $_subcategoryName Lists',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLists,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadLists,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _lists.length,
                itemBuilder: (ctx, i) => _GroceryListCard(
                  list: _lists[i],
                  accentColor: _accentColor,
                  onEdit: () => _openEditList(_lists[i]),
                  onReorder: () => _reorderList(_lists[i]),
                  onDelete: () => _showDeleteDialog(_lists[i]['id'] as String),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 72,
            color: _accentColor.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No Previous Lists',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your previous grocery orders will\nappear here for quick reordering.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String listId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove List',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove this grocery list?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteList(listId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Grocery List Card ──────────────────────────────────────────────────────────
class _GroceryListCard extends StatelessWidget {
  final Map<String, dynamic> list;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onReorder;
  final VoidCallback onDelete;

  const _GroceryListCard({
    required this.list,
    required this.accentColor,
    required this.onEdit,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final items = (list['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final totalItems = list['total_items'] as int? ?? items.length;
    final estimatedTotal = (list['estimated_total'] as num?)?.toDouble() ?? 0.0;
    final listName = list['list_name'] as String? ?? 'Grocery List';
    final createdAt = list['created_at'] as String?;
    final lastOrdered = list['last_ordered_at'] as String?;

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_basket_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF74777F),
                    size: 20,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit List'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalItems item${totalItems != 1 ? 's' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF44474E),
                      ),
                    ),
                    if (estimatedTotal > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      Text(
                        '≈ ₹${estimatedTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Show first 3 items as chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      items
                          .take(3)
                          .map(
                            (item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item['name'] ?? 'Item'} ×${item['quantity'] ?? 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList()
                        ..addAll(
                          items.length > 3
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAED),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${items.length - 3} more',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: const Color(0xFF74777F),
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(
                      'Edit List',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReorder,
                    icon: const Icon(Icons.replay_rounded, size: 15),
                    label: Text(
                      'Reorder',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// ── Edit Grocery List Screen ───────────────────────────────────────────────────
class _EditGroceryListSheet extends StatefulWidget {
  final Map<String, dynamic> list;
  final Color accentColor;
  final String subcategoryId;
  final String subcategoryName;
  final VoidCallback onSaved;
  final Future<void> Function(Map<String, dynamic>) onReorder;

  const _EditGroceryListSheet({
    required this.list,
    required this.accentColor,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.onSaved,
    required this.onReorder,
  });

  @override
  State<_EditGroceryListSheet> createState() => _EditGroceryListSheetState();
}

class _EditGroceryListSheetState extends State<_EditGroceryListSheet> {
  final _supabase = Supabase.instance.client;
  late List<Map<String, dynamic>> _items;
  late TextEditingController _nameCtrl;
  bool _isSaving = false;
  final TextEditingController _newItemCtrl = TextEditingController();
  final TextEditingController _newItemQtyCtrl = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    _items = (widget.list['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _nameCtrl = TextEditingController(
      text: widget.list['list_name'] as String? ?? 'My Grocery List',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newItemCtrl.dispose();
    _newItemQtyCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _newItemCtrl.text.trim();
    if (name.isEmpty) return;
    final qty = int.tryParse(_newItemQtyCtrl.text.trim()) ?? 1;
    setState(() {
      _items.add({'name': name, 'quantity': qty, 'price': 0, 'unit': 'piece'});
      _newItemCtrl.clear();
      _newItemQtyCtrl.text = '1';
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateQty(int index, int qty) {
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() => _items[index] = {..._items[index], 'quantity': qty});
  }

  Future<void> _saveList() async {
    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('grocery_saved_lists')
          .update({
            'list_name': _nameCtrl.text.trim(),
            'items': _items,
            'total_items': _items.length,
          })
          .eq('id', widget.list['id'] as String);

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('List saved successfully'),
            backgroundColor: widget.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save list'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items to your list first')),
      );
      return;
    }
    // Save first, then reorder
    await _saveList();
    if (mounted) {
      await widget.onReorder({...widget.list, 'items': _items});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        title: Text(
          'Edit Grocery List',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveList,
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // List name
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'List Name',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF74777F),
                      ),
                      prefixIcon: Icon(
                        Icons.label_rounded,
                        color: widget.accentColor,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Add new item
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Item',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _newItemCtrl,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Item name...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFFADB5BD),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _newItemQtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFFADB5BD),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _addItem,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items list
                Text(
                  'Items (${_items.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No items yet. Add items above.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final qty = item['quantity'] as int? ?? 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.accentColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      color: widget.accentColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String? ?? 'Item',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A1C1E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item['unit'] != null)
                                          Text(
                                            item['unit'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: const Color(0xFF74777F),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Qty controls
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _updateQty(i, qty - 1),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: widget.accentColor.withAlpha(
                                              20,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove_rounded,
                                            color: widget.accentColor,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '$qty',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: widget.accentColor,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _updateQty(i, qty + 1),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: widget.accentColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeItem(i),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFD32F2F),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < _items.length - 1)
                              const Divider(
                                height: 1,
                                indent: 14,
                                endIndent: 14,
                                color: Color(0xFFE8EAED),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveList,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: Text(
                        'Save List',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _placeOrder,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_cart_rounded, size: 16),
                      label: Text(
                        'Place Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
