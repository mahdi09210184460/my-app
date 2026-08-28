import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/shop_item_model.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  List<ShopItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await AdminService.getShopItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  void _showItemDialog([ShopItemModel? item]) {
    final titleController = TextEditingController(text: item?.title);
    final descController = TextEditingController(text: item?.description);
    final catController = TextEditingController(text: item?.category);
    final priceController = TextEditingController(text: item?.price.toString());
    final coinController = TextEditingController(text: item?.coinPrice.toString());
    bool isActive = item?.active ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(item == null ? 'افزودن محصول جدید' : 'ویرایش محصول'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان محصول')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'توضیحات')),
                  TextField(controller: catController, decoration: const InputDecoration(labelText: 'دسته‌بندی')),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت (تومان)')),
                  TextField(controller: coinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت (سکه)')),
                  SwitchListTile(
                    title: const Text('فعال'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'title': titleController.text,
                    'description': descController.text,
                    'category': catController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                    'coin_price': int.tryParse(coinController.text) ?? 0,
                    'active': isActive,
                  };
                  try {
                    if (item == null) {
                      await AdminService.createShopItem(data);
                    } else {
                      await AdminService.updateShopItem(item.id, data);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadItems();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
                    }
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف محصول'),
        content: const Text('آیا از حذف این محصول اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.deleteShopItem(id);
        _loadItems();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مدیریت فروشگاه')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text('${item.price} تومان | ${item.coinPrice} سکه'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showItemDialog(item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item.id)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showItemDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
