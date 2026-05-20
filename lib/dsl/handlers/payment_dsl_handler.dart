import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

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
        isDisabled: false,
      ),
    );
  }
 DSLRenderResult renderWithTimeline(Event event, DSLMessage msg, List<Event> timelineEvents) {
  final amount       = msg.get<int>('amount') ?? 0;
  final currency     = msg.get<String>('currency') ?? 'PKR';
  final orderId      = msg.get<String>('order_id') ?? '';
  final paymentUrl   = msg.get<String>('payment_url') ?? '';
  final customerName = msg.get<String>('customer_name') ?? '';
  final room         = event.room;

  final isPaid = timelineEvents.any((e) =>
    e.type == EventTypes.Message &&
    (e.content['body'] as String? ?? '').contains('Payment confirmed') &&
    e.originServerTs.isAfter(event.originServerTs)
  );

  final isLatest = !timelineEvents.any((e) {
    if (e.eventId == event.eventId) return false;
    final dsl = e.content['com.jaino.dsl'] as Map<String, dynamic>?;
    if (dsl == null) return false;
    if (dsl['type'] != 'payment') return false;
    final data = dsl['data'] as Map<String, dynamic>?;
    if (data == null) return false;
    return data['order_id'] == orderId &&
        e.originServerTs.isAfter(event.originServerTs);
  });

  final isDisabled = isPaid || !isLatest;

  return DSLRenderResult(
    widget: _PaymentCard(
      amount: amount,
      currency: currency,
      orderId: orderId,
      paymentUrl: paymentUrl,
      customerName: customerName,
      room: room,
      senderUserId: room.client.userID ?? '',
      isDisabled: isDisabled,
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
  final bool isDisabled;

  const _PaymentCard({
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.paymentUrl,
    required this.customerName,
    required this.room,
    required this.senderUserId,
    required this.isDisabled,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _loadingPay = false;

  Future<void> _openPayment() async {
  setState(() => _loadingPay = true);
  try {
    // Just open the payment_url directly — bot already created the transaction
    if (widget.paymentUrl.isEmpty) {
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
            url: widget.paymentUrl,
            orderId: widget.orderId,
            room: widget.room,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Try again.')),
      );
    }
  } finally {
    if (mounted) setState(() => _loadingPay = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor     = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor    = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = const Color(0xFFC9C9C9);
    final btnBg         = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final btnText       = isDark ? Colors.white : const Color(0xFF1A1A1A);

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
            'Complete your payment',
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
  onTap: (_loadingPay || widget.isDisabled) ? null : _openPayment,
  child: Container(
    width: double.infinity,
    height: 32,
    decoration: BoxDecoration(
      color: widget.isDisabled ? Colors.grey.shade400 : btnBg,
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
                  widget.isDisabled ? 'Paid ✓' : 'Pay Now',
                  style: TextStyle(
                    color: widget.isDisabled ? Colors.white : btnText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!widget.isDisabled) ...[
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







