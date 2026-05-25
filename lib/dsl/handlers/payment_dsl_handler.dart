import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class PaymentDSLHandler extends DSLHandler {
  @override
  String get type => 'payment';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final amount       = msg.get<int>('amount') ?? 0;
    final currency     = msg.get<String>('currency') ?? 'PKR';
    final orderId      = msg.get<String>('order_id') ?? '';
    final paymentUrl   = msg.get<String>('payment_url') ?? '';
    final customerName = msg.get<String>('customer_name') ?? '';
    final room         = event.room;

    return DSLRenderResult(
      widget: _PaymentCard(
        amount: amount,
        currency: currency,
        orderId: orderId,
        paymentUrl: paymentUrl,
        customerName: customerName,
        room: room,
        senderUserId: room.client.userID ?? '',
      ),
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final int amount;
  final String currency;
  final String orderId;
  final String paymentUrl;
  final String customerName;
  final Room room;
  final String senderUserId;

  const _PaymentCard({
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.paymentUrl,
    required this.customerName,
    required this.room,
    required this.senderUserId,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _loadingPay = false;
  bool _isPaid = false;
  bool _reviewEventSent = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _subscribeToPayment();
  }

  Future<void> _checkInitialStatus() async {
  final response = await Supabase.instance.client
      .from('payment_intents')
      .select('status')
      .eq('order_id', widget.orderId)
      .eq('status', 'paid')
      .maybeSingle();

 if (response != null && mounted && !_reviewEventSent) {
  _reviewEventSent = true;  // ADD THIS
  setState(() => _isPaid = true);
  await _sendPaymentSuccessEvent();
}
}

  void _subscribeToPayment() {
    _channel = Supabase.instance.client
        .channel('payment_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'payment_intents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: widget.orderId,
          ),
          callback: (payload) async {
  final newStatus = payload.newRecord['status'];
  if (newStatus == 'paid' && mounted && !_reviewEventSent) {
    _reviewEventSent = true;  // ADD THIS
    setState(() => _isPaid = true);
    await _sendPaymentSuccessEvent();
  }
},
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _sendPaymentSuccessEvent() async {
  try {
    await widget.room.sendEvent({
      'msgtype': 'm.text',
      'body': 'Payment confirmed',
      'com.jaino.dsl': {
        'type': 'payment_success',
        'version': 1,
        'data': {
          'order_id': widget.orderId,
        },
      },
    });
    debugPrint('✅ payment_success DSL event sent for order ${widget.orderId}');
  } catch (e) {
    debugPrint('🔴 Failed to send payment_success event: $e');
  }
}

 Future<void> _openPayment() async {
  setState(() => _loadingPay = true);
  try {
    final userId = widget.room.client.userID ?? '';
    debugPrint('🔵 Calling refresh-payment | order_id: ${widget.orderId} | user_id: $userId');

    final refreshResp = await Supabase.instance.client.functions.invoke(
      'refresh-payment',
      body: {
        'order_id': widget.orderId,
        'user_id': userId,
      },
    );
    debugPrint('🟢 raw response data: ${refreshResp.data}');
    debugPrint('🟢 response status: ${refreshResp.status}');

    debugPrint('🟢 refresh-payment response: ${refreshResp.data}');
    debugPrint('🟡 refresh-payment error: ${refreshResp.status}');

    final refreshData = refreshResp.data as Map<String, dynamic>;

    if (refreshData['status'] == 'paid') {
      if (mounted) setState(() => _isPaid = true);
      return;
    }

    final freshUrl = refreshData['payment_url'] as String?;
    if (freshUrl == null || freshUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment link not available')),
        );
      }
      return;
    }

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PaymentWebView(
            url: freshUrl,
            orderId: widget.orderId,
            room: widget.room,
          ),
        ),
      );
    }
  } catch (e, stack) {
    debugPrint('🔴 _openPayment error: $e');
    debugPrint('🔴 stack: $stack');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _loadingPay = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = const Color(0xFFC9C9C9);
    final btnBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final btnText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      width: 193,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💳 Payment Due',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.currency} ${widget.amount}',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isPaid ? 'Payment completed' : 'Complete your payment',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 0.60,
            color: subtitleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: (_loadingPay || _isPaid) ? null : _openPayment,
            child: Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: _isPaid ? Colors.grey.shade400 : btnBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: subtitleColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: _loadingPay
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: btnText,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isPaid ? 'Paid ✓' : 'Pay Now',
                            style: TextStyle(
                              color: _isPaid ? Colors.white : btnText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!_isPaid) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_circle_right,
                              color: btnText,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentWebView extends StatefulWidget {
  final String url;
  final String orderId;
  final Room room;

  const _PaymentWebView({
    required this.url,
    required this.orderId,
    required this.room,
  });

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
bool _paymentProcessed = false;

@override
void initState() {
  super.initState();
  _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) {
        if (request.url.startsWith('jaino://payment/success')) {
          Navigator.of(context).pop();
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ))
    ..loadRequest(Uri.parse(widget.url));
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}







