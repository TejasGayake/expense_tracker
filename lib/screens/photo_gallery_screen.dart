import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _allAttachments = [];
  List<Map<String, dynamic>> _filteredAttachments = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() => _isLoading = true);
    try {
      final attachments = await _db.getAllAttachments();
      // Also fetch related transaction info for each attachment
      List<Map<String, dynamic>> enriched = [];
      for (var att in attachments) {
        final txnId = att['transactionId'] as String?;
        Map<String, dynamic>? txn;
        if (txnId != null) {
          txn = await _db.getTransactionById(txnId);
        }
        enriched.add({
          ...att,
          'transaction': txn,
        });
      }
      setState(() {
        _allAttachments = enriched;
        _filteredAttachments = enriched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyDateFilter() {
    setState(() {
      _filteredAttachments = _allAttachments.where((att) {
        final createdAt = att['createdAt'] as int?;
        if (createdAt == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
        if (_startDate != null && date.isBefore(_startDate!)) return false;
        if (_endDate != null && date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyDateFilter();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filteredAttachments = _allAttachments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          if (_startDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: _clearFilter,
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredAttachments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _allAttachments.isEmpty
                            ? 'No receipt photos yet'
                            : 'No photos in selected date range',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_startDate != null && _endDate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)} (${_filteredAttachments.length} photos)',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _filteredAttachments.length,
                        itemBuilder: (context, index) {
                          final att = _filteredAttachments[index];
                          final filePath = att['filePath'] as String?;
                          final txn = att['transaction'] as Map<String, dynamic>?;
                          final txnDate = txn != null
                              ? DateTime.fromMillisecondsSinceEpoch(txn['date'] as int)
                              : null;
                          final txnAmount = txn?['amount'] as num?;

                          return GestureDetector(
                            onTap: () => _viewFullScreen(att),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  filePath != null && File(filePath).existsSync()
                                      ? Image.file(
                                          File(filePath),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 32),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported, size: 32),
                                        ),
                                  // Gradient overlay at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (txnDate != null)
                                            Text(
                                              DateFormat('MMM d').format(txnDate),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          if (txnAmount != null)
                                            Text(
                                              '$currency${txnAmount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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

  void _viewFullScreen(Map<String, dynamic> attachment) {
    final filePath = attachment['filePath'] as String?;
    final txn = attachment['transaction'] as Map<String, dynamic>?;
    final caption = attachment['caption'] as String?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoViewer(
          filePath: filePath,
          caption: caption,
          transaction: txn,
        ),
      ),
    );
  }
}

class _FullScreenPhotoViewer extends StatelessWidget {
  final String? filePath;
  final String? caption;
  final Map<String, dynamic>? transaction;

  const _FullScreenPhotoViewer({
    required this.filePath,
    this.caption,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService().currencySymbol;
    final txnDate = transaction != null
        ? DateTime.fromMillisecondsSinceEpoch(transaction!['date'] as int)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          caption ?? 'Receipt Photo',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: filePath != null && File(filePath!).existsSync()
                ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(filePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
                  ),
          ),
          // Transaction info bar
          if (transaction != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction!['description'] ?? 'No description',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$currency${(transaction!['amount'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (txnDate != null)
                        Text(
                          DateFormat('MMM d, yyyy h:mm a').format(txnDate),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                    ],
                  ),
                  if (transaction!['category'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        transaction!['category'] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
