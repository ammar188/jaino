import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluffychat/config/setting_keys.dart';
import 'review_view.dart';

class Review extends StatefulWidget {
  const Review({super.key});

  @override
  State<Review> createState() => ReviewState();
}

class ReviewState extends State<Review> {
  late Future<List<Map<String, dynamic>>> reviewsFuture;

  @override
  void initState() {
    super.initState();
    reviewsFuture = fetchReviews();
  }

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    final url =
        '${AppSettings.supabaseUrl.value}/rest/v1/reviews?select=*&order=created_at.desc';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': AppSettings.supabaseAnonKey.value,
        'Authorization': 'Bearer ${AppSettings.supabaseAnonKey.value}',
      },
    );
    if (response.statusCode != 200) throw Exception('Failed to load reviews');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  void refresh() {
    setState(() => reviewsFuture = fetchReviews());
  }

  @override
  Widget build(BuildContext context) {
    return ReviewView(controller: this);
  }
}