enum UserRole { rhAdmin, manager, employee }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? contractType;
  final DateTime? contractStartDate;
  final double? salary;
  final String? phone;
  final String? address;
  final List<String>? documents; // List of document URLs/IDs
  final String? managerId; // For employees
  final List<String>? teamMemberIds; // For managers

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.contractType,
    this.contractStartDate,
    this.salary,
    this.phone,
    this.address,
    this.documents,
    this.managerId,
    this.teamMemberIds,
  });

  // Factory constructor for JSON parsing (adjust based on actual API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] as String,
      email: json["email"] as String,
      name: json["name"] as String,
      role: UserRole.values.firstWhere((e) => e.toString() == "UserRole.${json["role"]}"),
      contractType: json["contractType"] as String?,
      contractStartDate: json["contractStartDate"] != null ? DateTime.parse(json["contractStartDate"] as String) : null,
      salary: (json["salary"] as num?)?.toDouble(),
      phone: json["phone"] as String?,
      address: json["address"] as String?,
      documents: (json["documents"] as List<dynamic>?)?.map((e) => e as String).toList(),
      managerId: json["managerId"] as String?,
      teamMemberIds: (json["teamMemberIds"] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  // Method to convert User object to JSON (adjust based on API needs)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "name": name,
      "role": role.toString().split(".").last,
      "contractType": contractType,
      "contractStartDate": contractStartDate?.toIso8601String(),
      "salary": salary,
      "phone": phone,
      "address": address,
      "documents": documents,
      "managerId": managerId,
      "teamMemberIds": teamMemberIds,
    };
  }
}

