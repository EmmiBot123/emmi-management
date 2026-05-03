import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/Support/support_ticket_model.dart';
import '../../Repository/Support/support_repository.dart';
import '../../Repository/Support/delhivery_repository.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage>
    with SingleTickerProviderStateMixin {
  final SupportRepository _repository = SupportRepository();
  String _statusFilter = 'all'; // 'all', 'open', 'resolved'
  
  late AnimationController _heroController;
  late Animation<double> _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroAnim = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _setFilter(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ═══════════ HERO HEADER ═══════════
          FadeTransition(
            opacity: _heroAnim,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPad + 20,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2B1055), Color(0xFF7597DE)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative shapes
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),

                  // Header Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button & Title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.support_agent,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Support Tickets",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All Tickets", "all", Icons.all_inbox),
                            const SizedBox(width: 8),
                            _buildFilterChip("Open", "open", Icons.hourglass_top),
                            const SizedBox(width: 8),
                            _buildFilterChip("Resolved", "resolved", Icons.check_circle_outline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ═══════════ CONTENT ═══════════
          Expanded(
            child: StreamBuilder<List<SupportTicket>>(
              stream: _repository.getTicketsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2B1055),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allTickets = snapshot.data ?? [];
                final filteredTickets = _statusFilter == 'all'
                    ? allTickets
                    : allTickets.where((t) => t.status == _statusFilter).toList();

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 60, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          "No ${_statusFilter == 'all' ? '' : '$_statusFilter '}tickets found.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 40),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];
                    return _buildTicketCard(ticket);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF2B1055) : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2B1055) : Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final isResolved = ticket.status == 'resolved';
    
    // Determine colors based on status
    final statusColor = isResolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusBgColor = isResolved ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final statusIcon = isResolved ? Icons.check_circle : Icons.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: FutureBuilder<Map<String, String>>(
            future: _getUserDetails(ticket.email),
            builder: (context, snapshot) {
              final fetchedName = snapshot.data?['name'];
              final name = (fetchedName != null && fetchedName.isNotEmpty) ? fetchedName : ticket.email;
              final schoolId = snapshot.data?['schoolId'];
              final hasSchoolId = schoolId != null && schoolId.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSchoolId) ...[
                    const SizedBox(height: 2),
                    Text(
                      "School ID: $schoolId",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (name != ticket.email) ...[
                    const SizedBox(height: 2),
                    Text(
                      ticket.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(ticket.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ticket.contactNumber.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    ticket.contactNumber,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          children: [
            // Divider
            Divider(color: Colors.grey.withOpacity(0.2), height: 1),
            const SizedBox(height: 16),
            
            // Message Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "User Message",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Chat History Section
            if (ticket.chatHistory.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark terminal look
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        const Text(
                          "Chat History Log",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          ticket.chatHistory,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFE2E8F0),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Replies Thread
            if (ticket.replies.isNotEmpty) ...[
              const Text(
                "Conversation",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              ...ticket.replies.map((reply) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: reply.sender == 'admin' ? const Color(0xFFF3E8FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: reply.sender == 'admin' ? const Color(0xFFD8B4FE) : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            reply.sender == 'admin' ? Icons.admin_panel_settings : Icons.person,
                            size: 12,
                            color: reply.sender == 'admin' ? const Color(0xFF7E22CE) : Colors.blueGrey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reply.sender == 'admin' ? "Admin" : "User",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: reply.sender == 'admin' ? const Color(0xFF7E22CE) : Colors.blueGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(reply.timestamp),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reply.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: reply.sender == 'admin' ? const Color(0xFF4C1D95) : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],

            // Legacy Admin Response (if exists)
            if (ticket.adminResponse != null && ticket.replies.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8B4FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply_all, size: 14, color: Color(0xFF7E22CE)),
                        SizedBox(width: 8),
                        Text(
                          "Admin Response",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF7E22CE),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.adminResponse!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Color(0xFF4C1D95),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!isResolved) ...[
              const Text(
                "Send Reply",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              _ReplyInput(
                onSubmit: (value) => _submitResponse(ticket.id!, value),
              ),
              const SizedBox(height: 16),
            ],

            // Hardware Complaint Section
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.settings_input_component,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Text(
                  "Hardware Complaint Details",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: ticket.isHardwareComplaint,
                  onChanged: (val) =>
                      _updateHardwareStatus(ticket.id!, val, ticket.trackingLink),
                  activeColor: const Color(0xFF10B981),
                ),
              ],
            ),
            if (ticket.isHardwareComplaint) ...[
              const SizedBox(height: 8),
              _TrackingInput(
                initialValue: ticket.trackingLink ?? '',
                onSave: (val) => _updateHardwareStatus(
                    ticket.id!, ticket.isHardwareComplaint, val, manualStatus: ticket.manualTrackingStatus),
              ),
              const SizedBox(height: 12),
              const Text(
                "Manual Shipment Status",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: (ticket.manualTrackingStatus != null && ['Yet to be picked up', 'In transit', 'Out for delivery', 'Delivered'].contains(ticket.manualTrackingStatus)) 
                    ? ticket.manualTrackingStatus 
                    : 'Yet to be picked up',
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blue.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold),
                items: ['Yet to be picked up', 'In transit', 'Out for delivery', 'Delivered']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => _updateHardwareStatus(
                    ticket.id!, ticket.isHardwareComplaint, ticket.trackingLink, manualStatus: val),
              ),
              if (ticket.trackingLink != null && ticket.trackingLink!.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _launchTracking(ticket.trackingLink!),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text("Open Public Tracker"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isResolved)
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(ticket.id!, 'resolved'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("Mark Resolved"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(ticket.id!, 'open'),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text("Reopen Ticket"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

  // Cache user lookups to avoid multiple requests
  final Map<String, Map<String, String>> _userCache = {};
  bool _legacyUsersLoaded = false;
  final Map<String, Map<String, String>> _legacyUserCache = {};

  Future<void> _loadLegacyUsers() async {
    if (_legacyUsersLoaded) return;
    try {
      final response = await http.get(Uri.parse('http://35.154.150.95:3000/users'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        for (var user in data) {
          final uEmail = user['email'] as String?;
          if (uEmail != null) {
            final roleIdList = user['roleId'];
            String sId = '';
            if (roleIdList is List && roleIdList.isNotEmpty) {
              sId = roleIdList.first.toString();
            } else if (roleIdList is String) {
              sId = roleIdList;
            }
            _legacyUserCache[uEmail] = {
              'name': user['name']?.toString() ?? '',
              'schoolId': sId,
            };
          }
        }
      }
    } catch (e) {
      debugPrint("Legacy user fetch error: $e");
    }
    _legacyUsersLoaded = true;
  }

  Future<Map<String, String>> _getUserDetails(String email) async {
    if (_userCache.containsKey(email)) {
      return _userCache[email]!;
    }
    
    // 1. Try Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final name = data['name'] as String? ?? '';
        final roleIdList = data['roleId'] as List<dynamic>? ?? [];
        final schoolId = roleIdList.isNotEmpty ? roleIdList.first.toString() : '';
        
        final result = {
          'name': name,
          'schoolId': schoolId,
        };
        _userCache[email] = result;
        return result;
      }
    } catch (e) {
      debugPrint("Error fetching user details for ticket: $e");
    }
    
    // 2. Try Legacy API
    await _loadLegacyUsers();
    if (_legacyUserCache.containsKey(email)) {
      final result = _legacyUserCache[email]!;
      _userCache[email] = result;
      return result;
    }

    // 3. Fallback: Parse Student Email (e.g. student_1791_4d_... )
    if (email.startsWith('student_')) {
      final parts = email.split('_');
      if (parts.length > 2) {
        final sId = parts[1];
        final className = parts[2].toUpperCase();
        final fallbackResult = {
          'name': 'Student (Class $className)',
          'schoolId': sId,
        };
        _userCache[email] = fallbackResult;
        return fallbackResult;
      }
    }
    
    // Ultimate Fallback
    final fallback = {'name': '', 'schoolId': ''};
    _userCache[email] = fallback;
    return fallback;
  }

  Future<void> _submitResponse(String id, String response) async {
    final success = await _repository.addTicketReply(id, response);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Reply sent" : "Failed to send reply"),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final success = await _repository.updateTicketStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Status updated" : "Failed to update status"),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateHardwareStatus(
      String id, bool isHardware, String? trackingLink, {String? manualStatus}) async {
    final success =
        await _repository.updateTicketHardwareDetails(id, isHardware, trackingLink, manualTrackingStatus: manualStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? "Hardware details updated" : "Failed to update details"),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _launchTracking(String link) async {
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch tracking link")),
        );
      }
    }
  }
}

// Separate StatefulWidget for Reply Input to handle local controller
class _ReplyInput extends StatefulWidget {
  final Function(String) onSubmit;
  const _ReplyInput({required this.onSubmit});

  @override
  State<_ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<_ReplyInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Enter your response...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
              onSubmitted: (val) {
                widget.onSubmit(val);
                _controller.clear();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2B1055),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: () {
                  widget.onSubmit(_controller.text);
                  _controller.clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _TrackingInput extends StatefulWidget {
  final String initialValue;
  final Function(String) onSave;
  const _TrackingInput({required this.initialValue, required this.onSave});

  @override
  State<_TrackingInput> createState() => _TrackingInputState();
}

class _TrackingInputState extends State<_TrackingInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Enter Delhivery Tracking Link / AWB...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF2B1055), size: 18),
            onPressed: () => widget.onSave(_controller.text),
          ),
        ],
      ),
    );
  }
}

class _LiveTrackingStatus extends StatefulWidget {
  final String awb;
  const _LiveTrackingStatus({required this.awb});

  @override
  State<_LiveTrackingStatus> createState() => _LiveTrackingStatusState();
}

class _LiveTrackingStatusState extends State<_LiveTrackingStatus> {
  final _delhiveryRepo = DelhiveryRepository();
  Map<String, dynamic>? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void didUpdateWidget(_LiveTrackingStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.awb != widget.awb) {
      _fetchStatus();
    }
  }

  Future<void> _fetchStatus() async {
    if (DelhiveryRepository.apiToken.isEmpty) return;
    
    // Simple AWB check (usually numbers)
    if (!widget.awb.contains(RegExp(r'[0-9]'))) return;

    setState(() => _isLoading = true);
    final data = await _delhiveryRepo.getTrackingStatus(widget.awb);
    if (mounted) {
      setState(() {
        _status = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DelhiveryRepository.apiToken.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Delhivery API Token not configured. Live tracking disabled.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_status == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "Could not fetch live status. Check AWB number.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final statusText = _status!['Status']['Status'] ?? 'Unknown';
    final location = _status!['Status']['ScannedLocation'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                "Live Status: $statusText",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Last Scan: $location",
            style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
          ),
        ],
      ),
    );
  }
}
