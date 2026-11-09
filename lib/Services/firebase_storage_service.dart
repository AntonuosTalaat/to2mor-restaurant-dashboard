import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:restaurantdashboard/firebase_options.dart';

import 'dart:io' if (dart.library.html) 'io_stub.dart';
import 'web_file_bytes_stub.dart'
    if (dart.library.html) 'web_file_bytes_web.dart';

class FirebaseStorageService {
  static Duration get uploadTimeout =>
      kIsWeb ? const Duration(seconds: 30) : const Duration(seconds: 10);

  final FirebaseStorage _storage;
  final Dio _dio;

  FirebaseStorageService({FirebaseStorage? storage, Dio? dio})
    : _storage = storage ?? _defaultStorage(),
      _dio = dio ?? Dio();

  static FirebaseStorage _defaultStorage() {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      return FirebaseStorage.instance;
    }
    final bucketUri = bucket.startsWith('gs://') ? bucket : 'gs://$bucket';
    return FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: bucketUri,
    );
  }

  Uint8List _compressImage(
    Uint8List bytes, {
    int quality = 70,
    int maxWidth = 800,
  }) {
    if (bytes.isEmpty) return bytes;
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return Uint8List.fromList(bytes);

      img.Image resized = image;
      if (image.width > maxWidth) {
        resized = img.copyResize(image, width: maxWidth);
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (_) {
      return Uint8List.fromList(bytes);
    }
  }

  Future<String> uploadImageBytes(
    Uint8List imageBytes,
    String fileName, {
    required String folderPath,
  }) async {
    if (imageBytes.isEmpty) {
      throw FirebaseStorageException('Image bytes cannot be empty');
    }

    final bytesToUpload = _compressImage(imageBytes);
    final sanitized = _sanitizeFileName(fileName);
    final path =
        '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$sanitized';
    final contentType = _contentTypeFromFileName(sanitized);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseStorageException('User not authenticated');
    }

    try {
      final token = await user.getIdToken(true).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw FirebaseStorageException(
          'انتهت مهلة التحقق من تسجيل الدخول',
        ),
      );

      if (kIsWeb) {
        return await _uploadViaRestApi(
          path: path,
          bytes: bytesToUpload,
          contentType: contentType,
          token: token!,
        );
      }

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putData(bytesToUpload, metadata);
      await uploadTask.timeout(
        uploadTimeout,
        onTimeout: () => throw FirebaseStorageException(
          'انتهت مهلة رفع الصورة — تأكد من تفعيل Storage ونشر storage.rules',
        ),
      );
      return await ref.getDownloadURL().timeout(uploadTimeout);
    } on FirebaseException catch (e) {
      throw FirebaseStorageException(
        'فشل رفع الصورة [${e.code}]: ${e.message ?? e.plugin}',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw FirebaseStorageException(
        'فشل رفع الصورة (HTTP $status): ${body ?? e.message}',
      );
    } on TimeoutException {
      throw FirebaseStorageException(
        'انتهت مهلة رفع الصورة — تحقق من CORS و storage.rules على المشروع',
      );
    } on FirebaseStorageException {
      rethrow;
    } catch (e) {
      throw FirebaseStorageException('فشل رفع الصورة: $e');
    }
  }

  /// رفع مباشر عبر REST على الويب — أوثق من putData مع الـ hosting.
  Future<String> _uploadViaRestApi({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String token,
  }) async {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      throw FirebaseStorageException('storageBucket غير مضبوط في Firebase');
    }

    final response = await _dio
        .post<Map<String, dynamic>>(
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o',
          queryParameters: {'name': path, 'uploadType': 'media'},
          data: bytes,
          options: Options(
            headers: {
              'Authorization': 'Firebase $token',
              'Content-Type': contentType,
            },
            responseType: ResponseType.json,
          ),
        )
        .timeout(uploadTimeout);

    final data = response.data;
    if (data == null) {
      throw FirebaseStorageException('رد فارغ من Firebase Storage');
    }

    final objectName = data['name'] as String?;
    final downloadToken = data['downloadTokens'] as String?;

    if (objectName != null && downloadToken != null) {
      final encodedName = Uri.encodeComponent(objectName);
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedName?alt=media&token=$downloadToken';
    }

    // fallback
    return _storage.ref().child(path).getDownloadURL().timeout(uploadTimeout);
  }

  Future<String> uploadImage(
    dynamic imageFile, {
    required String folderPath,
  }) async {
    if (kIsWeb) {
      if (imageFile is Uint8List) {
        return uploadImageBytes(
          imageFile,
          'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folderPath: folderPath,
        );
      }
      final bytes = await _readWebFileBytes(imageFile);
      final filename =
          imageFile.name ??
          'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return uploadImageBytes(bytes, filename, folderPath: folderPath);
    }

    if (imageFile is File) {
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split(RegExp(r'[/\\]')).last;
      return uploadImageBytes(bytes, filename, folderPath: folderPath);
    }

    if (imageFile is Uint8List) {
      return uploadImageBytes(
        imageFile,
        'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folderPath: folderPath,
      );
    }

    throw FirebaseStorageException(
      'Unsupported image type: ${imageFile.runtimeType}',
    );
  }

  Future<String> uploadItemImage(Uint8List bytes, String fileName) async {
    final uid = _requireUserId();
    return uploadImageBytes(
      bytes,
      fileName,
      folderPath: 'restaurants/$uid/items',
    );
  }

  Future<String> uploadExtraImage(Uint8List bytes, String fileName) async {
    final uid = _requireUserId();
    return uploadImageBytes(
      bytes,
      fileName,
      folderPath: 'restaurants/$uid/extras',
    );
  }

  Future<String> uploadLogoImage(
    Uint8List bytes,
    String fileName, {
    String? restaurantId,
  }) async {
    final uid = restaurantId ?? _requireUserId();
    return uploadImageBytes(
      bytes,
      fileName,
      folderPath: 'restaurants/$uid/logo',
    );
  }

  String _requireUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseStorageException('User not authenticated');
    }
    return uid;
  }

  Future<Uint8List> _readWebFileBytes(dynamic file) => readWebFileBytes(file);

  String _sanitizeFileName(String fileName) {
    final base = fileName.split('/').last.split('\\').last;
    final sanitized = base.replaceAll(RegExp(r'[^\w.\-]'), '_');
    return sanitized.isEmpty ? 'image.jpg' : sanitized;
  }

  String _contentTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class FirebaseStorageException implements Exception {
  final String message;

  FirebaseStorageException(this.message);

  @override
  String toString() => 'FirebaseStorageException: $message';
}
