import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../services/local_storage.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _habitService = HabitService();
  bool _isLoading = false;
  
  // Reminder time
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    // STATE RESTORATION: Load draft habit if exists
    _loadDraftHabit();
  }

  @override
  void dispose() {
    // STATE RESTORATION: Save draft if user exits without submitting
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty) {
      _saveDraftHabit();
    }
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadDraftHabit() {
    final draft = LocalStorageService.getDraftHabit();
    if (draft != null) {
      setState(() {
        _nameController.text = draft['name'] ?? '';
        _descriptionController.text = draft['description'] ?? '';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📝 Draft restored from last session'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _saveDraftHabit() {
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty) {
      LocalStorageService.saveDraftHabit(
        name: _nameController.text,
        description: _descriptionController.text,
      );
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _submitHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final habit = Habit(
        id: '',
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        streak: 0,
        createdAt: DateTime.now(),
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
      );

      await _habitService.addHabit(habit);

      // STATE RESTORATION: Clear draft after successful creation
      await LocalStorageService.clearDraftHabit();

      // Increment total habits created counter
      await LocalStorageService.incrementHabitsCreated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Habit created! Reminder set for ${_reminderTime.format(context)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear draft',
            onPressed: () {
              setState(() {
                _nameController.clear();
                _descriptionController.clear();
                _reminderTime = const TimeOfDay(hour: 9, minute: 0);
              });
              LocalStorageService.clearDraftHabit();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft cleared')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your progress is automatically saved',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Habit Name',
                    hintText: 'e.g., Morning Meditation',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.track_changes),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a habit name';
                    }
                    return null;
                  },
                  onChanged: (_) => _saveDraftHabit(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g., Meditate for 10 minutes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onChanged: (_) => _saveDraftHabit(),
                ),
                const SizedBox(height: 16),
                
                // REMINDER TIME PICKER
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active, color: Colors.deepPurple),
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      'Remind me at ${_reminderTime.format(context)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _selectReminderTime,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // POINTS INFO CARD
                Card(
                  elevation: 2,
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Points System',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPointsRow('Days 1-2', '10 points'),
                        _buildPointsRow('Days 3-6', '15 points'),
                        _buildPointsRow('Days 7-29', '20 points'),
                        _buildPointsRow('Days 30-99', '30 points'),
                        _buildPointsRow('Day 100+', '50 points', isHighlight: true),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitHabit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Habit',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsRow(String streak, String points, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            streak,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.amber.shade900 : Colors.black87,
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.amber.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
