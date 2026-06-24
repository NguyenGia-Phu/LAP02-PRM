import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPdfReport(Uint8List pdfBytes, String fileName) async {
    final ref = _storage.ref().child('reports/$fileName');
    final uploadTask = ref.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
