import 'package:flutter/material.dart';
import '../../Model/Support/support_ticket_model.dart';
import '../../Repository/Support/support_repository.dart';
import 'package:intl/intl.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  final SupportRepository _repository = SupportRepository();
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Support Tickets"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _statusFilter = value),
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("All Tickets")),
              const PopupMenuItem(value: 'open', child: Text("Open Only")),
              const PopupMenuItem(value: 'resolved', child: Text("Resolved Only")),
            ],
          )
        ],
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: _repository.getTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allTickets = snapshot.data ?? [];
          final filteredTickets = _statusFilter == 'all'
              ? allTickets
              : allTickets.where((t) => t.status == _statusFilter).toList();

          if (filteredTickets.isEmpty) {
            return const Center(child: Text("No support tickets found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTickets.length,
            itemBuilder: (context, index) {
              final ticket = filteredTickets[index];
              return _buildTicketCard(ticket);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isResolved = ticket.status == 'resolved';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          ticket.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Status: ${ticket.status.toUpperCase()} • ${dateFormat.format(ticket.createdAt)}",
          style: TextStyle(
            color: isResolved ? Colors.green : Colors.orange,
            fontSize: 12,
          ),
        ),
        leading: Icon(
          isResolved ? Icons.check_circle : Icons.error_outline,
          color: isResolved ? Colors.green : Colors.orange,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Message:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(ticket.message),
                const SizedBox(height: 16),
                if (ticket.chatHistory.isNotEmpty) ...[
                  const Text(
                    "Chat History:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          ticket.chatHistory,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (ticket.adminResponse != null) ...[
                  const Divider(),
                  const Text(
                    "Admin Response:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.adminResponse!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                ] else if (!isResolved) ...[
                  const Divider(),
                  const Text(
                    "Reply to user:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Enter your response...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                    onSubmitted: (value) => _submitResponse(ticket.id!, value),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isResolved)
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(ticket.id!, 'resolved'),
                        icon: const Icon(Icons.check),
                        label: const Text("Mark as Resolved"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(ticket.id!, 'open'),
                        icon: const Icon(Icons.undo),
                        label: const Text("Reopen Ticket"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResponse(String id, String text) async {
    if (text.trim().isEmpty) return;
    final success = await _repository.updateTicketResponse(id, text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Response sent and ticket resolved" : "Failed to send response"),
          backgroundColor: success ? Colors.green : Colors.red,
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
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
