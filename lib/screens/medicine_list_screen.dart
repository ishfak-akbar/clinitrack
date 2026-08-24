import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicines = context.watch<MedicineProvider>().medicines;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Medicine Inventory'),
      ),
      body: medicines.isEmpty
          ? const Center(child: Text('No medicines found'))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          final med = medicines[index];
          final isLow = med.stock < 40;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                med.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('${med.category} • ${med.unit}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${med.stock}',
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
                  arguments: med,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/order-medicine'),
        icon: const Icon(Icons.add),
        label: const Text('Order Medicine'),
      ),
    );
  }
}