import 'package:flutter/material.dart';

class BikeCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String imagePath;
  final String timeAgo;
  final List<String> tags;
  final double? width;
  final VoidCallback? onTap;

  const BikeCard({
    super.key,
    this.title = '2021 Royal Enfield Hunter 350',
    this.price = '₹1.85 Lakh',
    this.location = 'Madhya Pradesh 458468',
    this.imagePath = 'assets/images/bike.png',
    this.timeAgo = '10 days ago',
    this.tags = const ['15,000 km', 'Petrol', '350cc'],
    this.width = 165,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/bike_detail'),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike Image
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      imagePath,
                      height: 85,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Container(
                        height: 110,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/Path 3392.png', height: 16, width: 16),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0C0E1B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: tags
                        .map((tag) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildInfoTag(tag),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Color(0xFF262A36), fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2E4475)),
                      ),
                      Text(timeAgo, style: TextStyle(color: Colors.grey.shade400, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.w500)),
    );
  }
}
