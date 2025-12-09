import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/outlet_model.dart';
import '../models/visit_model.dart';
import '../services/outlet_service.dart';
import '../services/visit_service.dart';
import 'visit_category_list_screen.dart';
import 'visit_detail_screen.dart';

class StartVisitScreen extends StatefulWidget {
  final UserModel currentUser;

  const StartVisitScreen({super.key, required this.currentUser});

  @override
  State<StartVisitScreen> createState() => _StartVisitScreenState();
}

class _StartVisitScreenState extends State<StartVisitScreen> {
  final _outletService = OutletService();
  
  List<OutletModel> _outlets = [];
  List<OutletModel> _filteredOutlets = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOutlets() async {
    setState(() => _isLoading = true);
    try {
      // Filter outlets by user's division (with no limit to show all)
      final response = await _outletService.getOutlets(
        divisionId: widget.currentUser.divisionId,
        limit: -1, // Get all outlets instead of just 10
      );
      if (response.success && response.data != null) {
        setState(() {
          _outlets = response.data!;
          _filteredOutlets = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to load outlets'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading outlets: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOutlets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOutlets = _outlets;
      } else {
        _filteredOutlets = _outlets.where((outlet) {
          return outlet.name.toLowerCase().contains(query.toLowerCase()) ||
              outlet.code.toLowerCase().contains(query.toLowerCase()) ||
              (outlet.address?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOutlets,
          child: CustomScrollView(
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello ${widget.currentUser.name.split(' ')[0]}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Welcome Back !',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () {
                                // TODO: Show notifications
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Action Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Action',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Info Card (replacing the gradient card)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withAlpha(179),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withAlpha(77),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Begin Your Outlet Visit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Select an outlet below to start',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterOutlets,
                      decoration: InputDecoration(
                        hintText: 'Search outlets...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Outlets Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Outlet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_filteredOutlets.length} outlets',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Outlets List
              _isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )
                  : _filteredOutlets.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No outlets available'
                                        : 'No outlets found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final outlet = _filteredOutlets[index];
                                return _buildOutletCard(outlet);
                              },
                              childCount: _filteredOutlets.length,
                            ),
                          ),
                        ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutletCard(OutletModel outlet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withAlpha(51),
                Theme.of(context).primaryColor.withAlpha(26),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.store,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          outlet.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              outlet.code,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (outlet.address != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      outlet.address!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => _showOutletDetailBottomSheet(outlet),
      ),
    );
  }

  void _showOutletDetailBottomSheet(OutletModel outlet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OutletDetailSheet(
        outlet: outlet,
        currentUser: widget.currentUser,
      ),
    );
  }
}

// Outlet Detail Bottom Sheet Widget
class _OutletDetailSheet extends StatefulWidget {
  final OutletModel outlet;
  final UserModel currentUser;

  const _OutletDetailSheet({
    required this.outlet,
    required this.currentUser,
  });

  @override
  State<_OutletDetailSheet> createState() => _OutletDetailSheetState();
}

class _OutletDetailSheetState extends State<_OutletDetailSheet> {
  final _visitService = VisitService();
  
  List<VisitModel> _outletVisits = [];
  bool _isLoadingVisits = true;
  bool _isCreatingVisit = false;
  bool _hasVisitedToday = false;
  bool _isCheckingToday = true;

  @override
  void initState() {
    super.initState();
    _loadOutletVisits();
    _checkIfVisitedToday();
  }

  Future<void> _checkIfVisitedToday() async {
    setState(() => _isCheckingToday = true);
    try {
      final response = await _visitService.hasVisitedToday(widget.outlet.id);
      if (response.success && response.data != null) {
        setState(() {
          _hasVisitedToday = response.data!;
          _isCheckingToday = false;
        });
      } else {
        setState(() => _isCheckingToday = false);
      }
    } catch (e) {
      print('Error checking today visit: $e');
      setState(() => _isCheckingToday = false);
    }
  }

  Future<void> _loadOutletVisits() async {
    setState(() => _isLoadingVisits = true);
    try {
      final response = await _visitService.getVisitsByOutlet(widget.outlet.id);
      if (response.success && response.data != null) {
        setState(() {
          _outletVisits = response.data!;
          _isLoadingVisits = false;
        });
      } else {
        setState(() => _isLoadingVisits = false);
      }
    } catch (e) {
      print('Error loading outlet visits: $e');
      setState(() => _isLoadingVisits = false);
    }
  }

  Future<void> _startNewVisit() async {
    print('🔵 Starting new visit...');
    
    // Show dialog to input crew
    final crewController = TextEditingController();
    final crewName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Crew in Charge'),
        content: TextField(
          controller: crewController,
          decoration: const InputDecoration(
            labelText: 'Enter crew name',
            hintText: 'e.g., John Doe',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, crewController.text),
            child: const Text('Start Visit'),
          ),
        ],
      ),
    );

    // If cancelled or empty
    if (crewName == null || crewName.trim().isEmpty) {
      return;
    }
    
    setState(() => _isCreatingVisit = true);
    
    try {
      // Create new visit with crew
      print('🔵 Creating visit for outlet: ${widget.outlet.id}, crew: $crewName');
      final response = await _visitService.createVisit(
        outletId: widget.outlet.id,
        notes: 'Visit to ${widget.outlet.name}',
        crewInCharge: crewName.trim(),
      );

      print('🔵 Visit response: success=${response.success}, data=${response.data}');

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() => _isCreatingVisit = false);
        
        print('🔵 Navigating to category list screen...');
        // Navigate to category list screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitCategoryListScreen(
              outlet: widget.outlet,
              currentUser: widget.currentUser,
              visit: response.data!,
            ),
          ),
        ).then((_) {
          print('🔵 Returned from category list, reloading visits...');
          // Reload visits and check today when coming back
          _loadOutletVisits();
          _checkIfVisitedToday();
        });
      } else {
        print('❌ Visit creation failed: ${response.message}');
        setState(() => _isCreatingVisit = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to create visit')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error creating visit: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isCreatingVisit = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withAlpha(179),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.outlet.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.outlet.code,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.outlet.address != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.outlet.address!,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Start New Visit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isCreatingVisit || _hasVisitedToday || _isCheckingToday) 
                            ? null 
                            : () {
                                _startNewVisit();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasVisitedToday 
                              ? Colors.grey[400] 
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isCheckingToday
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : _isCreatingVisit
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _hasVisitedToday ? Icons.check_circle : Icons.play_arrow, 
                                        size: 24
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _hasVisitedToday 
                                            ? 'Already Visited Today' 
                                            : 'Start New Visit',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    if (_hasVisitedToday) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You have already visited this outlet today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Visit History Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    const Text(
                      'Visit History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_outletVisits.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Visit History List
              Expanded(
                child: _isLoadingVisits
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : _outletVisits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No visit history yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start your first visit!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _outletVisits.length,
                            itemBuilder: (context, index) {
                              final visit = _outletVisits[index];
                              return _buildVisitHistoryItem(visit);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitHistoryItem(VisitModel visit) {
    IconData icon;
    Color iconColor;
    
    switch (visit.status) {
      case 'completed':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'in_progress':
        icon = Icons.pending;
        iconColor = Colors.orange;
        break;
      case 'scheduled':
        icon = Icons.schedule;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.circle_outlined;
        iconColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitDetailScreen(
              visit: visit,
              outlet: widget.outlet,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatStatus(visit.status),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateWithTime(visit),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'scheduled':
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDateWithTime(VisitModel visit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(visit.visitDate.year, visit.visitDate.month, visit.visitDate.day);
    
    // Get time from checkInTime if available, otherwise from visitDate
    String timeStr = '00:00';
    if (visit.checkInTime != null && visit.checkInTime!.isNotEmpty) {
      // Parse HH:mm:ss format
      final parts = visit.checkInTime!.split(':');
      if (parts.length >= 2) {
        timeStr = '${parts[0]}:${parts[1]}';
      }
    } else {
      timeStr = '${visit.visitDate.hour.toString().padLeft(2, '0')}:${visit.visitDate.minute.toString().padLeft(2, '0')}';
    }
    
    if (visitDate == today) {
      return 'Today $timeStr';
    } else if (visitDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    } else {
      return '${visit.visitDate.day}/${visit.visitDate.month}/${visit.visitDate.year} $timeStr';
    }
  }
}
