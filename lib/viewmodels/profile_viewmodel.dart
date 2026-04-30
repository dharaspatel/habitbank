import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required ProfileService service,
    required this.userId,
    ImagePicker? picker,
  })  : _service = service,
        _picker = picker ?? ImagePicker();

  final ProfileService _service;
  final ImagePicker _picker;
  final String userId;

  UserProfile? _profile;
  bool _busy = false;
  String? _error;
  File? _pickedPhoto;

  UserProfile? get profile => _profile;
  bool get busy => _busy;
  String? get error => _error;
  File? get pickedPhoto => _pickedPhoto;

  Future<void> load() async {
    _busy = true;
    notifyListeners();
    try {
      _profile = await _service.get(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      _pickedPhoto = File(x.path);
      notifyListeners();
    }
  }

  Future<void> save({required String name}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      String? photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await _service.uploadPhoto(userId: userId, file: _pickedPhoto!);
      }
      _profile = await _service.upsert(
        userId: userId,
        name: name,
        photoUrl: photoUrl,
      );
      _pickedPhoto = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
