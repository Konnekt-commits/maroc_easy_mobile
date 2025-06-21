import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoaderVille extends StatelessWidget {
  const LoaderVille({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 5),
            width: 120,
            height: 120,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class LoaderDecouverte extends StatelessWidget {
  const LoaderDecouverte({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          width: double.infinity,
          height: 300,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class LoaderCategorieAdmin extends StatelessWidget {
  const LoaderCategorieAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          width: double.infinity,
          height: 60,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class LoaderCategory extends StatelessWidget {
  const LoaderCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                width: 30,
                height: 20,
                color: Colors.grey,
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                width: 70,
                height: 10,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoaderAnnonce extends StatelessWidget {
  const LoaderAnnonce({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          width: double.infinity,
          height: 250,
          color: Colors.grey,
        ),
      ),
    );
  }
}
