import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:intl/intl.dart';

class TripRecordListScreen extends ConsumerWidget {
  const TripRecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tripRecordsProvider),
          )
        ],
      ),
      body: tripRecordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('첫 여행 기록을 추가해보세요!'));
          }
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(record.title),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(record.date)),
                  trailing: record.group != null
                      ? Chip(
                    label: Text(record.group!.name),
                    backgroundColor: Color(int.parse(record.group!.color.replaceFirst('#', '0xFF'))),
                  )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripRecordScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}