import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/training/training_service.dart';
import '../../models/training/training_models.dart';
import 'training_schedule_form_screen.dart';
import 'training_detail_screen.dart';

class TrainingScheduleListScreen extends StatefulWidget {
  const TrainingScheduleListScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScheduleListScreen> createState() =>
      _TrainingScheduleListScreenState();
}

class _TrainingScheduleListScreenState
    extends State<TrainingScheduleListScreen> {
  final TrainingService _trainingService = TrainingService();
  List<TrainingScheduleModel> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _trainingService.getSchedules();
    if (response.success && response.data != null) {
      setState(() {
        _schedules = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Error loading schedules'),
          ),
        );
      }
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
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: _loadSchedules,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Jadwal Training',
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
                              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.calendar_month,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Schedule List
                    _schedules.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada jadwal training',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final schedule = _schedules[index];

                                // Check if the schedule should be marked as expired
                                String currentStatus = schedule.status;
                                if (schedule.status == 'scheduled') {
                                  final now = DateTime.now();
                                  final scheduledDateTime = DateTime(
                                    schedule.scheduledDate.year,
                                    schedule.scheduledDate.month,
                                    schedule.scheduledDate.day,
                                  );
                                  final daysDifference = now
                                      .difference(scheduledDateTime)
                                      .inDays;

                                  if (daysDifference > 1) {
                                    currentStatus = 'expired';
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildGlassCard(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TrainingDetailScreen(
                                                  schedule: schedule,
                                                ),
                                          ),
                                        ).then((_) => _loadSchedules());
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header Row: Icon + Status
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      _getStatusColor(
                                                        currentStatus,
                                                      ),
                                                      _getStatusColor(
                                                        currentStatus,
                                                      ).withValues(alpha: 0.7),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _getStatusIcon(currentStatus),
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    currentStatus,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _formatStatus(currentStatus),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // Outlet Name
                                          Text(
                                            schedule.outletName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Schedule Details
                                          _buildInfoRow(
                                            Icons.calendar_today,
                                            'Tanggal',
                                            '${_formatDate(schedule.scheduledDate)} ${schedule.scheduledTime}',
                                            Colors.blue,
                                          ),

                                          if (schedule.trainerName != null) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.person,
                                              'Trainer',
                                              schedule.trainerName!,
                                              Colors.green,
                                            ),
                                          ],

                                          if (schedule.crewLeader != null &&
                                              schedule
                                                  .crewLeader!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.supervisor_account,
                                              'Crew Leader',
                                              schedule.crewLeader!,
                                              Colors.orange,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }, childCount: _schedules.length),
                            ),
                          ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrainingScheduleFormScreen(),
            ),
          ).then((_) => _loadSchedules());
        },
        icon: const Icon(
          Icons.add_circle_outline,
          size: 24,
          color: Colors.white,
        ),
        label: const Text(
          'Tambah Jadwal Training',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[500],
        elevation: 8,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Dijadwalkan';
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
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
                color: Color(0xFF4A90E2).withValues(alpha: 0.1),
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
}
