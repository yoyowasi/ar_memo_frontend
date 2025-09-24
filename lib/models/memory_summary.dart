class MemorySummary {
  final int total;
  final int nearby;
  final int thisMonth;

  const MemorySummary({
    required this.total,
    required this.nearby,
    required this.thisMonth,
  });

  factory MemorySummary.fromJson(Map<String, dynamic> json) {
    return MemorySummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      nearby: (json['nearby'] as num?)?.toInt() ?? 0,
      thisMonth: (json['thisMonth'] as num?)?.toInt() ?? 0,
    );
  }
}
