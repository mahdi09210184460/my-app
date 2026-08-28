import 'package:flutter/material.dart';
import '../models/news_model.dart';
import 'package:intl/intl.dart' hide TextDirection;

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;
  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات خبر')),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.imageUrl != null)
                Image.network(news.imageUrl!, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(news.createdAt),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    Text(
                      news.content,
                      style: const TextStyle(fontSize: 16, height: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
