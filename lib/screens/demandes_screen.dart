import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mon_sirh_mobile/models/conge.dart';
import 'package:mon_sirh_mobile/models/user.dart';
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:mon_sirh_mobile/providers/conge_provider.dart';
import 'package:mon_sirh_mobile/widgets/conge_card.dart'; // Assuming a CongeCard widget exists
import 'package:provider/provider.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch requests initially if not already loaded
    // Provider might handle this already in its constructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen: false inside initState/callbacks
      Provider.of<CongeProvider>(context, listen: false).fetchCongeRequests();
      Provider.of<CongeProvider>(context, listen: false).fetchSoldeConges();
    });
  }

  void _showAddCongeDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    DateTime? _startDate;
    DateTime? _endDate;
    CongeType _selectedType = CongeType.paye;
    final _motifController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage dialog state locally
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvelle demande de congé'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Start Date Picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(_startDate == null
                            ? 'Date de début'
                            : 'Début: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow past dates slightly?
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              _startDate = pickedDate;
                            });
                          }
                        },
                      ),
                      // End Date Picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(_endDate == null
                            ? 'Date de fin'
                            : 'Fin: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              _endDate = pickedDate;
                            });
                          }
                        },
                      ),
                      // Type Dropdown
                      DropdownButtonFormField<CongeType>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Type de congé'),
                        items: CongeType.values.map((CongeType type) {
                          return DropdownMenuItem<CongeType>(
                            value: type,
                            // Provide user-friendly names for enum values
                            child: Text(type.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim()),
                          );
                        }).toList(),
                        onChanged: (CongeType? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              _selectedType = newValue;
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Champ requis' : null,
                      ),
                      // Motif TextField
                      TextFormField(
                        controller: _motifController,
                        decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Soumettre'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_startDate == null || _endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez sélectionner les dates.'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      if (_endDate!.isBefore(_startDate!)) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La date de fin doit être après la date de début.'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final congeProvider = Provider.of<CongeProvider>(context, listen: false);
                      final success = await congeProvider.submitCongeRequest(
                        _startDate!,
                        _endDate!,
                        _selectedType,
                        _motifController.text.isNotEmpty ? _motifController.text : null,
                      );

                      Navigator.of(dialogContext).pop(); // Close dialog

                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Demande soumise avec succès.' : congeProvider.errorMessage ?? 'Échec de la soumission.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                            ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final congeProvider = Provider.of<CongeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // No need to listen here
    final currentUser = authProvider.currentUser;

    // Determine if the current user can submit a request
    final bool canSubmitRequest = currentUser?.role == UserRole.employee || currentUser?.role == UserRole.manager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Congés et Absences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              congeProvider.fetchCongeRequests();
              congeProvider.fetchSoldeConges();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display leave balance for employees
          if (currentUser?.role == UserRole.employee && congeProvider.soldeConges != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Solde de congés restant: ${congeProvider.soldeConges?.toStringAsFixed(1) ?? 'N/A'} jours',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          // Loading indicator or list
          Expanded(
            child: congeProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : congeProvider.errorMessage != null
                    ? Center(child: Text('Erreur: ${congeProvider.errorMessage}'))
                    : congeProvider.relevantCongeRequests.isEmpty
                        ? const Center(child: Text('Aucune demande de congé à afficher.'))
                        : RefreshIndicator(
                            onRefresh: () async {
                               await congeProvider.fetchCongeRequests();
                               await congeProvider.fetchSoldeConges();
                            },
                            child: ListView.builder(
                                itemCount: congeProvider.relevantCongeRequests.length,
                                itemBuilder: (context, index) {
                                  final request = congeProvider.relevantCongeRequests[index];
                                  // Use a dedicated widget for the card
                                  return CongeCard(congeRequest: request);
                                },
                              ),
                          ),
          ),
        ],
      ),
      floatingActionButton: canSubmitRequest
          ? FloatingActionButton(
              onPressed: () => _showAddCongeDialog(context),
              tooltip: 'Nouvelle demande',
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB if user cannot submit requests
    );
  }
}

