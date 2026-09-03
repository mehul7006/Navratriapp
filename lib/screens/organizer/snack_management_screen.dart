import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class SnackManagementScreen extends StatefulWidget {
  const SnackManagementScreen({super.key});

  @override
  State<SnackManagementScreen> createState() => _SnackManagementScreenState();
}

class _SnackManagementScreenState extends State<SnackManagementScreen> {
  List<Map<String, dynamic>> _snacks = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _showOrders = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _snacks = await DatabaseHelper.getAllSnacks();
    _orders = await DatabaseHelper.getSnackOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('snack_orders'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showOrders ? _buildOrdersList() : _buildSnacksList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: () => _showAddSnackDialog(),
        child: const Icon(Icons.add, color: AppTheme.purpleDark),
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingOrders = _orders.where((o) => o['status'] == 'pending').length;
    return Container(
      margin: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showOrders = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showOrders ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Items (${_snacks.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showOrders ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showOrders = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showOrders ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Orders (${_orders.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showOrders ? AppTheme.purpleDark : AppTheme.textMuted)),
                    if (pendingOrders > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        child: Text('$pendingOrders', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnacksList() {
    if (_snacks.isEmpty) return Center(child: Text(AppLocalizations.t('no_snack_items'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _snacks.length,
      itemBuilder: (context, index) => _buildSnackCard(_snacks[index]),
    );
  }

  Widget _buildSnackCard(Map<String, dynamic> snack) {
    final available = (snack['quantity_available'] ?? 0) - (snack['quantity_sold'] ?? 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: (snack['is_vegetarian'] ?? true) ? Colors.green.withOpacity(0.2) : AppTheme.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              (snack['is_vegetarian'] ?? true) ? Icons.eco : Icons.restaurant,
              color: (snack['is_vegetarian'] ?? true) ? Colors.green : AppTheme.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snack['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(snack['description'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹${snack['price']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                    const SizedBox(width: 12),
                    Text('Stock: $available', style: TextStyle(fontSize: 12, color: available > 10 ? Colors.green : AppTheme.redAccent)),
                    const SizedBox(width: 12),
                    Text('Sold: ${snack['quantity_sold'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.goldPrimary),
            color: AppTheme.purpleCard,
            onSelected: (v) {
              if (v == 'toggle') {
                DatabaseHelper.updateSnack(snack['id'], isActive: !(snack['is_active'] ?? true));
                _loadData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'toggle', child: Text(snack['is_active'] == true ? AppLocalizations.t('deactivate') : AppLocalizations.t('activate'), style: const TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) return Center(child: Text(AppLocalizations.t('no_orders_yet'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    Color statusColor;
    switch (status) {
      case 'delivered': statusColor = Colors.green; break;
      case 'preparing': statusColor = Colors.blue; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Center(
              child: Text((order['house_number'] ?? '').toString().substring(0, 3), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['user_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${order['snack_name']} x${order['quantity']} • ₹${order['total_price']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (status == 'pending') ...[
            _buildStatusBtn(AppLocalizations.t('preparing'), Colors.blue, () async {
              await DatabaseHelper.updateSnackOrderStatus(order['id'], 'preparing');
              _loadData();
            }),
            const SizedBox(width: 4),
            _buildStatusBtn(AppLocalizations.t('ready'), Colors.green, () async {
              await DatabaseHelper.updateSnackOrderStatus(order['id'], 'delivered');
              _loadData();
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  void _showAddSnackDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.t('add_snack_item'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            const SizedBox(height: 16),
            _buildField(controller: nameController, label: AppLocalizations.t('item_name'), icon: Icons.restaurant),
            const SizedBox(height: 12),
            _buildField(controller: descController, label: AppLocalizations.t('description'), icon: Icons.description),
            const SizedBox(height: 12),
            _buildField(controller: priceController, label: AppLocalizations.t('price_rs'), icon: Icons.attach_money, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField(controller: qtyController, label: AppLocalizations.t('quantity_available'), icon: Icons.inventory, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                await DatabaseHelper.addSnack(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: double.tryParse(priceController.text) ?? 0,
                  quantity: int.tryParse(qtyController.text) ?? 0,
                );
                Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(AppLocalizations.t('add_item'), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
    );
  }
}
