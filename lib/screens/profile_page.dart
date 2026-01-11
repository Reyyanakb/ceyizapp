import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_constants.dart';
import '../services/friend_service.dart';
import 'login_register_screen.dart';
import 'friends/friends_home_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  bool isUploading = false;

  // Soft purple-pink palette
  final Color _bgStart = const Color(0xFFF3E8FF); // Purple 50
  final Color _bgEnd = const Color(0xFFFCE7F3);   // Pink 50
  final Color _accentPurple = const Color(0xFFC084FC); // Purple 400
  final Color _accentPink = const Color(0xFFF472B6);   // Pink 400

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? u) {
      if (mounted) {
        setState(() {
          user = u;
        });
      }
    });
  }

  Future<void> _updateProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600
    );

    if (pickedFile == null || user == null) return;

    setState(() => isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_avatars/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask? task;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(File(pickedFile.path));
      }

      await task;
      final downloadUrl = await ref.getDownloadURL();

      await user!.updatePhotoURL(downloadUrl);
      await user!.reload();

      if (mounted) {
        setState(() {
          user = FirebaseAuth.instance.currentUser;
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil fotoğrafı başarıyla güncellendi ✨"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint("Foto yükleme hatası: $e");
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yükleme başarısız: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _updateName() async {
    final controller = TextEditingController(text: user?.displayName ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("İsim Düzenle", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Ad Soyad",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: Colors.grey.shade600))
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accentPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && user != null) {
                await user!.updateDisplayName(controller.text.trim());
                await user!.reload();
                setState(() {
                  user = FirebaseAuth.instance.currentUser;
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgStart, _bgEnd],
            )
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: _accentPurple.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text("Profilinizi görmek için giriş yapın", style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginRegisterScreen(onLogin: (u) {
                          Navigator.pop(context);
                        }))
                      );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Giriş Yap"),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentPink,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
            builder: (context, snapshot) {
              bool hasRequests = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final requests = data['receivedRequests'] as List<dynamic>?;
                if (requests != null && requests.isNotEmpty) hasRequests = true;
              }

              return Stack(
                children: [
                    IconButton(
                    icon: const Icon(Icons.people_alt_rounded, color: Colors.black54),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsHomeScreen()));
                    },
                  ),
                  if (hasRequests)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: _signOut,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, Colors.white],
            stops: const [0.0, 0.6],
          )
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              _buildHeaderWrapper(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildPrivacyToggle(),
                    const SizedBox(height: 16),
                    _StatusCard(
                      title: "Tamamlananlar",
                      countLabel: "Aldıklarım",
                      statusKey: "aldı",
                      startColor: const Color(0xFFD1FAE5),
                      endColor: const Color(0xFFA7F3D0),
                      iconColor: const Color(0xFF059669),
                      icon: Icons.check_circle_rounded,
                      userId: user!.uid,
                    ),
                    const SizedBox(height: 16),
                    _StatusCard(
                      title: "Planlananlar",
                      countLabel: "Çeyiz Listem",
                      statusKey: "alacak",
                      startColor: const Color(0xFFFEF3C7),
                      endColor: const Color(0xFFFDE68A),
                      iconColor: const Color(0xFFD97706),
                      icon: Icons.bookmarks_rounded,
                      userId: user!.uid,
                    ),
                    const SizedBox(height: 16),
                    _StatusCard(
                      title: "Eksikler",
                      countLabel: "Almadıklarım",
                      statusKey: "almadı",
                      startColor: const Color(0xFFFFE4E6),
                      endColor: const Color(0xFFFECDD3),
                      iconColor: const Color(0xFFE11D48),
                      icon: Icons.shopping_bag_rounded,
                      userId: user!.uid,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWrapper() {
    final Stream<QuerySnapshot> _checklistsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('checklists')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: _checklistsStream,
      builder: (context, snapshot) {
        int totalCompleted = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['items'] is List) {
               final list = data['items'] as List;
               totalCompleted += list.where((i) => i['checked'] == true).length;
            }
          }
        }
        return _buildHeader(totalCompleted);
      },
    );
  }

  Widget _buildHeader(int totalCompleted) {
    int level = totalCompleted ~/ 5;

    String badgeIcon = "";
    String badgeLabel = "";
    List<Color> badgeColors = [Colors.grey.shade200, Colors.grey.shade300];
    Color badgeTextColor = Colors.grey.shade700;

    if (level >= 1) {
       if (level < 5) {
         badgeIcon = "🥉";
         badgeLabel = "Bronz Üye";
         badgeColors = [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)];
         badgeTextColor = Colors.brown;
       } else if (level < 10) {
         badgeIcon = "🥈";
         badgeLabel = "Gümüş Üye";
         badgeColors = [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)];
         badgeTextColor = Colors.blueGrey;
       } else if (level < 20) {
         badgeIcon = "🥇";
         badgeLabel = "Altın Üye";
         badgeColors = [const Color(0xFFFEFCE8), const Color(0xFFFEF08A)];
         badgeTextColor = Colors.orange.shade800;
       } else {
         badgeIcon = "💎";
         badgeLabel = "Elmas Üye";
         badgeColors = [const Color(0xFFECFEFF), const Color(0xFFA5F3FC)];
         badgeTextColor = Colors.cyan.shade800;
       }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentPurple.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ]
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_accentPurple, _accentPink]),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: isUploading
                  ? CircularProgressIndicator(color: _accentPurple)
                  : (user?.photoURL == null
                      ? Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                          style: TextStyle(fontSize: 40, color: _accentPurple, fontWeight: FontWeight.bold),
                        )
                      : null),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isUploading ? null : _updateProfilePhoto,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: _accentPink, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _updateName,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.displayName ?? "Kullanıcı",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff1f2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),

        Text(
          user?.email ?? "",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 16),

        if (level >= 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: badgeColors),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: badgeColors.last.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badgeIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  "$badgeLabel • $totalCompleted Ürün",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPrivacyToggle() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isPrivate = data['isPrivate'] ?? false;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SwitchListTile(
            activeColor: _accentPink,
            title: const Text(
              "Gizli Hesap",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              "Profilini sadece arkadaşların görebilir",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            secondary: Icon(
              isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isPrivate ? _accentPink : Colors.grey,
            ),
            value: isPrivate,
            onChanged: (bool value) {
              FriendService().togglePrivacy(user!.uid, isPrivate);
            },
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String countLabel;
  final String statusKey;
  final Color startColor;
  final Color endColor;
  final Color iconColor;
  final IconData icon;
  final String userId;

  const _StatusCard({
    required this.title,
    required this.countLabel,
    required this.statusKey,
    required this.startColor,
    required this.endColor,
    required this.iconColor,
    required this.icon,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3E8FF).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showProductList(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [startColor, endColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff374151),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProductListSheet(
          statusKey: statusKey, userId: userId, title: title, accentColor: iconColor),
    );
  }
}

class _ProductListSheet extends StatefulWidget {
  final String statusKey;
  final String userId;
  final String title;
  final Color accentColor;

  const _ProductListSheet({
    required this.statusKey,
    required this.userId,
    required this.title,
    required this.accentColor,
  });

  @override
  State<_ProductListSheet> createState() => _ProductListSheetState();
}

class _ProductListSheetState extends State<_ProductListSheet> {
  final TextEditingController _newItemController = TextEditingController();

  Future<void> _addNewItem(String itemName) async {
    if (itemName.trim().isEmpty) return;
    String? categoryId = AppConstants.getCategoryFor(itemName);
    categoryId ??= 'salon';

    // "Aldıklarım" listesinden ekleniyorsa, checked = true yapalım.
    bool isCompleted = (widget.statusKey == 'aldı');

    final newItem = {
      'id': '$categoryId-${DateTime.now().millisecondsSinceEpoch}',
      'name': itemName,
      'price': 0,
      'checked': isCompleted,
    };

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('checklists')
          .doc(categoryId);

      // Try updating, if fails set
      await docRef.update({
        'items': FieldValue.arrayUnion([newItem])
      }).onError((e, _) async {
        await docRef.set({
          'items': [newItem],
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      });

      // Eğer "Aldıklarım" olarak eklendiyse, bildirim gönderelim
      if (isCompleted) {
        FriendService().sendNotificationToFriends("$itemName ürününü çeyizine ekledi! 🎉");
      }

      _newItemController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             backgroundColor: widget.accentColor,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             content: Text("$itemName listeye eklendi"),
          ),
        );
          Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Ekleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _checklistsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('checklists')
        .snapshots();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.list_alt_rounded, color: widget.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: Colors.grey.shade400))
                  ],
                ),
              ),

              if (widget.statusKey == 'almadı' || widget.statusKey == 'aldı') ...[
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                   child: Autocomplete<String>(
                     optionsBuilder: (TextEditingValue textEditingValue) {
                       if (textEditingValue.text == '') return const Iterable<String>.empty();
                       return AppConstants.getAllItemNames().where((String option) {
                         return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                       });
                     },
                     onSelected: (String selection) => _addNewItem(selection),
                     fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                       return TextField(
                         controller: textEditingController,
                         focusNode: focusNode,
                         decoration: InputDecoration(
                           hintText: "Hızlıca ürün ekle...",
                           filled: true,
                           fillColor: Colors.grey.shade50,
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                           prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                           suffixIcon: Container(
                             margin: const EdgeInsets.all(6),
                             decoration: BoxDecoration(color: widget.accentColor, borderRadius: BorderRadius.circular(10)),
                             child: IconButton(
                               icon: const Icon(Icons.add, color: Colors.white, size: 20),
                               constraints: const BoxConstraints(),
                               padding: EdgeInsets.zero,
                               onPressed: () => _addNewItem(textEditingController.text),
                             ),
                           ),
                         ),
                         onSubmitted: (val) => _addNewItem(val),
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 8),
              ],
              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _checklistsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu'));
                    if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: widget.accentColor));

                    final docs = snapshot.data?.docs ?? [];
                    List<Map<String, dynamic>> allItems = [];

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['items'] is List) {
                        for (var item in data['items']) {
                          final bool checked = item['checked'] ?? false;
                          bool matches = false;
                          if (widget.statusKey == 'aldı' && checked) matches = true;
                          if (widget.statusKey == 'alacak' && !checked) matches = true;
                          if (widget.statusKey == 'almadı' && !checked) matches = true;
                          if (matches) allItems.add(item as Map<String, dynamic>);
                        }
                      }
                    }

                    if (allItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                               color: Colors.grey.shade50,
                               shape: BoxShape.circle,
                             ),
                             child: Icon(Icons.history_edu_rounded, size: 48, color: Colors.grey.shade300)
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Liste şu an boş",
                              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      itemCount: allItems.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = allItems[index];
                        final name = data['name'] ?? 'İsimsiz';
                        final price = data['price'] ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(color: widget.accentColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xff374151)),
                                ),
                              ),
                              Text(
                                '$price ₺',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}