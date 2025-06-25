import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final String category;
  final double rating;
  final List<String> imageUrls;
  final VoidCallback onTap;

  const PropertyCard({
    Key? key,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrls,
    required this.onTap,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrls.isNotEmpty
                    ? imageUrls[0]
                    : 'https://via.placeholder.com/300',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating == 0 ? "N/A" : rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Text(location, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  // Price
                  if (category == 'Shopping' || category == 'Restaurant')
                    Text(
                      "À partir de " + price,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      category == 'Santé'
                          ? "Contactez-nous"
                          : category == 'Logement'
                          ? price + ' / nuit'
                          : price,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
