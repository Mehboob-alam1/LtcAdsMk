class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String amount;
  final String status;
  final int createdAt;

  factory TransactionItem.fromWithdrawal({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final created = data['createdAt'];
    return TransactionItem(
      id: id,
      type: 'withdrawal',
      title: data['wallet']?.toString() ?? 'Wallet',
      amount: data['amount']?.toString() ?? '-',
      status: data['status']?.toString() ?? 'pending',
      createdAt: created is num ? created.toInt() : 0,
    );
  }

  factory TransactionItem.fromBoost({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final created = data['createdAt'];
    return TransactionItem(
      id: id,
      type: 'boost',
      title: data['pack']?.toString() ?? 'Boost',
      amount: data['price']?.toString() ?? '-',
      status: data['status']?.toString() ?? 'queued',
      createdAt: created is num ? created.toInt() : 0,
    );
  }
}
