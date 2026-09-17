import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/list_states.dart';
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

  Future<void> _reload() =>
      context.read<MedicineProvider>().loadMedicines();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final allMedicines = provider.medicines;
    final filtered = _filteredMedicines(allMedicines);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryTealAccent : AppColors.primaryTeal;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Medicine Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add medicine',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _AddMedicineDialog(),
            ),
          ),
        ],
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
          if (provider.errorMessage.isNotEmpty)
            ListErrorBanner(
              message: provider.errorMessage,
              onRetry: _reload,
            ),
          Expanded(
            child: provider.isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allMedicines.isEmpty
                        ? 'No medicines yet'
                        : 'No medicines found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (allMedicines.isEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const _AddMedicineDialog(),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add medicine'),
                    ),
                  ],
                ],
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

class _AddMedicineDialog extends StatefulWidget {
  const _AddMedicineDialog();

  @override
  State<_AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'tablets');
  bool _isSaving = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = '';
    });

    final ok = await context.read<MedicineProvider>().addMedicine(
      Medicine(
        id: '',
        name: _nameController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        stock: int.parse(_stockController.text.trim()),
        unit: _unitController.text.trim().isEmpty
            ? 'tablets'
            : _unitController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      setState(() {
        _error = context.read<MedicineProvider>().errorMessage.isEmpty
            ? 'Could not save medicine'
            : context.read<MedicineProvider>().errorMessage;
      });
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine added successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Paracetamol 500mg',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'General',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        hintText: '0',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'tablets',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _error,
                  style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
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