class AppConstants {
  static const Map<String, List<Map<String, dynamic>>> defaultItems = {
    'salon': [
      {'name': 'Koltuk Takımı', 'price': 0},
      {'name': 'Sehpa', 'price': 0},
      {'name': 'Televizyon Ünitesi', 'price': 0},
      {'name': 'Halı', 'price': 0},
      {'name': 'Perde', 'price': 0},
      {'name': 'Avize', 'price': 0},
      {'name': 'Duvar Saati', 'price': 0},
      {'name': 'Vazo', 'price': 0},
    ],
    'mutfak': [
      {'name': 'Yemek Masası', 'price': 0},
      {'name': 'Sandalye Takımı', 'price': 0},
      {'name': 'Buzdolabı', 'price': 0},
      {'name': 'Fırın', 'price': 0},
      {'name': 'Ocak', 'price': 0},
      {'name': 'Davlumbaz', 'price': 0},
      {'name': 'Mutfak Dolabı', 'price': 0},
      {'name': 'Bulaşık Makinesi', 'price': 0},
    ],
    'banyo': [
      {'name': 'Duş Perdesi', 'price': 0},
      {'name': 'Havlu Takımı', 'price': 0},
      {'name': 'Banyo Dolabı', 'price': 0},
      {'name': 'Ayna', 'price': 0},
      {'name': 'Sepet', 'price': 0},
      {'name': 'Paspas', 'price': 0},
      {'name': 'Sabunluk', 'price': 0},
      {'name': 'Bornoz Takımı', 'price': 0},
      {'name': 'Klozet Takımı', 'price': 0},
      {'name': 'Çöp Kovası', 'price': 0},
      {'name': 'Diş Fırçalık', 'price': 0},
      {'name': 'Tuvalet Kağıtlığı', 'price': 0},
      {'name': 'Kirli Sepeti', 'price': 0},
    ],
    'yatak-odasi': [
      {'name': 'Yatak', 'price': 0},
      {'name': 'Gardırop', 'price': 0},
      {'name': 'Şifonyer', 'price': 0},
      {'name': 'Komodin', 'price': 0},
      {'name': 'Yatak Örtüsü', 'price': 0},
      {'name': 'Nevresim Takımı', 'price': 0},
      {'name': 'Yastık', 'price': 0},
    ],
    'tekstil': [
      {'name': 'Havlu Seti', 'price': 0},
      {'name': 'Nevresim', 'price': 0},
      {'name': 'Pike', 'price': 0},
      {'name': 'Battaniye', 'price': 0},
      {'name': 'Yatak Çarşafı', 'price': 0},
      {'name': 'Yastık Kılıfı', 'price': 0},
      {'name': 'Masa Örtüsü', 'price': 0},
    ],
    'mutfak-esyalari': [
      {'name': 'Tencere Seti', 'price': 0},
      {'name': 'Tabak Seti', 'price': 0},
      {'name': 'Çatal Bıçak Takımı', 'price': 0},
      {'name': 'Bardak Seti', 'price': 0},
      {'name': 'Çaydanlık', 'price': 0},
      {'name': 'Tava', 'price': 0},
      {'name': 'Tost Makinesi', 'price': 0},
      {'name': 'Blender Seti', 'price': 0},
      {'name': 'Miksere', 'price': 0},
      {'name': 'Kahve Makinesi', 'price': 0},
    ],
  };

  static List<String> getAllItemNames() {
    final List<String> names = [];
    defaultItems.forEach((key, value) {
      for (var item in value) {
        names.add(item['name'] as String);
      }
    });
    return names;
  }

  static String? getCategoryFor(String itemName) {
    String? foundCat;
    defaultItems.forEach((catId, items) {
      for (var item in items) {
        if (item['name'] == itemName) {
          foundCat = catId;
          return;
        }
      }
    });
    return foundCat;
  }
}
