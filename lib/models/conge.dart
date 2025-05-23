enum CongeStatus { enAttente, approuvee, refusee }

enum CongeType { paye, maladie, sansSolde, autre }

class Conge {
  final String id;
  final String employeeId;
  final String employeeName; // For display purposes
  final DateTime dateDebut;
  final DateTime dateFin;
  final CongeType type;
  final CongeStatus status;
  final String? motif;
  final String? managerId; // Who approved/refused
  final DateTime? decisionDate;

  Conge({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.dateDebut,
    required this.dateFin,
    required this.type,
    required this.status,
    this.motif,
    this.managerId,
    this.decisionDate,
  });

  // Factory constructor for JSON parsing (adjust based on actual API response)
  factory Conge.fromJson(Map<String, dynamic> json) {
    return Conge(
      id: json["id"] as String,
      employeeId: json["employeeId"] as String,
      employeeName: json["employeeName"] as String? ?? "N/A", // Handle potential null
      dateDebut: DateTime.parse(json["dateDebut"] as String),
      dateFin: DateTime.parse(json["dateFin"] as String),
      type: CongeType.values.firstWhere((e) => e.toString() == "CongeType.${json["type"]}", orElse: () => CongeType.autre),
      status: CongeStatus.values.firstWhere((e) => e.toString() == "CongeStatus.${json["status"]}", orElse: () => CongeStatus.enAttente),
      motif: json["motif"] as String?,
      managerId: json["managerId"] as String?,
      decisionDate: json["decisionDate"] != null ? DateTime.parse(json["decisionDate"] as String) : null,
    );
  }

  // Method to convert Conge object to JSON (adjust based on API needs)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "employeeId": employeeId,
      "employeeName": employeeName,
      "dateDebut": dateDebut.toIso8601String(),
      "dateFin": dateFin.toIso8601String(),
      "type": type.toString().split(".").last,
      "status": status.toString().split(".").last,
      "motif": motif,
      "managerId": managerId,
      "decisionDate": decisionDate?.toIso8601String(),
    };
  }

  // Calculate duration in days (simple example, might need refinement for business days)
  int get durationInDays {
    return dateFin.difference(dateDebut).inDays + 1;
  }
}

