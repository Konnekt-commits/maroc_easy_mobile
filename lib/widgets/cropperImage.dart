import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class CropperFullScreenPage extends StatefulWidget {
  final Widget cropper;
  final Future<dynamic> Function() crop;
  final void Function(RotationAngle) rotate;

  const CropperFullScreenPage({
    required this.cropper,
    required this.crop,
    required this.rotate,
  });

  @override
  State<CropperFullScreenPage> createState() => CropperFullScreenPageState();
}

class CropperFullScreenPageState extends State<CropperFullScreenPage> {
  CropAspectRatioPreset _selectedRatio = CropAspectRatioPreset.square;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Recadrer l’image',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.white70),
              tooltip: "Réinitialiser",
              onPressed: () {
                setState(() {
                  _selectedRatio = CropAspectRatioPreset.original;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                final result = await widget.crop();
                Navigator.of(context).pop(result);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            "Pincer pour zoomer et déplacer",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.cropper,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          const Text(
            "Faites pivoter la photo",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          //_buildAspectRatioPicker(),
          const SizedBox(height: 10),
          _buildRotateControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAspectRatioPicker() {
    final ratios = {
      "1:1": CropAspectRatioPreset.square,
      "16:9": CropAspectRatioPreset.ratio16x9,
      "4:3": CropAspectRatioPreset.ratio4x3,
      "Original": CropAspectRatioPreset.original,
    };

    return Wrap(
      spacing: 12,
      children:
          ratios.entries.map((entry) {
            final selected = _selectedRatio == entry.value;
            return ChoiceChip(
              label: Text(
                entry.key,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedRatio = entry.value;
                });
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey.shade800,
            );
          }).toList(),
    );
  }

  Widget _buildRotateControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.rotate_left, color: Colors.white),
          tooltip: "Tourner à gauche",
          onPressed: () => widget.rotate(RotationAngle.counterClockwise90),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.rotate_right, color: Colors.white),
          tooltip: "Tourner à droite",
          onPressed: () => widget.rotate(RotationAngle.clockwise90),
        ),
      ],
    );
  }
}

/*
class CropperView extends StatelessWidget {
  final CropAspectRatioPreset preset;

  const CropperView({required this.preset});

  /// Retourne le ratio selon la sélection
  CropAspectRatio get aspectRatio {
    switch (preset) {
      case CropAspectRatioPreset.square:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
      case CropAspectRatioPreset.ratio16x9:
        return const CropAspectRatio(ratioX: 16, ratioY: 9);
      case CropAspectRatioPreset.ratio4x3:
        return const CropAspectRatio(ratioX: 4, ratioY: 3);
      case CropAspectRatioPreset.original:
      default:
        return const CropAspectRatio(ratioX: 1, ratioY: 1); // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageCropper().cropper(
      context: context,
      sourcePath: 'image_path_placeholder', // ne sera jamais utilisé (mock)
      uiSettings: [
        WebUiSettings(
          context: context,
          presentStyle: CropperPresentStyle.inline, // 👈 Important ici
          viewPort: aspectRatio,
          showZoomer: true,
        )
      ],
    );
  }
}*/
