import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/section_label.dart';
import '../widgets/form_section_card.dart';
import '../widgets/sticky_save_button.dart';

class OrderMedicineScreen extends StatefulWidget {
  const OrderMedicineScreen({super.key});

  @override
  State<OrderMedicineScreen> createState() => _OrderMedicineScreenState();
}

class _OrderMedicineScreenState extends State<OrderMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  Medicine? _selectedMedicine;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Medicine && _selectedMedicine == null) {
      _selectedMedicine = args;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final qty = int.parse(_quantityController.text.trim());
    await context.read<MedicineProvider>().addStock(_selectedMedicine!.id, qty);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ordered $qty ${_selectedMedicine!.unit} of ${_selectedMedicine!.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = context.watch<MedicineProvider>().medicines;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Order Medicine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            FormSectionCard(
              children: [
                const SectionLabel('Select Medicine', icon: Icons.medication_outlined),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMedicine?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Choose medicine',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  items: medicines
                      .map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.name} (${m.stock} left)'),
                  ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedMedicine = medicines.firstWhere((m) => m.id == id);
                    });
                  },
                  validator: (value) => value == null ? 'Please select a medicine' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormSectionCard(
              children: [
                const SectionLabel('Quantity to Order', icon: Icons.inventory_2_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Quantity is required';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickySaveButton(
        isSaving: _isSaving,
        onPressed: _handleOrder,
        label: 'Place Order',
      ),
    );
  }
}