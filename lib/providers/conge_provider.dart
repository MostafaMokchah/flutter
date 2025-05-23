import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mon_sirh_mobile/models/conge.dart';
import 'package:mon_sirh_mobile/models/user.dart';

class CongeProvider with ChangeNotifier {
  final User _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Conge> _congeRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  double? _soldeConges;

  CongeProvider(this._currentUser) {
    fetchCongeRequests();
    fetchSoldeConges();
  }

  List<Conge> get congeRequests => _congeRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get soldeConges => _soldeConges;

  List<Conge> get relevantCongeRequests {
    if (_currentUser.role == UserRole.employee) {
      return _congeRequests.where((req) => req.employeeId == _currentUser.id).toList();
    } else if (_currentUser.role == UserRole.manager) {
      final teamIds = _currentUser.teamMemberIds ?? [];
      return _congeRequests.where((req) =>
          teamIds.contains(req.employeeId) || req.managerId == _currentUser.id).toList();
    } else {
      return _congeRequests;
    }
  }

  Future<void> fetchCongeRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('conges').get();
      _congeRequests = snapshot.docs
          .map((doc) => Conge.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching leave requests: $e. Using sample data.');
      _congeRequests = _getSampleCongeData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSoldeConges() async {
    if (_currentUser.role != UserRole.employee) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('soldes').doc(_currentUser.id).get();
      if (doc.exists && doc.data()?['solde'] != null) {
        _soldeConges = (doc['solde'] as num).toDouble();
      } else {
        _soldeConges = 15.5;
        print("Solde not found, using sample value.");
      }
    } catch (e) {
      print('Error fetching leave balance: $e. Using sample data.');
      _soldeConges = 15.5;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitCongeRequest(DateTime start, DateTime end, CongeType type, String? motif) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final congeData = {
        'employeeId': _currentUser.id,
        'employeeName': _currentUser.name,
        'dateDebut': start.toIso8601String(),
        'dateFin': end.toIso8601String(),
        'type': type.name,
        'motif': motif,
        'status': 'enAttente',
        'managerId': _currentUser.managerId,
      };

      await _firestore.collection('conges').add(congeData);

      await fetchCongeRequests();
      await fetchSoldeConges();
      return true;
    } catch (e) {
      print('Error submitting leave request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCongeStatus(String congeId, CongeStatus newStatus) async {
    if (_currentUser.role != UserRole.manager && _currentUser.role != UserRole.rhAdmin) {
      _errorMessage = "Permission denied.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('conges').doc(congeId).update({
        'status': newStatus.name,
        'managerId': _currentUser.id,
        'decisionDate': DateTime.now().toIso8601String(),
      });

      await fetchCongeRequests();
      return true;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Conge> _getSampleCongeData() {
    final empId1 = "emp1";
    final empId2 = "emp2";
    final managerId = "manager1";

    return [
      Conge(id: "c1", employeeId: empId1, employeeName: "Alice Smith", dateDebut: DateTime.now().add(Duration(days: 10)), dateFin: DateTime.now().add(Duration(days: 14)), type: CongeType.paye, status: CongeStatus.enAttente, motif: "Vacances d'été", managerId: managerId),
      Conge(id: "c2", employeeId: empId2, employeeName: "Bob Johnson", dateDebut: DateTime.now().add(Duration(days: 5)), dateFin: DateTime.now().add(Duration(days: 6)), type: CongeType.maladie, status: CongeStatus.approuvee, managerId: managerId, decisionDate: DateTime.now().subtract(Duration(days: 1))),
      Conge(id: "c3", employeeId: empId1, employeeName: "Alice Smith", dateDebut: DateTime.now().subtract(Duration(days: 20)), dateFin: DateTime.now().subtract(Duration(days: 18)), type: CongeType.paye, status: CongeStatus.refusee, managerId: managerId, decisionDate: DateTime.now().subtract(Duration(days: 15))),
      Conge(id: "c4", employeeId: empId2, employeeName: "Bob Johnson", dateDebut: DateTime.now().add(Duration(days: 30)), dateFin: DateTime.now().add(Duration(days: 31)), type: CongeType.sansSolde, status: CongeStatus.enAttente, managerId: managerId),
    ];
  }
}
