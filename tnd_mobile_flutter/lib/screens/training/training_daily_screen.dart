import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/training/training_service.dart';
import '../../models/training/training_models.dart';
import 'training_session_checklist_screen.dart';

class TrainingDailyScreen extends StatefulWidget {
  final TrainingScheduleModel? schedule;

  const TrainingDailyScreen({Key? key, this.schedule}) : super(key: key);

  @override
  State<TrainingDailyScreen> createState() => _TrainingDailyScreenState();
}

class _TrainingDailyScreenState extends State<TrainingDailyScreen> {
  final TrainingService _trainingService = TrainingService();
  TrainingScheduleModel? _selectedSchedule;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use the passed schedule if available, otherwise load schedules for today
    if (widget.schedule != null) {
      _selectedSchedule = widget.schedule;
      _isLoading = false;
    } else {
      _loadTodaySchedules();
    }
  }

  Future<void> _loadTodaySchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now();
      final response = await _trainingService.getSchedules();
      print(
        'DEBUG DAILY: Got ${response.data?.length ?? 0} schedules from API',
      );
      if (response.success && response.data != null) {
        // Debug: Print first schedule data
        if (response.data!.isNotEmpty) {
          final first = response.data!.first;
          print('DEBUG DAILY: First schedule data:');
          print('  - id: ${first.id}');
          print('  - outletName: ${first.outletName}');
          print('  - crewLeader: ${first.crewLeader}');
          print('  - crewName: ${first.crewName}');
          print('  - status: ${first.status}');
        }
        // Filter schedules for today that are scheduled or ongoing (NOT completed)
        final todaySchedules = response.data!.where((schedule) {
          // Check if this is a schedule for today
          bool isToday =
              schedule.scheduledDate.year == today.year &&
              schedule.scheduledDate.month == today.month &&
              schedule.scheduledDate.day == today.day;

          // Also check for expired schedules (past schedules that are still marked as 'scheduled')
          bool isPastAndScheduled =
              schedule.scheduledDate.isBefore(today) &&
              schedule.status == 'scheduled';

          // Only show if status is 'scheduled' or 'ongoing', NOT 'completed'
          bool isNotCompleted = schedule.status != 'completed';

          return ((isToday && isNotCompleted) || isPastAndScheduled);
        }).toList();

        setState(() {
          // If there's only one schedule for today, use it as the selected one
          if (todaySchedules.length == 1) {
            _selectedSchedule = todaySchedules.first;
          } else if (todaySchedules.isNotEmpty) {
            // If multiple schedules for today, just set the first one or let user choose
            _selectedSchedule = todaySchedules.first;
          } else {
            // If no schedules for today, set as null
            _selectedSchedule = null;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Gagal memuat jadwal training hari ini';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Daily Training',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.today,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadTodaySchedules,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTodaySchedules,
                      child: _errorMessage != null
                          ? SizedBox(
                              height: 400,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : _selectedSchedule != null
                          ? _buildScheduleCard(_selectedSchedule!)
                          : SizedBox(
                              height: 400,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 60,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada jadwal training hari ini',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Jadwal training belum dibuat atau sudah selesai',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(TrainingScheduleModel schedule) {
    // Determine the status considering if it's expired
    String currentStatus = schedule.status;
    if (schedule.status == 'scheduled') {
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        schedule.scheduledDate.year,
        schedule.scheduledDate.month,
        schedule.scheduledDate.day,
      );
      final daysDifference = now.difference(scheduledDateTime).inDays;

      if (daysDifference > 1) {
        // More than 1 day past the scheduled date
        currentStatus = 'expired';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with outlet name and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.outletName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatus(currentStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Trainer info
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  'Trainer: ${schedule.trainerName ?? '-'}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            // Crew Leader info
            if (schedule.crewLeader != null &&
                schedule.crewLeader!.isNotEmpty &&
                schedule.crewLeader != 'TBD')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      'Crew Leader: ${schedule.crewLeader}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Date and time info
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${schedule.scheduledDate.day}/${schedule.scheduledDate.month}/${schedule.scheduledDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        schedule.scheduledTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _navigateToScheduleDetail(schedule);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5C6BC0),
                            Color(0xFF5C6BC0).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF5C6BC0).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (currentStatus == 'scheduled') {
                        _startTraining(schedule);
                      } else if (currentStatus == 'ongoing' ||
                          currentStatus == 'expired') {
                        _continueTraining(schedule);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              (currentStatus == 'ongoing' ||
                                  currentStatus == 'expired')
                              ? [
                                  Color(0xFF5C6BC0),
                                  Color(0xFF5C6BC0).withValues(alpha: 0.8),
                                ]
                              : [
                                  Color(0xFF7E57C2),
                                  Color(0xFF7E57C2).withValues(alpha: 0.8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (currentStatus == 'ongoing' ||
                                    currentStatus == 'expired')
                                ? Color(0xFF5C6BC0).withValues(alpha: 0.3)
                                : Color(0xFF7E57C2).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            (currentStatus == 'ongoing' ||
                                    currentStatus == 'expired')
                                ? 'Lanjutkan'
                                : 'Mulai',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF5C6BC0).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange; // Using orange to indicate expired/past due
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Dijadwalkan';
      case 'ongoing':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  void _navigateToScheduleDetail(TrainingScheduleModel schedule) {
    // Navigate to schedule detail screen
    // This would depend on what specific screen is needed for schedule details
    // For now, showing a basic alert
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Jadwal: ${schedule.outletName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tanggal: ${schedule.scheduledDate.day}/${schedule.scheduledDate.month}/${schedule.scheduledDate.year}',
              ),
              Text('Waktu: ${schedule.scheduledTime}'),
              Text('Status: ${_formatStatus(schedule.status)}'),
              Text('Trainer: ${schedule.trainerName ?? '-'}'),
              if (schedule.crewLeader != null)
                Text('Crew Leader: ${schedule.crewLeader}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _startTraining(TrainingScheduleModel schedule) async {
    // Implementation for starting a training session from a schedule
    // First, we need to create or start a session based on the schedule
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Memulai sesi training..."),
              ],
            ),
          );
        },
      );

      // Start the training session by changing status from 'scheduled' to 'ongoing'
      final response = await _trainingService.startTrainingSession(
        sessionId: schedule.id,
      );

      print(
        'Response from _trainingService.startTrainingSession: ${response.success}, ${response.message}, ${response.data}',
      ); // Add this line

      if (response.success) {
        // Navigate to the training checklist screen to begin the training
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Create a temporary TrainingSessionModel based on the schedule
          final tempSession = TrainingSessionModel(
            id: schedule.id, // Using schedule ID as session ID
            scheduleId: schedule.id,
            outletId: schedule.outletId,
            outletName: schedule.outletName,
            sessionDate: schedule.scheduledDate,
            trainerId: schedule.trainerId,
            trainerName: schedule.trainerName,
            crewLeaderId: schedule.trainerId != null
                ? schedule.trainerId.toString()
                : null, // Using trainer ID as crew leader ID temporarily, converting to string
            crewLeaderName:
                schedule.crewLeader, // Using crew leader from schedule
            crewName: schedule.crewName, // Using crew name from schedule
            status: 'ongoing', // Updated status
            startedAt: DateTime.now(), // Current time as start time
            completedAt: null,
            revisionNotes: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to the training checklist screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TrainingSessionChecklistScreen(session: tempSession),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal memulai training'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _continueTraining(TrainingScheduleModel schedule) async {
    // Implementation for continuing ongoing training
    // Create a temporary TrainingSessionModel based on the schedule
    final tempSession = TrainingSessionModel(
      id: schedule.id, // Using schedule ID as session ID
      scheduleId: schedule.id,
      outletId: schedule.outletId,
      outletName: schedule.outletName,
      sessionDate: schedule.scheduledDate,
      trainerId: schedule.trainerId,
      trainerName: schedule.trainerName,
      crewLeaderId: schedule.trainerId
          ?.toString(), // Using trainer ID as crew leader ID temporarily, converting to string
      crewLeaderName:
          schedule.crewLeader ??
          'Crew Leader', // Using crew leader from schedule with fallback
      crewName: schedule.crewName, // Using crew name from schedule
      status: schedule.status, // Keep current status
      startedAt: DateTime.now(), // Current time as start time
      completedAt: null,
      revisionNotes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to the training checklist screen to continue the training
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TrainingSessionChecklistScreen(session: tempSession),
      ),
    );
  }
}
