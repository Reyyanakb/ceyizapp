import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../utils/app_constants.dart';

class CategoryDetailScreen extends StatefulWidget {
  final AppCategory category;
  final List<ChecklistItem> items;
  final VoidCallback onBack;
  final void Function(List<ChecklistItem> items) onUpdateItems;
  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.items,
    required this.onBack,
    required this.onUpdateItems,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late List<ChecklistItem> items;
  String newName = '';
  String newPrice = '';
  String? editingId;

  final Map<String, List<Map<String, dynamic>>> defaultItems = AppConstants.defaultItems;

  @override
  void initState() {
    super.initState();
    items = widget.items.isEmpty ? _defaultsFor(widget.category.id) : widget.items;
    if (widget.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onUpdateItems(items);
      });
    }
  }

  List<ChecklistItem> _defaultsFor(String id) {
    final list = defaultItems[id] ?? [];
    return list
        .asMap()
        .entries
        .map((e) => ChecklistItem(
              id: '$id-${DateTime.now().millisecondsSinceEpoch}-${e.key}',
              name: e.value['name'] as String,
              price: (e.value['price'] as num).toDouble(),
              checked: false,
            ))
        .toList();
  }

  void toggleItem(String id) {
    setState(() {
      items = items
          .map((e) => e.id == id ? e.copyWith(checked: !e.checked) : e)
          .toList();
      widget.onUpdateItems(items);
    });
  }

  void deleteItem(String id) {
    setState(() {
      items = items.where((e) => e.id != id).toList();
      widget.onUpdateItems(items);
    });
  }

  Future<void> savePrice(String id, double price, {String? imageUrl}) async {
  setState(() {
      items = items.map((e) =>
        e.id == id ?
          e.copyWith(price: price, checked: true, imageUrl: imageUrl ?? e.imageUrl)
          : e).toList();
      widget.onUpdateItems(items);
    });
}

  void addItem() {
    if (newName.trim().isEmpty) return;
    final priceVal = double.tryParse(newPrice) ?? 0;
    final item = ChecklistItem(
      id: '${widget.category.id}-${DateTime.now().millisecondsSinceEpoch}',
      name: newName.trim(),
      price: priceVal,
      checked: false,
    );
    setState(() {
      items = [...items, item];
      newName = '';
      newPrice = '';
      widget.onUpdateItems(items);
    });
  }

  // Tek bir pickImage fonksiyonu: Hem Web hem Mobile uyumlu
  Future<void> _pickImage(ImageSource source, void Function(File? file, Uint8List? bytes) onPick) async {
    try {
      // Görsel kalitesini ve boyutunu düşürerek upload hızını artırıyoruz
      final XFile? picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50, // %50 kalite
        maxWidth: 800,    // Maksimum genişlik 800px
      );
      
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        onPick(null, bytes);
      } else {
        onPick(File(picked.path), null);
      }
    } catch (e) {
      debugPrint("Fotoğraf seçimi hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = items.where((e) => e.checked).length;
    final total = items.length;
    final percentage = total == 0 ? 0 : (completed * 100 ~/ total);
    final totalSpent = items.fold<double>(0, (sum, e) => sum + (e.checked ? e.price : 0));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
            tooltip: 'Geri',
          ),
        ),
        title: Text(
          widget.category.name,
          style: TextStyle(
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
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
          child: Column(
            children: [
              // Header Summary Card
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                   gradient: LinearGradient(
                    colors: widget.category.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.category.gradient.first.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: 'cat_icon_${widget.category.id}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(widget.category.icon,
                                      style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tamamlanan',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '%$percentage',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 6,
                                          backgroundColor: Colors.black12,
                                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Harcama',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            ),
                            Text(
                              '${totalSpent.toStringAsFixed(0)} ₺',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),

              // Add Item Input Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Yeni ürün ekle...',
                            border: InputBorder.none,
                            icon: Icon(Icons.add_task_rounded, color: Colors.grey),
                          ),
                          onChanged: (v) => setState(() => newName = v),
                          controller: TextEditingController.fromValue(
                              TextEditingValue(text: newName, selection: TextSelection.collapsed(offset: newName.length))),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.shade300),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Fiyat',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 10),
                            suffixText: '₺',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => newPrice = v),
                          controller: TextEditingController.fromValue(
                              TextEditingValue(text: newPrice, selection: TextSelection.collapsed(offset: newPrice.length))),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: widget.category.gradient.last,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                        onPressed: addItem,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Item List
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 20)],
                              ),
                              child: Icon(Icons.shopping_bag_outlined, 
                                size: 60, color: Colors.grey.withOpacity(0.4)),
                            ),
                            const SizedBox(height: 16),
                            Text('Listeniz boş, eklemeye başlayın!',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Bottom padding for scrolling space
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: item.checked ? const Color(0xfff8fafc) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: item.checked 
                                ? [] 
                                : [
                                    BoxShadow(
                                      color: Colors.blueGrey.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                              border: Border.all(
                                color: item.checked ? Colors.transparent : Colors.white,
                                width: 2
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {}, // Prevent ripple for whole card if not improved
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      GestureDetector(
                                        onTap: () => toggleItem(item.id),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.elasticOut,
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: item.checked 
                                              ? widget.category.gradient.first 
                                              : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: item.checked 
                                                ? Colors.transparent 
                                                : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                            boxShadow: item.checked
                                              ? [
                                                  BoxShadow(
                                                    color: widget.category.gradient.first.withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ]
                                              : [],
                                          ),
                                          child: item.checked
                                              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontWeight: item.checked ? FontWeight.normal : FontWeight.bold,
                                                fontSize: 16,
                                                color: item.checked ? Colors.grey.shade400 : Colors.blueGrey.shade800,
                                                decoration: item.checked ? TextDecoration.lineThrough : null,
                                                decorationColor: Colors.grey.shade400,
                                              ),
                                            ),
                                            if (item.price > 0) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.price.toStringAsFixed(0)} ₺',
                                                style: TextStyle(
                                                  color: item.checked ? Colors.grey.shade300 : widget.category.gradient.first,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              )
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      // Image Preview
                                      if (item.imageUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              // Show full image dialog could go here
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.white, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                   BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.imageUrl!,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 44,
                                                    height: 44,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(Icons.broken_image, size: 16),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                      // Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              onTap: () {
                                                // Camera Dialog logic
                                                _showCameraDialog(context, item);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Icon(Icons.camera_alt_outlined, 
                                                  color: Colors.grey.shade500, size: 22),
                                              ),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              onTap: () {
                                                // Edit Dialog logic
                                                _showEditDialog(context, item);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Icon(Icons.edit_outlined, 
                                                  color: Colors.blueAccent.shade100, size: 22),
                                              ),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              onTap: () => deleteItem(item.id),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Icon(Icons.delete_outline_rounded, 
                                                  color: Colors.redAccent.shade100, size: 22),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Refactored Dialogs into methods to keep build clean
  void _showCameraDialog(BuildContext context, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        File? pickedFile;
        Uint8List? pickedBytes;
        
        bool isUploading = false;
        String? previewUrl = item.imageUrl;
        
        return StatefulBuilder(
          builder: (context, setStateSB) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Ürün Fotoğrafı'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: (previewUrl != null)
                      ? Image.network(previewUrl!, fit: BoxFit.cover)
                      : (kIsWeb && pickedBytes != null)
                          ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                          : (!kIsWeb && pickedFile != null)
                              ? Image.file(pickedFile!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text("Kamera"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera, (f, b) {
                          setStateSB(() {
                            pickedFile = f;
                            pickedBytes = b;
                            previewUrl = null;
                          });
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text("Galeri"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery, (f, b) {
                          setStateSB(() {
                            pickedFile = f;
                            pickedBytes = b;
                            previewUrl = null;
                          });
                        }),
                      ),
                    ),
                  ],
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                   LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isUploading ? null : () async {
                  String? downloadUrl = previewUrl;
                  
                  if (pickedFile != null || pickedBytes != null) {
                    setStateSB(() { isUploading = true; });
                    
                    try {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('productImages/${item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
                      
                      UploadTask? task;
                      if (kIsWeb && pickedBytes != null) {
                        task = ref.putData(pickedBytes!, SettableMetadata(contentType: 'image/jpeg'));
                      } else if (pickedFile != null) {
                        task = ref.putFile(pickedFile!);
                      }
                      
                      if (task != null) {
                        final snapshot = await task.whenComplete(() {});
                        downloadUrl = await snapshot.ref.getDownloadURL();
                      }
                    } catch (e) {
                      debugPrint("Upload hatası: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Yükleme başarısız: $e"), backgroundColor: Colors.red),
                        );
                      }
                      setStateSB(() { isUploading = false; });
                      return;
                    }
                  }
                  
                  await savePrice(item.id, item.price, imageUrl: downloadUrl);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Görsel güncellendi ✨"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        String tmp = item.price == 0 ? '' : item.price.toStringAsFixed(0);
        File? pickedFile;
        Uint8List? pickedBytes;
        bool isUploading = false;
        String? previewUrl = item.imageUrl;

        return StatefulBuilder(
          builder: (context, setStateSB) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Düzenle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fiyat',
                    suffixText: '₺',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  controller: TextEditingController(text: tmp),
                  onChanged: (v) => tmp = v,
                ),
                const SizedBox(height: 16),
                
                 Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: (previewUrl != null)
                      ? Image.network(previewUrl!, fit: BoxFit.cover)
                      : (kIsWeb && pickedBytes != null)
                          ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                          : (!kIsWeb && pickedFile != null)
                              ? Image.file(pickedFile!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey.shade400),
                                    const SizedBox(height: 4),
                                    Text("Görsel Ekle", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text("Kamera"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera, (f, b) {
                          setStateSB(() {
                            pickedFile = f;
                            pickedBytes = b;
                            previewUrl = null;
                          });
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text("Galeri"),
                         style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery, (f, b) {
                          setStateSB(() {
                            pickedFile = f;
                            pickedBytes = b;
                            previewUrl = null;
                          });
                        }),
                      ),
                    ),
                  ],
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isUploading ? null : () async {
                  final p = double.tryParse(tmp) ?? 0;
                  String? downloadUrl = previewUrl;
                  
                  if (pickedFile != null || pickedBytes != null) {
                    setStateSB(() { isUploading = true; });
                    try {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('productImages/${item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
                      
                      UploadTask? task;
                      if (kIsWeb && pickedBytes != null) {
                        task = ref.putData(pickedBytes!, SettableMetadata(contentType: 'image/jpeg'));
                      } else if (pickedFile != null) {
                        task = ref.putFile(pickedFile!);
                      }
                      
                      if (task != null) {
                        final snapshot = await task.whenComplete(() {});
                        downloadUrl = await snapshot.ref.getDownloadURL();
                      }
                    } catch (e) {
                       debugPrint("Upload hatası: $e");
                       if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text("Yükleme başarısız: $e"), backgroundColor: Colors.red),
                        );
                       }
                      setStateSB(() { isUploading = false; });
                      return;
                    }
                  }
                  
                  await savePrice(item.id, p, imageUrl: downloadUrl);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kayıt başarılı ✅"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }
}
