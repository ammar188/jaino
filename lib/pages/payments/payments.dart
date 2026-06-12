import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payments_view.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  PaymentsController createState() => PaymentsController();
}

class PaymentsController extends State<PaymentsPage> {
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    setState(() => isLoading = true);

    final userId = Matrix.of(context).client.userID;
    final supabaseUrl = AppSettings.supabaseUrl.value;
    final supabaseKey = AppSettings.supabaseAnonKey.value;

    String url =
    '$supabaseUrl/rest/v1/payment_intents?user_id=eq.$userId&order=created_at.desc&select=customer_transaction_id,order_id,amount,customer_name,business_name,status,created_at';

    if (filter != 'all') {
      url += '&status=eq.$filter';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        payments = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void setFilter(String f) {
    filter = f;
    loadPayments();
  }

  @override
  Widget build(BuildContext context) => PaymentsView(this);
}