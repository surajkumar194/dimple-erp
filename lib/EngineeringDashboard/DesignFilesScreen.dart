import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DesignFilesScreen extends StatefulWidget {
  const DesignFilesScreen({super.key});

  @override
  State<DesignFilesScreen> createState() => _DesignFilesScreenState();
}

class _DesignFilesScreenState extends State<DesignFilesScreen> {
  void _showFileDialog() {
    final fileNameController = TextEditingController();
    final productController = TextEditingController();
    final versionController = TextEditingController();
    final descriptionController = TextEditingController();
    String fileType = 'CAD';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Design File'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'File Name',
                    prefixIcon: Icon(Icons.insert_drive_file),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: productController,
                  decoration: const InputDecoration(
                    labelText: 'Related Product',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fileType,
                  decoration: const InputDecoration(
                    labelText: 'File Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['CAD', 'PDF', 'Image', '3D Model', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => fileType = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: versionController,
                  decoration: const InputDecoration(
                    labelText: 'Version',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (fileNameController.text.isEmpty ||
                    productController.text.isEmpty ||
                    versionController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('designFiles').add({
                    'fileName': fileNameController.text,
                    'product': productController.text,
                    'fileType': fileType,
                    'version': versionController.text,
                    'description': descriptionController.text,
                    'uploadDate': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Design file added')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Files'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('designFiles')
            .orderBy('uploadDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No design files',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var file = doc.data() as Map<String, dynamic>;

              // Safely parse date
              DateTime? uploadDate;
              if (file['uploadDate'] != null) {
                if (file['uploadDate'] is Timestamp) {
                  uploadDate = (file['uploadDate'] as Timestamp).toDate();
                } else if (file['uploadDate'] is DateTime) {
                  uploadDate = file['uploadDate'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00BCD4),
                    child: Icon(
                      _getFileIcon(file['fileType'] ?? 'Other'),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    file['fileName'] ?? 'Untitled File',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${file['product'] ?? 'N/A'} | v${file['version'] ?? '1.0'}',
                  ),
                  trailing: Chip(
                    label: Text(
                      file['fileType'] ?? 'Other',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(file['fileName'] ?? 'File Details'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Product: ${file['product'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Type: ${file['fileType'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Version: ${file['version'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('Description: ${file['description'] ?? 'No description'}'),
                            if (uploadDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Uploaded: ${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFileDialog,
        icon: const Icon(Icons.upload_file),
        label: const Text('Add File'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'CAD':
        return Icons.architecture;
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Image':
        return Icons.image;
      case '3D Model':
        return Icons.view_in_ar;
      default:
        return Icons.insert_drive_file;
    }
  }
}