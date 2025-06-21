import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final String name;
  final String date;
  final String duration;
  final String comment;
  final String language;
  final String years;
  final String avatar;
  final bool isImage;
  final double rate;
  final bool canModify;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.name,
    required this.date,
    required this.duration,
    required this.comment,
    required this.language,
    required this.years,
    required this.avatar,
    this.isImage = false,
    required this.rate,
    this.canModify = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du commentaire (avatar, nom, etc.)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  isImage
                      ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(avatar),
                      )
                      : CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: Text(
                          avatar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        years,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              // Add edit/delete options if user can modify
              if (canModify)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      iconSize: 20,
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Note et date
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  if (index < rate.floor()) {
                    // Full star
                    return const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    );
                  } else if (index == rate.floor() &&
                      rate - rate.floor() >= 0.5) {
                    // Half star
                    return const Icon(
                      Icons.star_half,
                      size: 16,
                      color: Colors.amber,
                    );
                  } else {
                    // Empty star
                    return const Icon(
                      Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }
                }),
              ),
              const SizedBox(width: 8),
              Text('· $date', style: TextStyle(color: Colors.grey[700])),
            ],
          ),

          const SizedBox(height: 8),

          // Contenu du commentaire
          Text(comment, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
