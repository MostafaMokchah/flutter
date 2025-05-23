import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:mon_sirh_mobile/models/user.dart';
import 'package:intl/intl.dart'; // For date formatting

class FicheEmployeScreen extends StatefulWidget {
  const FicheEmployeScreen({super.key});

  @override
  State<FicheEmployeScreen> createState() => _FicheEmployeScreenState();
}

class _FicheEmployeScreenState extends State<FicheEmployeScreen> {
  // TODO: Add logic to fetch/display employee data (could be current user or another employee if admin/manager)
  // For now, displays the current logged-in user's data.

  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  // Controllers for editable fields
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      // TODO: Implement API call to update user profile
      print('Saving changes for user ${user.id}:');
      print('Phone: ${_phoneController.text}');
      print('Address: ${_addressController.text}');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update local user data (ideally refetch from API or update provider state)
      // For demo, we just toggle edit mode back
      // In a real app, update AuthProvider's currentUser or fetch updated data

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations mises à jour (simulation)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      // Should be handled by routing, but good practice to check
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Employé')),
        body: const Center(child: Text('Utilisateur non trouvé.')),
      );
    }

    // Determine if the current user can edit their own profile
    // TODO: Refine permissions based on specific requirements or API response
    final bool canEdit = user.role == UserRole.employee || user.role == UserRole.manager || user.role == UserRole.rhAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Employé'),
        actions: [
          if (canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: _toggleEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Annuler',
              onPressed: () {
                 // Reset controllers if needed
                 _phoneController.text = user.phone ?? '';
                 _addressController.text = user.address ?? '';
                _toggleEdit();
              },
            ),
           if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Enregistrer',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations Personnelles'),
              _buildInfoRow('Nom', user.name),
              _buildInfoRow('Email', user.email),
              _buildEditableInfoRow('Téléphone', _phoneController, Icons.phone, TextInputType.phone),
              _buildEditableInfoRow('Adresse', _addressController, Icons.home, TextInputType.streetAddress),
              const SizedBox(height: 20),

              _buildSectionTitle('Contrat de Travail'),
              _buildInfoRow('Type de contrat', user.contractType ?? 'N/A'),
              _buildInfoRow('Date d\'embauche', user.contractStartDate != null ? DateFormat('dd/MM/yyyy').format(user.contractStartDate!) : 'N/A'),
              _buildInfoRow('Salaire', user.salary != null ? '${user.salary?.toStringAsFixed(2)} €' : 'N/A'), // Format as needed
              const SizedBox(height: 20),

              _buildSectionTitle('Documents'),
              _buildDocumentList(user.documents),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, TextEditingController controller, IconData icon, TextInputType keyboardType) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: _isEditing
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    // hintText: 'Entrez $label',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(icon, size: 18),
                  ),
                  keyboardType: keyboardType,
                  validator: (value) {
                    // Add specific validation if needed
                    // if (value == null || value.isEmpty) {
                    //   return 'Ce champ est requis';
                    // }
                    return null;
                  },
                )
              : Text(controller.text.isNotEmpty ? controller.text : 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<String>? documents) {
    if (documents == null || documents.isEmpty) {
      return const Text('Aucun document disponible.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: documents.map((doc) {
        // Assuming 'doc' is a display name or URL/ID
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(doc), // Display the document name/identifier
          trailing: const Icon(Icons.visibility), // Or download icon
          onTap: () {
            // TODO: Implement document viewing/downloading logic
            // Maybe navigate to PdfViewerScreen with the document URL/ID
            print('View document: $doc');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Affichage du document $doc (non implémenté)')),
            );
          },
        );
      }).toList(),
    );
  }
}

