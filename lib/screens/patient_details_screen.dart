import 'dart:typed_data';

import 'package:clinitrack/widgets/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/expandable_record_section.dart';
import '../providers/patient_provider.dart';
import 'package:provider/provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/appointment_provider.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 40),
        title: const Text('Delete Patient'),
        content: Text(
          "Are you sure you want to delete ${patient.name}'s record? This action cannot be undone.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          SizedBox(height: 7,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PatientProvider>().deletePatient(patient.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${patient.name} deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = ModalRoute.of(context)?.settings.arguments as Patient?;

    if (patient == null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Medical Record')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No patient record found.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
            onPressed: () => _confirmDelete(context, patient),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Patient header ----------
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  patient.name.isNotEmpty ? patient.name.substring(0, 1) : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age} yrs, ${patient.gender}  |  ${patient.bloodGroup}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text('Phone: ${patient.contact}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/add-prescription', arguments: patient),
                  icon: const Icon(Icons.medication_outlined, size: 18),
                  label: const Text('Prescribe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/follow-up', arguments: patient),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Follow-up'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- Medical History ----------
          Text('Medical History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                patient.medicalHistory.isEmpty ? 'No medical history recorded.' : patient.medicalHistory,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Allergies ----------
          Text('Allergies', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: patient.allergies.isEmpty
                    ? Text('No known allergies.', style: Theme.of(context).textTheme.bodyLarge)
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: patient.allergies
                      .map((a) => Chip(
                    label: Text(a, style: TextStyle(fontSize: 13, color: accent)),
                    backgroundColor: accent.withValues(alpha: isDark ? 0.15 : 0.10),
                    side: BorderSide(color: accent.withValues(alpha: isDark ? 0.35 : 0.22)),
                  ))
                      .toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // ---------- Expandable sections ----------
          Consumer<PrescriptionProvider>(
            builder: (context, prescriptionProvider, _) {
              final items = prescriptionProvider
                  .forPatient(patient.id)
                  .map((p) => p.summary)
                  .toList();
              return ExpandableRecordSection(
                title: 'Prescriptions',
                items: items,
              );
            },
          ),
          Consumer<AppointmentProvider>(
            builder: (context, appointmentProvider, _) {
              final items = appointmentProvider
                  .visitHistoryForPatient(patient.id)
                  .map((a) => '${a.date} • ${a.time} — ${a.reason} (${a.doctor})')
                  .toList();
              return ExpandableRecordSection(
                title: 'Visit History',
                items: items,
              );
            },
          ),
          const SizedBox(height: 16),

          // ---------- Attachments (Step 16: Supabase Storage) ----------
          Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _AttachmentsSection(patient: patient),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 16: patient files in the private `attachments` bucket
/// (`attachments/{uid}/{patientId}/{file}`), opened via signed URLs.
class _AttachmentsSection extends StatefulWidget {
  final Patient patient;

  const _AttachmentsSection({required this.patient});

  @override
  State<_AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<_AttachmentsSection> {
  List<String> _files = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!StorageService.useBackend) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final files =
          await StorageService.listAttachments(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } on StorageFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _upload() async {
    if (_isUploading) return;
    final picked = await FilePicker.pickFiles();
    if (!mounted) return;
    if (picked.isEmpty) return;
    final file = picked.single;
    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file')),
      );
      return;
    }
    if (!mounted) return;
    if (bytes.length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File must be under 10 MB')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final stored = await StorageService.uploadAttachment(
        patientId: widget.patient.id,
        fileName: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _files = [..._files, stored];
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } on StorageFailure catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _open(String name) async {
    try {
      final url = await StorageService.attachmentUrl(
        widget.patient.id,
        name,
      );
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } on StorageFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await StorageService.deleteAttachment(widget.patient.id, name);
      if (!mounted) return;
      setState(() => _files = _files.where((f) => f != name).toList());
    } on StorageFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!StorageService.useBackend) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'File attachments need Supabase configured.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        color: AppColors.errorRed),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_files.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No files yet. Upload reports, scans or prescriptions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final name in _files)
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(_iconFor(name),
                      color: AppColors.primaryTeal),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.errorRed),
                    onPressed: () => _delete(name),
                  ),
                  onTap: () => _open(name),
                ),
            const Divider(),
            TextButton.icon(
              onPressed: _isUploading ? null : _upload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                  _isUploading ? 'Uploading…' : 'Upload file'),
            ),
          ],
        ),
      ),
    );
  }
}