
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// import '../../core/services/api_service.dart';
import 'verification_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({
    super.key,
  });

  @override
  State<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState
    extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _drivingLicense;
  File? _nationalId;
  File? _vehicleDocument;

  bool _isLoading = false;

  Future<void> _pickDocument({
    required String documentType,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        final file = File(pickedFile.path);

        switch (documentType) {
          case 'license':
            _drivingLicense = file;
            break;

          case 'national_id':
            _nationalId = file;
            break;

          case 'vehicle':
            _vehicleDocument = file;
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select document: $e',
      );
    }
  }

  Future<void> _submitDocuments() async {
    if (_drivingLicense == null ||
        _nationalId == null ||
        _vehicleDocument == null) {
      _showMessage(
        'Please upload all required documents.',
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * We are not calling document-upload API methods yet
       * because the current ApiService you showed does not
       * contain those endpoints.
       *
       * Once the backend document endpoints are ready,
       * we will connect them here.
       */

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const VerificationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onUpload,
  }) {
    final uploaded = file != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Icon(icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  uploaded
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: uploaded
                      ? Colors.green
                      : null,
                ),
              ],
            ),

            if (uploaded) ...[
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(10),
                child: Image.file(
                  file,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isLoading ? null : onUpload,
                icon: Icon(
                  uploaded
                      ? Icons.refresh
                      : Icons.upload,
                ),
                label: Text(
                  uploaded
                      ? 'Replace Document'
                      : 'Upload Document',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUploaded =
        _drivingLicense != null &&
        _nationalId != null &&
        _vehicleDocument != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Documents',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const Icon(
                Icons.description_outlined,
                size: 70,
              ),

              const SizedBox(height: 16),

              const Text(
                'Upload Your Documents',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Upload clear photos of your documents. '
                'RydeX will review them before you can start receiving rides.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              _documentCard(
                title: 'Driving License',
                subtitle:
                    'Upload a clear photo of your driving license.',
                icon: Icons.badge_outlined,
                file: _drivingLicense,
                onUpload: () {
                  _pickDocument(
                    documentType: 'license',
                  );
                },
              ),

              _documentCard(
                title: 'National ID',
                subtitle:
                    'Upload a clear photo of your national ID.',
                icon: Icons.credit_card,
                file: _nationalId,
                onUpload: () {
                  _pickDocument(
                    documentType: 'national_id',
                  );
                },
              ),

              _documentCard(
                title: 'Vehicle Document',
                subtitle:
                    'Upload the required vehicle document.',
                icon: Icons.directions_car,
                file: _vehicleDocument,
                onUpload: () {
                  _pickDocument(
                    documentType: 'vehicle',
                  );
                },
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  color: Colors.orange.withValues(
                    alpha: 0.1,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your documents are clear, readable, and belong to you. Incorrect or unclear documents may delay verification.',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || !allUploaded
                          ? null
                          : _submitDocuments,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SUBMIT DOCUMENTS',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
