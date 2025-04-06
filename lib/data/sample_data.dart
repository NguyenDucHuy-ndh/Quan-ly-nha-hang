import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/menu_category.dart';
import 'package:quanly_nhahang/models/menu_item.dart';
import 'package:quanly_nhahang/services/firestore_service.dart';

class SampleData extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  SampleData({Key? key}) : super(key: key);

  Future<void> _addSampleData() async {
    try {
      // Danh sách các danh mục
      List<MenuCategory> categories = [
        MenuCategory(
          id: '',
          name: 'Món khai vị',
          order: 1,
          imageUrl:
              'https://i.ytimg.com/vi/IE8Ig6FSMUg/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLBNjKsN_bADa_3wjAhH9w2z49vuPg',
        ),
        MenuCategory(
          id: '',
          name: 'Món súp',
          order: 2,
          imageUrl:
              'https://thucphamquocte.vn/wp-content/uploads/2024/10/mon-canh-cho-mua-thu.jpg',
        ),
        MenuCategory(
          id: '',
          name: 'Món chính',
          order: 3,
          imageUrl:
              'https://product.hstatic.net/1000373773/product/an-menufood-jan2024__2_-16_4b1fc2dd7e694c26ab0728dc6a0e31d4_master.jpg',
        ),
        MenuCategory(
          id: '',
          name: 'Món cơm',
          order: 4,
          imageUrl:
              'https://danviet.mediacdn.vn/296231569849192448/2021/6/22/bdimkitchen-1624265016976-1624324614473-1624324615163357692634.jpg',
        ),
        MenuCategory(
          id: '',
          name: 'Món nước',
          order: 5,
          imageUrl:
              'https://giavichinsu.com/wp-content/uploads/2024/02/mon-nuoc-ngon-tai-nha.jpg',
        ),
        MenuCategory(
          id: '',
          name: 'Món tráng miệng',
          order: 6,
          imageUrl:
              'https://gofoodmarket.vn/wp-content/uploads/2024/02/rau-cau-trai-cay.jpg',
        ),
        MenuCategory(
          id: '',
          name: 'Đồ uống',
          order: 7,
          imageUrl:
              'https://baristaschool.vn/wp-content/uploads/2021/07/tu-dien-do-uong.jpg',
        ),
      ];

      // Danh sách các món ăn theo từng danh mục
      Map<int, List<MenuItem>> menuItemsByCategory = {
        0: [
          MenuItem(
            id: '',
            name: 'Gỏi cuốn',
            description: 'Gỏi cuốn tôm thịt tươi với rau sống và bún',
            price: 25000,
            categoryId: '',
            imageUrl:
                'https://khaihoanphuquoc.com.vn/wp-content/uploads/2023/11/nu%CC%9Bo%CC%9B%CC%81c-ma%CC%86%CC%81m-cha%CC%82%CC%81m-go%CC%89i-cuo%CC%82%CC%81n-1200x900.png',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Chả giò',
            description: 'Chả giò chiên giòn nhân thịt và nấm',
            price: 30000,
            categoryId: '',
            imageUrl:
                'https://monngonmoingay.com/wp-content/smush-webp/2025/01/Cha-gio.png.webp',
            available: true,
          ),
        ],
        1: [
          MenuItem(
            id: '',
            name: 'Súp cua',
            description: 'Súp cua với thịt cua, trứng và nấm',
            price: 35000,
            categoryId: '',
            imageUrl:
                'https://bizweb.dktcdn.net/100/489/006/files/sup-cua-11.jpg?v=1697696659414',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Súp hải sản',
            description: 'Súp hải sản đặc biệt với tôm, mực và sò điệp',
            price: 40000,
            categoryId: '',
            imageUrl:
                'https://crabseafood.vn/wp-content/uploads/2022/11/soup-hai-san-2.png',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Súp gà nấm hương',
            description: 'Súp gà thơm ngon với nấm hương',
            price: 30000,
            categoryId: '',
            imageUrl:
                'https://cdn.tgdd.vn/Files/2021/08/05/1373270/cach-nau-sup-ga-ngo-non-thom-ngon-bo-duong-202201141412125884.jpg',
            available: true,
          ),
        ],

        // Món chính (index 2)
        2: [
          MenuItem(
            id: '',
            name: 'Cá kho tộ',
            description: 'Cá lóc kho tộ với nước mắm và ớt',
            price: 85000,
            categoryId: '',
            imageUrl:
                'https://file.hstatic.net/200000312673/article/ca_basamaster_cat_khoanh_kho_to_dam_vi__dua_com_0c734ec0508544769a927c1d0b2f7e33.jpeg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Sườn xào chua ngọt',
            description: 'Sườn heo xào chua ngọt với ớt chuông',
            price: 90000,
            categoryId: '',
            imageUrl:
                'hhttps://i-giadinh.vnecdn.net/2024/11/19/Bc6Thnhphm6-1732011665-9702-1732011821.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Gà hấp lá chanh',
            description: 'Gà ta hấp với lá chanh thơm ngon',
            price: 120000,
            categoryId: '',
            imageUrl:
                'https://inox304.com.vn/wp-content/uploads/2024/09/Mon-ga-hap-la-chanh-mang-lai-loi-ich-gi-cho-suc-khoe.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Bò lúc lắc',
            description: 'Bò lúc lắc với hành tây và ớt chuông',
            price: 110000,
            categoryId: '',
            imageUrl:
                'https://hidafoods.vn/wp-content/uploads/2023/07/cach-lam-bo-luc-lac-thom-ngon-chuan-vi-nha-hang-1.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Tôm rang muối',
            description: 'Tôm sú rang muối với tỏi và ớt',
            price: 150000,
            categoryId: '',
            imageUrl: 'https://i.ytimg.com/vi/U5MkvtAHwxs/maxresdefault.jpg',
            available: true,
          ),
        ],

        // Món cơm (index 3)
        3: [
          MenuItem(
            id: '',
            name: 'Cơm chiên hải sản',
            description: 'Cơm chiên với tôm, mực và rau củ',
            price: 65000,
            categoryId: '',
            imageUrl:
                'https://dulichphudien.vn/datafiles/163/2024-10/47020676-com-chien-hai-san.png',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Cơm gà Hải Nam',
            description: 'Cơm gà Hải Nam với gà luộc và nước dùng đặc biệt',
            price: 70000,
            categoryId: '',
            imageUrl:
                'https://cdn.tgdd.vn/Files/2021/08/16/1375575/cach-nau-com-ga-hai-nam-don-gian-ga-chin-vang-uom-da-gion-dung-chuan-202112290927578686.png',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Cơm sườn nướng',
            description: 'Cơm với sườn nướng và đồ chua',
            price: 75000,
            categoryId: '',
            imageUrl: 'https://i.ytimg.com/vi/cJu6tFJe_Gc/maxresdefault.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Cơm tấm',
            description: 'Cơm tấm sườn bì chả với nước mắm',
            price: 60000,
            categoryId: '',
            imageUrl:
                'https://www.order.capichiapp.com/_next/image?url=https%3A%2F%2Fcdn.capichiapp.com%2Frestaurants%2Fapp_images%2F000%2F001%2F831%2Flarge%2F23H05598-min.jpg%3F1690363228&w=3840&q=75',
            available: true,
          ),
        ],

        // Món nước (index 4)
        4: [
          MenuItem(
            id: '',
            name: 'Phở bò',
            description: 'Phở bò với thịt bò tái và nạm',
            price: 55000,
            categoryId: '',
            imageUrl:
                'https://hidafoods.vn/wp-content/uploads/2023/10/cach-nau-pho-bo-bap-hoa-thom-ngon-dam-da-huong-vi-4.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Bún bò Huế',
            description: 'Bún bò Huế cay với thịt bò và giò heo',
            price: 60000,
            categoryId: '',
            imageUrl:
                'https://i2.ex-cdn.com/crystalbay.com/files/content/2024/08/15/bun-bo-hue-6-0935.jpeg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Hủ tiếu nam vang',
            description: 'Hủ tiếu kiểu Nam Vang với tôm, thịt và lòng heo',
            price: 55000,
            categoryId: '',
            imageUrl: 'https://i.ytimg.com/vi/fziqSn-xkws/maxresdefault.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Bánh canh cua',
            description: 'Bánh canh với thịt cua và chả cá',
            price: 65000,
            categoryId: '',
            imageUrl:
                'https://cdn.tgdd.vn/2021/05/CookProduct/thumbcmscn-1200x676-4.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Mì Quảng',
            description: 'Mì Quảng với tôm, thịt và đậu phộng',
            price: 60000,
            categoryId: '',
            imageUrl:
                'https://helenrecipes.com/wp-content/uploads/2021/05/Screenshot-2021-05-31-142423-1200x675.png',
            available: true,
          ),
        ],

        // Món tráng miệng (index 5)
        5: [
          MenuItem(
            id: '',
            name: 'Chè ba màu',
            description: 'Chè ba màu với đậu xanh, đậu đỏ và thạch',
            price: 25000,
            categoryId: '',
            imageUrl:
                'hhttps://helenrecipes.com/wp-content/uploads/2015/03/IMG_9091.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Bánh flan',
            description: 'Bánh flan caramen mềm mịn',
            price: 20000,
            categoryId: '',
            imageUrl:
                'https://static.hawonkoo.vn/hwks1/images/2023/07/cach-lam-banh-flan-bang-noi-chien-khong-dau-1-1.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Trái cây tươi',
            description: 'Đĩa trái cây tươi theo mùa',
            price: 35000,
            categoryId: '',
            imageUrl:
                'https://vcdn1-suckhoe.vnecdn.net/2022/12/18/fruits-1729-1671358576.jpg?w=0&h=0&q=100&dpr=2&fit=crop&s=zMoW-Mc5jeXNpaeL-uBd3Q',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Chè đậu xanh',
            description: 'Chè đậu xanh với nước cốt dừa',
            price: 22000,
            categoryId: '',
            imageUrl:
                'https://www.btaskee.com/wp-content/uploads/2021/08/che-dau-xanh-nuoc-cot-dua.jpeg',
            available: true,
          ),
        ],

        // Đồ uống (index 6)
        6: [
          MenuItem(
            id: '',
            name: 'Cà phê sữa',
            description: 'Cà phê sữa đặc kiểu Việt Nam',
            price: 18000,
            categoryId: '',
            imageUrl:
                'https://classiccoffee.com.vn/files/common/uong-cafe-sua-co-tot-khong-luu-y-khi-uong-cafe-sua-b7nrl.png',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Trà đá',
            description: 'Trà đá thơm mát',
            price: 5000,
            categoryId: '',
            imageUrl:
                'https://coffeeteavn.com/wp-content/uploads/2024/08/1-1.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Sinh tố bơ',
            description: 'Sinh tố bơ đặc creamy với sữa đặc',
            price: 30000,
            categoryId: '',
            imageUrl:
                'https://www.cet.edu.vn/wp-content/uploads/2021/05/cach-lam-sinh-to-bo.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Nước ép cam',
            description: 'Nước ép cam tươi',
            price: 25000,
            categoryId: '',
            imageUrl:
                'https://elmich.vn/wp-content/uploads/2024/01/nuoc-ep-cam-tao-3.jpg',
            available: true,
          ),
          MenuItem(
            id: '',
            name: 'Nước dừa tươi',
            description: 'Nước dừa tươi nguyên trái',
            price: 28000,
            categoryId: '',
            imageUrl:
                'https://storage-vnportal.vnpt.vn/ndh-ubnd/5893/1223/uong-nuoc-dua.jpg',
            available: true,
          ),
        ],
      };

      // Thêm từng danh mục và các món ăn tương ứng
      for (int i = 0; i < categories.length; i++) {
        // Thêm danh mục vào Firestore
        DocumentReference categoryRef =
            await _firestoreService.addMenuCategory(categories[i]);

        // Thêm các món ăn thuộc danh mục
        if (menuItemsByCategory.containsKey(i)) {
          for (MenuItem item in menuItemsByCategory[i]!) {
            // Cập nhật categoryId cho từng món ăn
            MenuItem updatedItem = MenuItem(
              id: item.id,
              name: item.name,
              description: item.description,
              price: item.price,
              categoryId: categoryRef.id,
              imageUrl: item.imageUrl,
              available: item.available,
            );

            await _firestoreService.addMenuItem(
                categoryRef.id, updatedItem.toMap());
          }
        }
      }

      print('Sample data added successfully!');
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _addSampleData,
          child: const Text('Thêm dữ liệu mẫu'),
        ),
      ),
    );
  }
}
