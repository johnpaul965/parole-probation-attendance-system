import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';

class ActivityCreateScreen extends StatefulWidget {
  const ActivityCreateScreen({super.key});

  @override
  State<ActivityCreateScreen> createState() => _ActivityCreateScreenState();
}

class _ActivityCreateScreenState extends State<ActivityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  ActivityType _type = ActivityType.treePlanting;
  DateTime _schedule = DateTime.now().add(const Duration(days: 1));
  final Set<String> _selectedParolees = {};
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _schedule,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_schedule),
    );
    if (time == null || !mounted) return;
    setState(() {
      _schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParolees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one parolee')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user!;
    try {
      await context.read<ActivityProvider>().createActivity(
            title: _titleController.text.trim(),
            type: _type,
            description: _descController.text.trim(),
            location: _locationController.text.trim(),
            scheduleDate: _schedule,
            officerId: user.id,
            officerName: user.fullName,
            paroleeIds: _selectedParolees.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity created')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create activity')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parolees = context.watch<DashboardProvider>().parolees;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Activity')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<ActivityType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Activity Type'),
              items: ActivityType.values
                  .where((t) => t != ActivityType.other)
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Schedule'),
              subtitle: Text(_schedule.toLocal().toString().substring(0, 16)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDateTime,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Assign Parolees', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (parolees.isEmpty)
              const Text('No parolees assigned to you yet.', style: TextStyle(color: AppColors.textMuted))
            else
              ...parolees.map(
                (p) => CheckboxListTile(
                  value: _selectedParolees.contains(p.id),
                  title: Text(p.fullName),
                  subtitle: Text(p.caseNumber),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedParolees.add(p.id);
                      } else {
                        _selectedParolees.remove(p.id);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Activity'),
            ),
          ],
        ),
      ),
    );
  }
}
