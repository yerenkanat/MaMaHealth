import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/profile.dart';
import '../engagement/engagement_service.dart';
import '../profile_switch/bloc/profile_switch_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MeProfile? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<EngagementService>();
    try {
      await svc.checkin(); // продлить streak и начислить баллы за вход
      final me = await svc.me();
      if (mounted) setState(() => _me = me);
    } catch (_) {
      // офлайн/ошибка — оставляем дефолты
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _invite() {
    const code = 'MAMA-2026';
    Clipboard.setData(const ClipboardData(text: code));
    _toast('Реферальный код $code скопирован — поделитесь с друзьями!');
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _toast('Настройки — скоро'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(me: me),
            const SizedBox(height: 12),
            const _ChildrenCard(),
            const SizedBox(height: 12),
            _PointsCard(points: me?.points ?? 0, onInvite: _invite),
            const SizedBox(height: 20),
            _FavoritesSection(onTap: (t) => _toast('$t — скоро')),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.me});
  final MeProfile? me;

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
                color: const Color(0xFFFDE7D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🔥 ${me?.streak ?? 0} дней подряд',
                  style: const TextStyle(
                      color: Color(0xFFE07B39), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(me?.city ?? '—', style: const TextStyle(color: Colors.black45)),
            const SizedBox(height: 4),
            Text(me?.name ?? 'Мама',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE7E0FB),
                child:
                    Icon(Icons.emoji_emotions_outlined, color: Color(0xFF6A4BD0)),
              ),
              title: Text('Мой статус',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
              subtitle: Text('Я мама',
                  style: TextStyle(color: Colors.black87, fontSize: 16)),
              trailing: Icon(Icons.unfold_more),
            ),
          ],
        ),
      ),
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
  const _PointsCard({required this.points, required this.onInvite});
  final int points;
  final VoidCallback onInvite;

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
            Row(
              children: [
                const Icon(Icons.stars, color: AppColors.peach),
                const SizedBox(width: 10),
                Text('$points баллов',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.black38),
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
                  onPressed: onInvite,
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
  const _FavoritesSection({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Мои посты'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap('Мои посты'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Мои заказы'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap('Мои заказы'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Мои вопросы'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap('Мои вопросы'),
          ),
        ],
      ),
    );
  }
}
