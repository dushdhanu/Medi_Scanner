import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine_analysis_result.dart';
import '../services/database_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MedicineAnalysisResult> _historyList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _onlyFavorites = false;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.getAllMedicines(
      searchQuery: _searchQuery,
      onlyFavorites: _onlyFavorites,
    );
    final count = await DatabaseService.getMedicineCount();
    if (mounted) {
      setState(() {
        _historyList = list;
        _totalCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    await DatabaseService.deleteMedicine(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Medicine Cabinet?'),
        content: const Text(
          'Are you sure you want to permanently delete all records from your local phone SQLite database? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.clearAll();
      _loadHistory();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Cabinet (ඖෂධ එකතුව)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.storage_rounded, size: 12, color: Color(0xFF00696B)),
                const SizedBox(width: 4),
                Text(
                  'Local SQLite DB • $_totalCount saved',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF00696B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _onlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _onlyFavorites ? Colors.redAccent : null,
            ),
            tooltip: _onlyFavorites ? 'Show All' : 'Show Favorites Only',
            onPressed: () {
              setState(() => _onlyFavorites = !_onlyFavorites);
              _loadHistory();
            },
          ),
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cabinet',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _loadHistory();
              },
              decoration: InputDecoration(
                hintText: 'Search by brand or active ingredient (සිංහල/English)...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1B2424) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2E3D3D) : const Color(0xFFD6E2E2),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00696B).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.medication_liquid_rounded,
                                size: 48,
                                color: Color(0xFF00696B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching medicine found'
                                  : _onlyFavorites
                                      ? 'No Favorite Medicines Yet'
                                      : 'No Saved Medicines Yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF191C1C),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scan any medicine to store it offline in SQLite.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF6C7C7C),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _historyList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _historyList[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            onDismissed: (_) => _deleteItem(item.id),
                            child: Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF161F20) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF283636) : const Color(0xFFE2EDED),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultScreen(result: item),
                                    ),
                                  );
                                  _loadHistory();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image Thumbnail or Icon
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: (item.imagePath != null && File(item.imagePath!).existsSync())
                                            ? Image.file(
                                                File(item.imagePath!),
                                                width: 58,
                                                height: 58,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 58,
                                                height: 58,
                                                color: const Color(0xFF00696B).withValues(alpha: 0.1),
                                                child: const Icon(
                                                  Icons.medication_rounded,
                                                  color: Color(0xFF00696B),
                                                  size: 28,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Medicine Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.english.brandName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF191C1C),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.sinhala.brandName,
                                              style: GoogleFonts.notoSansSinhala(
                                                fontSize: 12,
                                                color: const Color(0xFF00696B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.english.genericName} • ${item.english.dosageStrength}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF6C7C7C),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),

                                            // Expiry & Pill Inventory Chips
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (item.expiryDate != null && item.expiryDate!.trim().isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: item.isExpired
                                                          ? Colors.red.withValues(alpha: 0.15)
                                                          : ((item.daysUntilExpiry != null && item.daysUntilExpiry! <= 30)
                                                              ? Colors.orange.withValues(alpha: 0.15)
                                                              : const Color(0xFF2E7D32).withValues(alpha: 0.12)),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          item.isExpired
                                                              ? Icons.error_outline_rounded
                                                              : ((item.daysUntilExpiry != null && item.daysUntilExpiry! <= 30)
                                                                  ? Icons.warning_amber_rounded
                                                                  : Icons.event_available_rounded),
                                                          size: 11,
                                                          color: item.isExpired
                                                              ? Colors.redAccent
                                                              : ((item.daysUntilExpiry != null && item.daysUntilExpiry! <= 30)
                                                                  ? Colors.orangeAccent
                                                                  : const Color(0xFF2E7D32)),
                                                        ),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          item.isExpired 
                                                              ? 'Expired (${item.expiryDate})' 
                                                              : 'EXP: ${item.expiryDate}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: item.isExpired
                                                                ? Colors.redAccent
                                                                : ((item.daysUntilExpiry != null && item.daysUntilExpiry! <= 30)
                                                                    ? Colors.orangeAccent
                                                                    : const Color(0xFF2E7D32)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],

                                                if (item.remainingPills != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (item.remainingPills! <= 2)
                                                          ? Colors.red.withValues(alpha: 0.15)
                                                          : const Color(0xFF00696B).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.inventory_2_outlined,
                                                          size: 11,
                                                          color: (item.remainingPills! <= 2) ? Colors.redAccent : const Color(0xFF00696B),
                                                        ),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          '${item.remainingPills} pills',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: (item.remainingPills! <= 2) ? Colors.redAccent : const Color(0xFF00696B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(item.timestamp),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? const Color(0xFF6B7A7A) : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Favorite button
                                      FutureBuilder<bool>(
                                        future: DatabaseService.isFavorite(item.id),
                                        builder: (context, snapshot) {
                                          final isFav = snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isFav ? Colors.redAccent : Colors.grey,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              await DatabaseService.toggleFavorite(item.id, !isFav);
                                              setState(() {});
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
