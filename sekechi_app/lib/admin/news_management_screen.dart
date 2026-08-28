import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/news_model.dart';

class NewsManagementScreen extends StatefulWidget {
  const NewsManagementScreen({super.key});

  @override
  State<NewsManagementScreen> createState() => _NewsManagementScreenState();
}

class _NewsManagementScreenState extends State<NewsManagementScreen> {
  List<NewsModel> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    try {
      final news = await AdminService.getNews();
      setState(() {
        _newsList = news;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  void _showNewsDialog([NewsModel? news]) {
    final titleController = TextEditingController(text: news?.title);
    final contentController = TextEditingController(text: news?.content);
    final imageController = TextEditingController(text: news?.imageUrl);
    bool isActive = news?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(news == null ? 'افزودن خبر جدید' : 'ویرایش خبر'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان خبر')),
                  TextField(controller: contentController, maxLines: 3, decoration: const InputDecoration(labelText: 'متن خبر')),
                  TextField(controller: imageController, decoration: const InputDecoration(labelText: 'لینک تصویر (اختیاری)')),
                  SwitchListTile(
                    title: const Text('نمایش در اپلیکیشن'),
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
                    'content': contentController.text,
                    'image_url': imageController.text.isEmpty ? null : imageController.text,
                    'is_active': isActive,
                  };
                  try {
                    if (news == null) {
                      await AdminService.createNews(data);
                    } else {
                      await AdminService.updateNews(news.id, data);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadNews();
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

  Future<void> _deleteNews(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف خبر'),
        content: const Text('آیا از حذف این خبر اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.deleteNews(id);
        _loadNews();
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
        appBar: AppBar(title: const Text('مدیریت اخبار')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _newsList.length,
                itemBuilder: (context, index) {
                  final news = _newsList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.newspaper, color: news.isActive ? Colors.green : Colors.grey),
                      title: Text(news.title),
                      subtitle: Text(news.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showNewsDialog(news)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNews(news.id)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNewsDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
