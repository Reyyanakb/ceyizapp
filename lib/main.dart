import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore eklendi
import 'firebase_options.dart';
import 'screens/login_register_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/category_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAuthenticated = false;
  AppUser? currentUser;
  AppCategory? selectedCategory;
  final Map<String, List<ChecklistItem>> checklistData = {};

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // Kullanıcı durumunu dinler ve verileri Firestore'dan çeker
  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        setState(() {
          isAuthenticated = true;
          currentUser = AppUser(
            id: user.uid,
            name: user.displayName ?? "Kullanıcı",
            email: user.email ?? "",
            avatar: user.photoURL ?? "👩‍🦰",
          );
        });

        // VERİLERİ BULUTTAN ÇEKME (FETCH)
        await _loadDataFromFirestore(user.uid);
      } else {
        setState(() {
          isAuthenticated = false;
          currentUser = null;
          checklistData.clear();
        });
      }
    });
  }

  // Firestore'dan verileri yükleme fonksiyonu
  Future<void> _loadDataFromFirestore(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('checklists')
          .get();

      final Map<String, List<ChecklistItem>> loadedData = {};

      for (var doc in snapshot.docs) {
        final List<dynamic> itemsList = doc.data()['items'] ?? [];
        loadedData[doc.id] = itemsList.map((item) {
          return ChecklistItem.fromMap(item);
        }).toList();
      }

      setState(() {
        checklistData.addAll(loadedData);
      });
    } catch (e) {
      print("Veri yüklenirken hata: $e");
    }
  }

  void handleLogin(AppUser user) {
    setState(() {
      isAuthenticated = true;
      currentUser = user;
    });
  }

  void handleLogout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      isAuthenticated = false;
      currentUser = null;
      selectedCategory = null;
      checklistData.clear();
    });
  }

  void handleCategorySelect(AppCategory category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void handleBackToCategories() {
    setState(() {
      selectedCategory = null;
    });
  }

  // VERİYİ BULUTA KAYDETME (SYNC)
  void handleChecklistUpdate(String categoryId, List<ChecklistItem> items) async {
    setState(() {
      checklistData[categoryId] = items;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('checklists')
            .doc(categoryId)
            .set({
          'items': items.map((i) => i.toMap()).toList(),
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Firestore yazma hatası: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çeyiz Listem',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffec4899)),
      ),
      home: Builder(
        builder: (_) {
          if (!isAuthenticated) {
            return LoginRegisterScreen(onLogin: handleLogin);
          }

          if (selectedCategory != null) {
            return CategoryDetailScreen(
              category: selectedCategory!,
              items: checklistData[selectedCategory!.id] ?? const [],
              onBack: handleBackToCategories,
              onUpdateItems: (items) => handleChecklistUpdate(selectedCategory!.id, items),
            );
          }

          return CategoriesScreen(
            user: currentUser!,
            checklistData: checklistData,
            onCategorySelect: handleCategorySelect,
            onLogout: handleLogout,
          );
        },
      ),
    );
  }
}

// --- Modeller ---

class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatar;
  const AppUser({required this.id, required this.name, required this.email, required this.avatar});
}

class AppCategory {
  final String id;
  final String name;
  final String icon;
  final List<Color> gradient;
  const AppCategory({required this.id, required this.name, required this.icon, required this.gradient});
}

class ChecklistItem {
  final String id;
  final String name;
  final double price;
  final bool checked;
  final String? imageUrl;

  const ChecklistItem({required this.id, required this.name, required this.price, required this.checked, this.imageUrl});

  ChecklistItem copyWith({String? id, String? name, double? price, bool? checked, String? imageUrl}) {
    return ChecklistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      checked: checked ?? this.checked,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      checked: map['checked'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'checked': checked,
      'imageUrl': imageUrl,
    };
  }
}