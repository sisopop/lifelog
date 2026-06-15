import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  static const _people = [
    ('엄마', '최근 함께한 기록 3개'),
    ('지연', '최근 기록 2개'),
    ('민수', '함께한 기록 1개'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사람', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _people.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final (name, sub) = _people[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Text(name.characters.first,
                    style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(sub, style: const TextStyle(color: AppColors.textHint)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
            ),
          );
        },
      ),
    );
  }
}
