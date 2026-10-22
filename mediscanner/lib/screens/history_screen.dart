import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/family_profile.dart';
import '../models/medicine_analysis_result.dart';
import '../services/biometric_service.dart';
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

  // Phase 7: Biometric Lock state
  bool _isLocked = false;
  bool _biometricEnabled = false;

  // Phase 7: Family Profiles state
  String _selectedProfileId = 'all';
  List<FamilyProfile> _familyProfiles = FamilyProfile.defaultProfiles;

  @override
  void initState() {
    super.initState();
    _initSecurityAndProfiles();
  }

  Future<void> _initSecurityAndProfiles() async {
    final enabled = await BiometricService.isLockEnabled();
    final profiles = await FamilyProfile.getAllProfiles();

    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _isLocked = enabled; // If biometric lock is enabled, start locked
        _familyProfiles = profiles;
      });
    }

    if (enabled) {
      _unlockWithBiometrics();
    } else {
      _loadHistory();
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final success = await BiometricService.authenticate(
      localizedReason: 'Scan fingerprint or face to view your Medicine Cabinet',
    );
    if (success && mounted) {
      setState(() => _isLocked = false);
      _loadHistory();
    }
  }

  Future<void> _showBiometricSettingsDialog() async {
    final isSupported = await BiometricService.isBiometricsSupported();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        bool current = _biometricEnabled;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.fingerprint_rounded, color: Color(0xFF00696B), size: 26),
                  SizedBox(width: 8),
                  Text('Biometric Security'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ඖෂධ එකතුව ඇඟිලි සලකුණෙන් (Fingerprint) හෝ Face ID මඟින් අගුළු ලා ආරක්ෂා කරන්න.',
                    style: GoogleFonts.notoSansSinhala(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lock Medicine Cabinet', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isSupported ? 'Prompt on opening cabinet' : 'Hardware not detected on device',
                      style: TextStyle(fontSize: 12, color: isSupported ? Colors.grey : Colors.redAccent),
                    ),
                    value: current,
                    activeThumbColor: const Color(0xFF00696B),
                    onChanged: isSupported
                        ? (val) async {
                            if (val) {
                              final verified = await BiometricService.authenticate(
                                localizedReason: 'Verify your biometric to enable app lock',
                              );
                              if (!verified) return;
                            }
                            await BiometricService.setLockEnabled(val);
                            setDialogState(() => current = val);
                            setState(() {
                              _biometricEnabled = val;
                              _isLocked = false;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.getAllMedicines(
      searchQuery: _searchQuery,
      onlyFavorites: _onlyFavorites,
      profileId: _selectedProfileId,
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

  Future<void> _showAddProfileDialog() async {
    final enController = TextEditingController();
    final siController = TextEditingController();
    int selectedColor = 0xFF00897B;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.person_add_rounded, color: Color(0xFF00696B)),
              SizedBox(width: 8),
              Text('Add Family Member'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: enController,
                decoration: const InputDecoration(
                  labelText: 'Name in English (e.g. Sister, Grandfather)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: siController,
                decoration: const InputDecoration(
                  labelText: 'නම සිංහලෙන් (උදා: අක්කා, සීයා)',
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose Color Theme:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  0xFF00897B, // Teal
                  0xFF0288D1, // Blue
                  0xFF7B1FA2, // Purple
                  0xFFE91E63, // Pink
                  0xFFEF6C00, // Orange
                ].map((c) {
                  final isSel = selectedColor == c;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      radius: 14,
                      child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00696B),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final en = enController.text.trim();
                final si = siController.text.trim();
                if (en.isNotEmpty) {
                  final nav = Navigator.of(context);
                  final newProfile = FamilyProfile(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    nameEn: en,
                    nameSi: si.isNotEmpty ? si : en,
                    colorValue: selectedColor,
                    iconCodePoint: Icons.face_rounded.codePoint,
                  );
                  await FamilyProfile.addCustomProfile(newProfile);
                  final refreshed = await FamilyProfile.getAllProfiles();
                  if (mounted) {
                    setState(() {
                      _familyProfiles = refreshed;
                      _selectedProfileId = newProfile.id;
                    });
                    nav.pop();
                    _loadHistory();
                  }
                }
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
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

  void _shareDoctorSummary() {
    if (_historyList.isEmpty) return;

    final assigned = _selectedProfileId == 'all'
        ? 'All Family Members (සමස්ත පවුල)'
        : _familyProfiles.firstWhere(
            (p) => p.id == _selectedProfileId,
            orElse: () => FamilyProfile.defaultProfiles.first,
          ).nameEn;

    final buffer = StringBuffer();
    buffer.writeln('📋 CLINICAL MEDICATION SUMMARY (වෛද්‍ය උපදෙස් සඳහා)');
    buffer.writeln('====================================================');
    buffer.writeln('👤 Patient Profile: $assigned');
    buffer.writeln('📅 Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('💊 Active Medications: ${_historyList.length}');
    buffer.writeln('----------------------------------------------------');

    for (int i = 0; i < _historyList.length; i++) {
      final item = _historyList[i];
      buffer.writeln('\n${i + 1}. ${item.english.brandName} (${item.english.dosageStrength})');
      buffer.writeln('   • Generic: ${item.english.genericName}');
      buffer.writeln('   • Directions: ${item.english.usageInstructions}');
      buffer.writeln('   • සිංහලෙන්: ${item.sinhala.usageInstructions}');
      if (item.expiryDate != null) {
        buffer.writeln('   • Expiry Date: ${item.expiryDate} (${item.isExpired ? "⚠️ EXPIRED" : "Valid"})');
      }
      if (item.remainingPills != null) {
        buffer.writeln('   • Remaining Inventory: ${item.remainingPills} pills left');
      }
      if (item.english.spcGenericAlternative != null && item.english.spcGenericAlternative!.isNotEmpty) {
        buffer.writeln('   • SPC / Osu Sala Generic: ${item.english.spcGenericAlternative}');
      }
      if (item.english.dietaryWarnings.isNotEmpty) {
        buffer.writeln('   • Dietary Caution: ${item.english.dietaryWarnings.join("; ")}');
      }
    }

    buffer.writeln('\n====================================================');
    buffer.writeln('🏥 Prepared for Clinical Consultation via MedScan AI');
    buffer.writeln('⚠️ Disclaimer: Always verify with attending registered medical doctor.');

    Share.share(
      buffer.toString(),
      subject: 'Doctor Medication Summary - $assigned',
    );
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
          // Phase 7: Biometric Security Settings Button
          IconButton(
            icon: Icon(
              _biometricEnabled ? Icons.fingerprint_rounded : Icons.fingerprint_outlined,
              color: _biometricEnabled ? const Color(0xFF00696B) : Colors.grey,
            ),
            tooltip: 'Biometric Lock Settings',
            onPressed: _showBiometricSettingsDialog,
          ),
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
          if (_historyList.isNotEmpty && !_isLocked)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Doctor WhatsApp Summary (වෛද්‍යවරයාට යැවීමට)',
              onPressed: _shareDoctorSummary,
            ),
          if (_historyList.isNotEmpty && !_isLocked)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cabinet',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLocked
          ? _buildLockedScreen(isDark)
          : Column(
              children: [
                // Phase 7: Multi-Member Family Profile Filter Bar
                _buildProfileFilterBar(isDark),

                // Phase 8.3: 1-Tap Doctor WhatsApp Export Bar
                if (_historyList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: _shareDoctorSummary,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.send_to_mobile_rounded, color: Color(0xFF128C7E), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1-Tap Doctor WhatsApp Summary (${_historyList.length} medicines)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF128C7E),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF128C7E), size: 13),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _loadHistory();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search brand or active ingredient (සිංහල/English)...',
                      hintStyle: const TextStyle(fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1B2424) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                                  Icon(
                                    Icons.medication_rounded,
                                    size: 64,
                                    color: isDark ? const Color(0xFF2E3D3D) : const Color(0xFFCCE0E0),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No medicines found for this profile',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF90A1A1) : const Color(0xFF5A6A6A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ස්කෑන් කළ ඖෂධ මෙහි සුරැකෙනු ඇත.',
                                    style: GoogleFonts.notoSansSinhala(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF6B7A7A) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _historyList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _historyList[index];
                                return _buildMedicineCard(item, isDark);
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildLockedScreen(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00696B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 72, color: Color(0xFF00696B)),
            ),
            const SizedBox(height: 24),
            Text(
              'Medicine Cabinet Locked',
              style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'පෞද්ගලික වෛද්‍ය දත්ත ආරක්ෂා කිරීම සඳහා ඇඟිලි සලකුණෙන් අගුළු හැරිය යුතුය.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00696B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _unlockWithBiometrics,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock with Biometrics / විවෘත කරන්න', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFilterBar(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // All Filter Chip
          FilterChip(
            selected: _selectedProfileId == 'all',
            showCheckmark: false,
            avatar: const Icon(Icons.groups_rounded, size: 16),
            label: const Text('All / සියල්ල'),
            selectedColor: const Color(0xFF00696B),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _selectedProfileId == 'all' ? Colors.white : null,
            ),
            onSelected: (val) {
              setState(() => _selectedProfileId = 'all');
              _loadHistory();
            },
          ),
          const SizedBox(width: 8),

          // Family Profile Filter Chips
          ..._familyProfiles.map((p) {
            final isSel = _selectedProfileId == p.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSel,
                showCheckmark: false,
                avatar: Icon(p.icon, size: 16, color: isSel ? Colors.white : p.color),
                label: Text('${p.nameSi} (${p.nameEn})'),
                selectedColor: p.color,
                backgroundColor: p.color.withValues(alpha: 0.08),
                side: BorderSide(color: p.color.withValues(alpha: isSel ? 1 : 0.3)),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : (isDark ? Colors.white : p.color),
                ),
                onSelected: (val) {
                  setState(() => _selectedProfileId = p.id);
                  _loadHistory();
                },
              ),
            );
          }),

          // Add Member Button Chip
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00696B)),
            label: const Text('+ Member'),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00696B)),
            onPressed: _showAddProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineAnalysisResult item, bool isDark) {
    final assignedProfile = _familyProfiles.firstWhere(
      (p) => p.id == item.profileId,
      orElse: () => FamilyProfile.defaultProfiles.first,
    );

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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.english.brandName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF191C1C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Phase 7: Assigned Profile Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: assignedProfile.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(assignedProfile.icon, size: 11, color: assignedProfile.color),
                                const SizedBox(width: 3),
                                Text(
                                  assignedProfile.nameSi,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: assignedProfile.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
}
