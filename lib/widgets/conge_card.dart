import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mon_sirh_mobile/models/conge.dart';
import 'package:mon_sirh_mobile/models/user.dart'; // For role check
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:mon_sirh_mobile/providers/conge_provider.dart';
import 'package:provider/provider.dart';

class CongeCard extends StatelessWidget {
  final Conge congeRequest;

  const CongeCard({super.key, required this.congeRequest});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final congeProvider = Provider.of<CongeProvider>(context, listen: false);

    // Determine if the current user can approve/reject this request
    final bool canManage = (currentUser?.role == UserRole.manager && congeRequest.status == CongeStatus.enAttente && congeRequest.managerId == currentUser?.id) ||
                           (currentUser?.role == UserRole.rhAdmin && congeRequest.status == CongeStatus.enAttente);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    congeRequest.employeeName, // Show employee name
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(congeRequest.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: ${congeRequest.type.toString().split('.').last}'),
            const SizedBox(height: 4),
            Text('Dates: ${DateFormat('dd/MM/yyyy').format(congeRequest.dateDebut)} - ${DateFormat('dd/MM/yyyy').format(congeRequest.dateFin)} (${congeRequest.durationInDays} j)'),
            if (congeRequest.motif != null && congeRequest.motif!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Motif: ${congeRequest.motif}'),
              ),
            if (congeRequest.decisionDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Décision le: ${DateFormat('dd/MM/yyyy').format(congeRequest.decisionDate!)} par ${congeRequest.managerId ?? 'Admin'}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600])),
              ),
            // Show approval/rejection buttons for managers/admins if request is pending
            if (canManage)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        // Show confirmation dialog before rejecting
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmer le rejet'),
                            content: const Text('Voulez-vous vraiment refuser cette demande ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Refuser', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;

                        if (confirm) {
                          final success = await congeProvider.updateCongeStatus(congeRequest.id, CongeStatus.refusee);
                           if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Demande refusée.' : congeProvider.errorMessage ?? 'Échec de la mise à jour.'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                           }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmer l\'approbation'),
                            content: const Text('Voulez-vous vraiment approuver cette demande ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Approuver')),
                            ],
                          ),
                        ) ?? false;

                        if (confirm) {
                            final success = await congeProvider.updateCongeStatus(congeRequest.id, CongeStatus.approuvee);
                             if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Demande approuvée.' : congeProvider.errorMessage ?? 'Échec de la mise à jour.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                             }
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CongeStatus status) {
    Color chipColor;
    String label;
    IconData iconData;

    switch (status) {
      case CongeStatus.approuvee:
        chipColor = Colors.green.shade100;
        label = 'Approuvée';
        iconData = Icons.check_circle_outline;
        break;
      case CongeStatus.refusee:
        chipColor = Colors.red.shade100;
        label = 'Refusée';
        iconData = Icons.cancel_outlined;
        break;
      case CongeStatus.enAttente:
      default:
        chipColor = Colors.orange.shade100;
        label = 'En attente';
        iconData = Icons.hourglass_empty_outlined;
        break;
    }

    return Chip(
      avatar: Icon(iconData, size: 16, color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
      label: Text(label, style: TextStyle(fontSize: 12, color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      visualDensity: VisualDensity.compact,
    );
  }
}

