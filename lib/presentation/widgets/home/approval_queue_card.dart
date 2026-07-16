import 'package:flutter/material.dart';

/// Parent view: how many tasks are waiting for approval, with a
/// tap-through to the filtered Tasks tab.
class ApprovalQueueCard extends StatelessWidget {
  const ApprovalQueueCard({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text(
          'Needs your approval',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          count == 0
              ? 'Nothing waiting right now 🎉'
              : '$count task${count == 1 ? '' : 's'} waiting',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
