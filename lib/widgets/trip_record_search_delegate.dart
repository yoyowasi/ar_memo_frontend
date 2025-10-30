import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ar_memo_frontend/models/trip_record.dart';

class TripRecordSearchDelegate extends SearchDelegate<TripRecord?> {
  TripRecordSearchDelegate(this.records);

  final List<TripRecord> records;

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResultList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResultList();

  Widget _buildResultList() {
    final lowerQuery = query.toLowerCase();
    final filtered = lowerQuery.isEmpty
        ? records
        : records.where((record) {
            final inTitle = record.title.toLowerCase().contains(lowerQuery);
            final inContent = record.content.toLowerCase().contains(lowerQuery);
            final inGroup =
                record.group?.name.toLowerCase().contains(lowerQuery) ?? false;
            return inTitle || inContent || inGroup;
          }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('일치하는 일기가 없습니다.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final record = filtered[index];
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(record.title),
          subtitle: Text(DateFormat('yyyy.MM.dd').format(record.date)),
          onTap: () => close(context, record),
        );
      },
    );
  }
}
