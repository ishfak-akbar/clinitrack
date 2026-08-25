import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/sticky_save_button.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medicine> _filteredMedicines(List<Medicine> allMedicines) {
    if (_query.trim().isEmpty) return allMedicines;
    return allMedicines
        .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final allMedicines = context.watch<MedicineProvider>().medicines;
    final filtered = _filteredMedicines(allMedicines);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Medicine Inventory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Text(
                'No medicines found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        for (int i = 0; i < filtered.length; i++) ...[
                          _MedicineRow(medicine: filtered[i], accent: accent),
                          if (i != filtered.length - 1) const Divider(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickySaveButton(
        isSaving: false,
        onPressed: () => Navigator.of(context).pushNamed('/order-medicine'),
        label: '+ Order Medicine',
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final Medicine medicine;
  final Color accent;

  const _MedicineRow({required this.medicine, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isLow = medicine.stock < 40;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.medication_outlined, color: accent),
      ),
      title: Text(
        medicine.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text('${medicine.category} • ${medicine.unit}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${medicine.stock}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isLow ? AppColors.errorRed : accent,
            ),
          ),
          Text(
            isLow ? 'Low stock' : 'In stock',
            style: TextStyle(
              fontSize: 11,
              color: isLow ? AppColors.errorRed : AppColors.successGreen,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).pushNamed(
          '/order-medicine',
          arguments: medicine,
        );
      },
    );
  }
}