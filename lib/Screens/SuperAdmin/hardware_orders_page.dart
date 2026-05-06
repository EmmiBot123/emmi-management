import 'package:flutter/material.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Repository/school_visit_repository.dart';

class _Palette {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
}

class HardwareOrdersPage extends StatefulWidget {
  const HardwareOrdersPage({super.key});

  @override
  State<HardwareOrdersPage> createState() => _HardwareOrdersPageState();
}

class _HardwareOrdersPageState extends State<HardwareOrdersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allOrders = []; // List of {visit: SchoolVisit, order: ServiceOrder}

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final repo = SchoolVisitRepository();
      final visits = await repo.getPaymentVisits();
      
      List<Map<String, dynamic>> orders = [];
      for (var v in visits) {
        for (var o in v.serviceOrders) {
          orders.add({
            'visit': v,
            'order': o,
          });
        }
      }
      
      // Sort newest first
      orders.sort((a, b) {
        final dateA = a['order'].createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b['order'].createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      setState(() => _allOrders = orders);
    } catch (e) {
      debugPrint("Error loading hardware orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(SchoolVisit visit, ServiceOrder order, String newStatus) async {
    try {
      setState(() => order.status = newStatus);
      final repo = SchoolVisitRepository();
      await repo.updateVisit(visit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order for ${visit.schoolProfile.name} updated to $newStatus")),
        );
      }
    } catch (e) {
      debugPrint("Update status error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: _Palette.surface,
        elevation: 0,
        title: const Text("Hardware Replacement Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _Palette.accent))
          : _allOrders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _allOrders.length,
                  itemBuilder: (context, index) {
                    final data = _allOrders[index];
                    final SchoolVisit visit = data['visit'];
                    final ServiceOrder order = data['order'];
                    return _buildOrderCard(visit, order);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: _Palette.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text("No hardware orders found", style: TextStyle(color: _Palette.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SchoolVisit visit, ServiceOrder order) {
    Color statusColor;
    switch (order.status) {
      case "Order Placed": statusColor = Colors.blue; break;
      case "Confirmed": statusColor = Colors.orange; break;
      case "Shipped": statusColor = Colors.purple; break;
      case "Resolved": statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.surfaceLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
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
                    Text(visit.schoolProfile.name.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(visit.schoolProfile.city, style: const TextStyle(color: _Palette.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _Palette.surfaceLight),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _Palette.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.devices_other, color: _Palette.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Item: ${order.item}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Defect: ${order.description}", style: const TextStyle(color: _Palette.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("UPDATE SHIPMENT STATUS", style: TextStyle(color: _Palette.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusAction(visit, order, "Confirmed", Colors.orange),
              const SizedBox(width: 12),
              _buildStatusAction(visit, order, "Shipped", Colors.purple),
              const SizedBox(width: 12),
              _buildStatusAction(visit, order, "Resolved", Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(SchoolVisit visit, ServiceOrder order, String status, Color color) {
    final isSelected = order.status == status;
    return Expanded(
      child: InkWell(
        onTap: () => _updateOrderStatus(visit, order, status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
