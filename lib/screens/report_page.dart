import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  static const String cloudName = 'cxteggal';
  static const String uploadPreset = 'campusfire_incidents';

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  String? selectedCategory;
  File? selectedImage;
  bool isSubmitting = false;

  final List<String> categories = [
    'Fire',
    'Safety concern',
    'Broken facility',
    'Water shortage',
    'Electricity outage',
    'Damaged furniture',
    'Sanitation problem',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // opening the photo options
  void showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Add a photograph',
                  style: TextStyle(
                    color: navy,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: PhotoOption(
                        title: 'Camera',
                        icon: Icons.camera_alt_outlined,
                        color: coral,
                        onPressed: () {
                          Navigator.pop(context);
                          pickImage(ImageSource.camera);
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: PhotoOption(
                        title: 'Gallery',
                        icon: Icons.photo_library_outlined,
                        color: mint,
                        onPressed: () {
                          Navigator.pop(context);
                          pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // selecting the incident photograph
  Future<void> pickImage(ImageSource source) async {
    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (error) {
      if (!mounted) return;

      showMessage('We could not open the selected image.', Colors.red);
    }
  }

  // removing the selected photograph
  void removeImage() {
    setState(() {
      selectedImage = null;
    });
  }

  // uploading the image to Cloudinary
  Future<Map<String, String>> uploadImage(File image) async {
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uploadUrl);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'campusfire/incidents';

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 40),
    );

    final response = await http.Response.fromStream(streamedResponse);

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message =
          responseData['error']?['message'] ??
          'The photograph could not be uploaded.';

      throw Exception(message);
    }

    return {
      'imageUrl': responseData['secure_url'] as String,
      'publicId': responseData['public_id'] as String,
    };
  }

  // submitting the incident report
  Future<void> submitReport() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'You need to sign in before reporting an incident.',
        Colors.red,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSubmitting = true;
    });

    try {
      String imageUrl = '';
      String imagePublicId = '';

      // uploading the selected photograph
      if (selectedImage != null) {
        final imageResult = await uploadImage(selectedImage!);

        imageUrl = imageResult['imageUrl'] ?? '';
        imagePublicId = imageResult['publicId'] ?? '';
      }

      final firestore = FirebaseFirestore.instance;
      final incidentReference = firestore.collection('incidents').doc();
      final notificationReference = firestore.collection('notifications').doc();

      final batch = firestore.batch();

      // saving the incident
      batch.set(incidentReference, {
        'id': incidentReference.id,
        'title': titleController.text.trim(),
        'category': selectedCategory,
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,
        'reportedBy': user.uid,
        'reporterName': user.displayName ?? 'CampusFire User',
        'reporterEmail': user.email ?? '',
        'status': 'Submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // creating the notification
      batch.set(notificationReference, {
        'userId': user.uid,
        'incidentId': incidentReference.id,
        'title': 'Report submitted',
        'message': '${titleController.text.trim()} was submitted successfully.',
        'type': 'incident_submitted',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit().timeout(const Duration(seconds: 25));

      if (!mounted) return;

      showMessage(
        'Your incident report was submitted successfully.',
        Colors.green,
      );

      formKey.currentState!.reset();
      titleController.clear();
      locationController.clear();
      descriptionController.clear();

      setState(() {
        selectedCategory = null;
        selectedImage = null;
      });
    } on TimeoutException {
      if (!mounted) return;

      showMessage(
        'The request took too long. Check your connection and try again.',
        Colors.red,
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('Report submission error: $error');

      showMessage(error.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // showing a message to the user
  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report an Incident',
                style: TextStyle(
                  color: navy,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Provide clear information so the campus team can respond quickly.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: coral),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If anyone is in immediate danger, contact campus security before submitting this form.',
                        style: TextStyle(
                          color: navy,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withValues(alpha: 0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(
                      title: 'Incident photograph',
                      optional: true,
                    ),

                    const SizedBox(height: 10),

                    IncidentImageFrame(
                      selectedImage: selectedImage,
                      onAddPressed: showPhotoOptions,
                      onRemovePressed: removeImage,
                    ),

                    const SizedBox(height: 22),

                    const FormLabel(title: 'Incident title'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: inputDecoration(
                        hint: 'Example: Smoke near the kitchen',
                        icon: Icons.title,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter an incident title.';
                        }

                        if (value.trim().length < 5) {
                          return 'Provide a clearer title.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    const FormLabel(title: 'Category'),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedCategory),
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: inputDecoration(
                        hint: 'Select a category',
                        icon: Icons.category_outlined,
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Select an incident category.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    const FormLabel(title: 'Location'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: locationController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: inputDecoration(
                        hint: 'Example: Learning Commons, Floor 2',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the incident location.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    const FormLabel(title: 'Description'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 500,
                      decoration: inputDecoration(
                        hint: 'Describe what happened and what you observed.',
                        icon: Icons.notes_outlined,
                        alignIconTop: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe the incident.';
                        }

                        if (value.trim().length < 15) {
                          return 'Provide a little more detail.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: coral,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: coral.withValues(
                            alpha: 0.55,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submitting report...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_outlined, size: 20),
                                  SizedBox(width: 9),
                                  Text(
                                    'Submit Report',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    bool alignIconTop = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignIconTop ? 80 : 0),
        child: Icon(icon),
      ),
      filled: true,
      fillColor: background,
      counterStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class FormLabel extends StatelessWidget {
  final String title;
  final bool optional;

  const FormLabel({super.key, required this.title, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ReportPageState.navy,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          const Text(
            '(optional)',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class IncidentImageFrame extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onAddPressed;
  final VoidCallback onRemovePressed;

  const IncidentImageFrame({
    super.key,
    required this.selectedImage,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedImage == null) {
      return InkWell(
        onTap: onAddPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 185,
          decoration: BoxDecoration(
            color: _ReportPageState.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD5DDE6), width: 1.4),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFFFE8E2),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: _ReportPageState.coral,
                  size: 29,
                ),
              ),
              SizedBox(height: 13),
              Text(
                'Add a photograph',
                style: TextStyle(
                  color: _ReportPageState.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Take a photo or choose one from your gallery',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(selectedImage!, fit: BoxFit.cover),

            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  PhotoActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: onAddPressed,
                  ),
                  const SizedBox(width: 8),
                  PhotoActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onPressed: onRemovePressed,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Photo added',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const PhotoOption({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 31),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                color: _ReportPageState.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const PhotoActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = _ReportPageState.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
