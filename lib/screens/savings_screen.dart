import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings.dart';
import '../services/data_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final DataService _dataService = DataService();
  List<Savings> _savings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    setState(() => _isLoading = true);
    final savings = await _dataService.getSavings();
    setState(() {
      _savings = savings;
      _isLoading = false;
    });
  }

  Future<void> _addSavings() async {
    final result = await showDialog<Savings>(
      context: context,
      builder: (context) => const AddSavingsDialog(),
    );
    
    if (result != null) {
      await _dataService.addSavings(result);
      _loadSavings();
    }
  }

  Future<void> _updateBalance(Savings savings) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => UpdateBalanceDialog(currentBalance: savings.balance),
    );
    
    if (result != null) {
      final updated = Savings(
        id: savings.id,
        name: savings.name,
        balance: result,
        targetAmount: savings.targetAmount,
        createdDate: savings.createdDate,
        description: savings.description,
      );
      await _dataService.updateSavings(updated);
      _loadSavings();
    }
  }

  Future<void> _deleteSavings(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings'),
        content: const Text('Are you sure you want to delete this savings account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.deleteSavings(id);
      _loadSavings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No savings yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a savings account',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savings.length,
                  itemBuilder: (context, index) {
                    final savings = _savings[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.savings, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        savings.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${currencyFormat.format(savings.balance)} / ${currencyFormat.format(savings.targetAmount)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSavings(savings.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: savings.progressPercentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                savings.progressPercentage >= 100
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${savings.progressPercentage.toStringAsFixed(1)}% complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _updateBalance(savings),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Update'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ],
                            ),
                            if (savings.description.isNotEmpty) ...[
                              const Divider(),
                              Text(
                                savings.description,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSavings,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddSavingsDialog extends StatefulWidget {
  const AddSavingsDialog({super.key});

  @override
  State<AddSavingsDialog> createState() => _AddSavingsDialogState();
}

class _AddSavingsDialogState extends State<AddSavingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _targetController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Savings'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Savings Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Current Balance'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final savings = Savings(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                balance: double.parse(_balanceController.text),
                targetAmount: double.parse(_targetController.text),
                createdDate: DateTime.now(),
                description: _descriptionController.text,
              );
              Navigator.pop(context, savings);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class UpdateBalanceDialog extends StatefulWidget {
  final double currentBalance;

  const UpdateBalanceDialog({super.key, required this.currentBalance});

  @override
  State<UpdateBalanceDialog> createState() => _UpdateBalanceDialogState();
}

class _UpdateBalanceDialogState extends State<UpdateBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: widget.currentBalance.toString(),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Balance'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _balanceController,
          decoration: const InputDecoration(labelText: 'New Balance'),
          keyboardType: TextInputType.number,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, double.parse(_balanceController.text));
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
