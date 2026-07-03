import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/profile.dart';
import '../profile_switch/bloc/profile_switch_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: const [Icon(Icons.settings_outlined), SizedBox(width: 16)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HeaderCard(),
          SizedBox(height: 12),
          _ChildrenCard(),
          SizedBox(height: 12),
          _PointsCard(),
          SizedBox(height: 20),
          _FavoritesSection(),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFF3E0EA),
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('29 · уровень',
                  style: TextStyle(
                      color: Color(0xFF6A4BD0), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            const Text('Алматы, Қазақстан',
                style: TextStyle(color: Colors.black45)),
            const SizedBox(height: 4),
            const Text('Айман',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(value: '413', label: 'подписчиков'),
                SizedBox(width: 24),
                _Stat(value: '39 911', label: 'подписки'),
              ],
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE7E0FB),
                child: Icon(Icons.emoji_emotions_outlined, color: Color(0xFF6A4BD0)),
              ),
              title: Text('Мой статус', style: TextStyle(color: Colors.black45, fontSize: 13)),
              subtitle: Text('Я мама', style: TextStyle(color: Colors.black87, fontSize: 16)),
              trailing: Icon(Icons.unfold_more),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.black45)),
      ],
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSwitchBloc, ProfileSwitchState>(
      builder: (context, state) {
        final kids = state.profiles
            .where((p) => p.type == ProfileType.child)
            .map((p) => p.title)
            .toList();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: AppGradients.hero,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C6BE8).withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Мои дети',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(kids.isEmpty ? 'Пока нет профилей' : kids.join(' · '),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        );
      },
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars, color: AppColors.peach),
                SizedBox(width: 10),
                Text('1000 баллов',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Получите 500 бонусов',
                style: TextStyle(
                    color: Color(0xFF6A4BD0), fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Text('Поделитесь реферальной ссылкой с друзьями',
                      style: TextStyle(color: Colors.black54)),
                ),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Пригласить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Column(
        children: [
          ListTile(leading: Icon(Icons.edit_outlined), title: Text('Мои посты'), trailing: Icon(Icons.chevron_right)),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.shopping_bag_outlined), title: Text('Мои заказы'), trailing: Icon(Icons.chevron_right)),
          Divider(height: 1),
          ListTile(leading: Icon(Icons.help_outline), title: Text('Мои вопросы'), trailing: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
