import 'package:flutter/material.dart';
import 'review.dart';

class ReviewView extends StatelessWidget {
  final ReviewState controller;

  const ReviewView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF70737D),
                      size: 16,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Reviews',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: controller.reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7150DB)),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load reviews',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
              ),
            );
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
              ),
            );
          }

          final total = reviews.length;
          final avgRating =
              reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int)) /
                  total;
          final Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (final r in reviews) {
            final star = r['rating'] as int;
            starCounts[star] = (starCounts[star] ?? 0) + 1;
          }

          return RefreshIndicator(
            color: const Color(0xFF7150DB),
            onRefresh: () async => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: i < avgRating.round()
                                    ? const Color(0xFFFFC107)
                                    : const Color(0xFFB7B9BC),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total review${total == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [5, 4, 3, 2, 1].map((star) {
                            final count = starCounts[star] ?? 0;
                            final fraction = count / total;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Text(
                                    '$star',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: fraction,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFEEEEEE),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                          Color(0xFF7150DB),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...reviews.map((r) => _ReviewCard(review: r)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rating = widget.review['rating'] as int;
    final comment = (widget.review['comment'] as String?) ?? '';
    final menuItem = widget.review['menu_item'] as String? ?? '';
    final userId = widget.review['user_id'] as String? ?? '';
    final createdAt = widget.review['created_at'] != null
        ? DateTime.tryParse(widget.review['created_at'].toString())
        : null;
    final dateStr = createdAt != null
        ? '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8E0FF),
                ),
                child: const Icon(Icons.person, color: Color(0xFF7150DB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userId.contains(':')
                          ? userId.split(':').first.replaceFirst('@', '')
                          : userId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 13,
                    color: i < rating
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFB7B9BC),
                  ),
                ),
              ),
            ],
          ),
          if (menuItem.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              menuItem,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7150DB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3C3C43),
                height: 1.5,
              ),
            ),
            if (comment.length > 80) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show Less' : 'Read More',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7150DB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _monthName(int m) => [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
        'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}