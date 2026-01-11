import 'package:flutter/material.dart';
import '../main.dart';
import 'profile_page.dart';

class CategoriesScreen extends StatelessWidget {
  final AppUser user;
  final Map<String, List<ChecklistItem>> checklistData;
  final void Function(AppCategory category) onCategorySelect;
  final VoidCallback onLogout;

  const CategoriesScreen({
    super.key,
    required this.user,
    required this.checklistData,
    required this.onCategorySelect,
    required this.onLogout,
  });

  List<AppCategory> get categories => const [
        AppCategory(
          id: 'salon',
          name: 'Salon',
          icon: '🛋️',
          gradient: [Color(0xff3b82f6), Color(0xff22d3ee)],
        ),
        AppCategory(
          id: 'mutfak',
          name: 'Mutfak',
          icon: '🍳',
          gradient: [Color(0xfff97316), Color(0xfff59e0b)],
        ),
        AppCategory(
          id: 'banyo',
          name: 'Banyo',
          icon: '🚿',
          gradient: [Color(0xff14b8a6), Color(0xff10b981)],
        ),
        AppCategory(
          id: 'yatak-odasi',
          name: 'Yatak Odası',
          icon: '🛏️',
          gradient: [Color(0xff8b5cf6), Color(0xffec4899)],
        ),
        AppCategory(
          id: 'tekstil',
          name: 'Tekstil',
          icon: '🧵',
          gradient: [Color(0xfffb7185), Color(0xffef4444)],
        ),
        AppCategory(
          id: 'mutfak-esyalari',
          name: 'Mutfak Eşyaları',
          icon: '🍽️',
          gradient: [Color(0xff22c55e), Color(0xff84cc16)],
        ),
      ];

  Map<String, dynamic> _statsFor(String categoryId) {
    final items = checklistData[categoryId] ?? [];
    final total = items.length;
    final completed = items.where((e) => e.checked).length;
    final percentage = total == 0 ? 0 : (completed * 100 ~/ total);
    final totalSpent = items.fold<double>(0, (sum, item) {
      return sum + (item.checked ? item.price : 0);
    });
    return {
      'total': total,
      'completed': completed,
      'percentage': percentage,
      'totalSpent': totalSpent,
    };
  }

  double _totalSpentAll() {
    return checklistData.entries.fold(0, (acc, entry) {
      return acc +
          entry.value.fold(0, (sum, item) => sum + (item.checked ? item.price : 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xfffff0f5), // Lavender Blush
              Color(0xffe6e6fa), // Lavender
              Color(0xffe0f7fa), // Cyan 50
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Header Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'user_avatar',
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfilePage()),
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xffec4899), Color(0xff8b5cf6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    // ignore: deprecated_member_use
                                    color: const Color(0xffec4899).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(user.avatar, style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, ${user.name}!',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: Colors.blueGrey.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Çeyiz listen hazır mı?',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: IconButton(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded, color: Color(0xffef4444)),
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 24),

                // Total Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffec4899), Color(0xffd946ef)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: const Color(0xffec4899).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Toplam Harcama',
                        style: TextStyle(
                          color: Colors.white70, 
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_totalSpentAll().toStringAsFixed(0)} ₺',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Bütçeni kontrol et ✨',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Categories
                Row(
                  children: [
                     Text(
                      "Kategoriler",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Column(
                  children: categories.map((cat) {
                    final stats = _statsFor(cat.id);
                    final percentage = stats['percentage'] as int;
                    final total = stats['total'] as int;
                    final completed = stats['completed'] as int;
                    final totalSpent = stats['totalSpent'] as double;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                          const BoxShadow(
                             color: Colors.white,
                             offset: Offset(-5, -5),
                             blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onCategorySelect(cat),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'cat_icon_${cat.id}',
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        colors: cat.gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: cat.gradient.first.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(cat.icon, style: const TextStyle(fontSize: 28)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            cat.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Colors.blueGrey.shade800,
                                            ),
                                          ),
                                          if (totalSpent > 0)
                                            Text(
                                              '${totalSpent.toStringAsFixed(0)} ₺',
                                              style: TextStyle(
                                                color: cat.gradient.first,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (total > 0) ...[
                                        Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: percentage / 100,
                                              child: Container(
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: cat.gradient),
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      // ignore: deprecated_member_use
                                                      color: cat.gradient.first.withOpacity(0.5),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$completed / $total tamamlandı (%$percentage)',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ] else 
                                        const Text('Henüz ürün yok',
                                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
