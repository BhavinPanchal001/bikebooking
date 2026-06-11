import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

enum CropAspectRatioPresetType {
  square,
  freeStyle,
  landscape,
}

class ImageCropHelper {
  ImageCropHelper._();
  
  static Future<XFile?> cropImage({
    required XFile sourceFile,
    CropAspectRatioPresetType aspectRatio = CropAspectRatioPresetType.freeStyle,
    bool lockAspectRatio = false,
  }) async {
    final presets = _presetsFor(aspectRatio);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourceFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF233A66),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF233A66),
          statusBarColor: const Color(0xFF233A66),
          initAspectRatio: presets.first,
          lockAspectRatio: lockAspectRatio,
          aspectRatioPresets: presets,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: lockAspectRatio,
          aspectRatioPresets: presets,
          resetAspectRatioEnabled: !lockAspectRatio,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return XFile(croppedFile.path);
  }

  static List<CropAspectRatioPreset> _presetsFor(
    CropAspectRatioPresetType type,
  ) {
    switch (type) {
      case CropAspectRatioPresetType.square:
        return [CropAspectRatioPreset.square];
      case CropAspectRatioPresetType.landscape:
        return [
          CropAspectRatioPreset.ratio16x9,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.original,
        ];
      case CropAspectRatioPresetType.freeStyle:
        return [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ];
    }
  }
}
