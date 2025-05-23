import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:mon_sirh_mobile/models/user.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      // Defensive redirect if user is null
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${user.name} (${user.role.toString().split('.').last})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      // Just show the dashboard items list — no nested routing UI here
      body: _buildDashboardContent(context, user),
    );
  }

  // Helper to build full dashboard route paths
  String _dashboardRoute(String subPath) => '/dashboard/$subPath';

  Widget _buildDashboardContent(BuildContext context, User user) {
    List<Widget> dashboardItems = [];

    dashboardItems.add(_buildProfileCard(context, user));

    if (user.role == UserRole.employee || user.role == UserRole.manager || user.role == UserRole.rhAdmin) {
      dashboardItems.add(_buildLeaveCard(context));
    }

    if (user.role == UserRole.rhAdmin || user.role == UserRole.manager) {
      dashboardItems.add(_buildTeamManagementCard(context, user));
    }

    if (user.role == UserRole.rhAdmin) {
      dashboardItems.add(_buildAdminStatsCard(context));
    }

    if (user.role == UserRole.employee || user.role == UserRole.manager || user.role == UserRole.rhAdmin) {
      dashboardItems.add(_buildDocumentsCard(context));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: dashboardItems,
    );
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: const Icon(Icons.person, size: 40),
        title: const Text('Mon Profil'),
        subtitle: const Text('Voir ou modifier mes informations'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go(_dashboardRoute('profile'));
        },
      ),
    );
  }

  Widget _buildLeaveCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: const Icon(Icons.calendar_today, size: 40),
        title: const Text('Congés & Absences'),
        subtitle: const Text('Demander ou gérer les congés'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go(_dashboardRoute('demandes'));
        },
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: const Icon(Icons.description, size: 40),
        title: const Text('Mes Documents'),
        subtitle: const Text('Consulter fiches de paie, attestations...'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go(_dashboardRoute('documents'));
        },
      ),
    );
  }

  Widget _buildTeamManagementCard(BuildContext context, User user) {
    if (user.role == UserRole.employee) return const SizedBox.shrink();

    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: Icon(Icons.group, size: 40, color: Colors.blueGrey),
        title: Text(user.role == UserRole.manager ? 'Mon Équipe' : 'Gestion Employés'),
        subtitle: const Text('Gérer les demandes, voir les profils...'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go(_dashboardRoute('team'));
        },
      ),
    );
  }

  Widget _buildAdminStatsCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        leading: Icon(Icons.bar_chart, size: 40, color: Colors.deepPurple),
        title: const Text('Tableau de Bord RH'),
        subtitle: const Text('Statistiques, calendrier global...'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go(_dashboardRoute('rh-dashboard'));
        },
      ),
    );
  }
}
