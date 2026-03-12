import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/logger_service.dart';
import '../utils/constants.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _logger = LoggerService.instance;
  String _activeFilter = 'all';

  List<LogEntry> get _filteredEntries {
    final entries = _logger.entries.reversed.toList();
    switch (_activeFilter) {
      case 'security':
        return entries.where((e) => e.level == LogLevel.security).toList();
      case 'error':
        return entries.where((e) => e.level == LogLevel.error).toList();
      case 'auth':
        return entries.where((e) => e.category == 'auth').toList();
      case 'backup':
        return entries.where((e) => e.category == 'backup').toList();
      case 'storage':
        return entries.where((e) => e.category == 'storage').toList();
      case 'tamper':
        return entries.where((e) => e.category == 'tamper').toList();
      default:
        return entries;
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.security:
        return const Color(0xFF7C3AED);
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.info:
        return const Color(0xFF3B82F6);
      case LogLevel.debug:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _exportAsText() {
    final buffer = StringBuffer();
    buffer.writeln('SecureAuth Security Logs');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('─' * 80);
    buffer.writeln('');

    for (final entry in _logger.entries) {
      buffer.writeln(entry.toString());
    }

    return buffer.toString();
  }

  Future<void> _handleExport() async {
    try {
      final text = _exportAsText();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/securauth_logs_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(text);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SecureAuth Security Logs',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export logs: $e')),
        );
      }
    }
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text(
          'This will permanently delete all recorded security logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _logger.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All logs cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Logs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _handleExport,
            tooltip: 'Export logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleClear,
            tooltip: 'Clear logs',
          ),
          SizedBox(width: AppConstants.paddingMD),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
              vertical: AppConstants.paddingMD,
            ),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Security', 'security'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Errors', 'error'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Auth', 'auth'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Backup', 'backup'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Storage', 'storage'),
                SizedBox(width: AppConstants.paddingSM),
                _buildFilterChip('Tamper', 'tamper'),
              ],
            ),
          ),
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    return FilterChip(
      label: Text(label),
      selected: _activeFilter == filterValue,
      onSelected: (selected) {
        setState(() {
          _activeFilter = filterValue;
        });
      },
    );
  }

  Widget _buildLogList() {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            SizedBox(height: AppConstants.paddingMD),
            Text(
              'No logs recorded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildLogEntryCard(entries[index]);
      },
    );
  }

  Widget _buildLogEntryCard(LogEntry entry) {
    final levelColor = _getLevelColor(entry.level);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMD),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
        color: Colors.grey.withOpacity(0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusMD),
                bottomLeft: Radius.circular(AppConstants.radiusMD),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(entry.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      SizedBox(width: AppConstants.paddingMD),
                      _buildLevelBadge(entry.level, levelColor),
                      SizedBox(width: AppConstants.paddingSM),
                      _buildCategoryBadge(entry.category),
                    ],
                  ),
                  SizedBox(height: AppConstants.paddingSM),
                  Text(
                    entry.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
                    SizedBox(height: AppConstants.paddingSM),
                    _buildMetadataRow(entry.metadata!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(LogLevel level, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Text(
        category.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildMetadataRow(Map<String, dynamic> metadata) {
    final metadataItems = metadata.entries
        .map(
          (e) => Text(
            '${e.key}: ${e.value}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        )
        .toList();

    return Wrap(
      spacing: AppConstants.paddingSM,
      runSpacing: AppConstants.paddingXS,
      children: metadataItems,
    );
  }
}
