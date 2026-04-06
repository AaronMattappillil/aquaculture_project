import 'pond_model.dart';
import 'support_ticket_model.dart';

class AdminUserSummary {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final int numPonds;
  final int activeAlerts;
  final int numReports;
  final int numNotifications;
  final DateTime createdAt;

  AdminUserSummary({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.numPonds,
    required this.activeAlerts,
    required this.numReports,
    required this.numNotifications,
    required this.createdAt,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      role: json['role'] ?? 'FARMER',
      numPonds: json['num_ponds'] ?? 0,
      activeAlerts: json['active_alerts'] ?? 0,
      numReports: json['num_reports'] ?? 0,
      numNotifications: json['num_notifications'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class AdminUserProfile {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final String status;
  final int numPonds;
  final int activeAlerts;
  final int numComplaints;
  final int numReports;
  final int numNotifications;
  final List<PondModel> ponds;
  final List<SupportTicketModel> tickets;
  final DateTime createdAt;

  AdminUserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.status,
    required this.numPonds,
    required this.activeAlerts,
    required this.numComplaints,
    required this.numReports,
    required this.numNotifications,
    required this.ponds,
    required this.tickets,
    required this.createdAt,
  });

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      status: (json['status'] ?? 'active').toString().toUpperCase(),
      numPonds: json['num_ponds'] ?? 0,
      activeAlerts: json['active_alerts'] ?? 0,
      numComplaints: json['num_complaints'] ?? 0,
      numReports: json['num_reports'] ?? 0,
      numNotifications: json['num_notifications'] ?? 0,
      ponds: (json['ponds'] as List? ?? []).map((x) => PondModel.fromJson(x)).toList(),
      tickets: (json['tickets'] as List? ?? []).map((x) => SupportTicketModel.fromJson(x)).toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class AdminDashboardTickets {
  final int open;
  final int resolved;

  AdminDashboardTickets({required this.open, required this.resolved});

  factory AdminDashboardTickets.fromJson(Map<String, dynamic> json) {
    return AdminDashboardTickets(
      open: json['open'] ?? 0,
      resolved: json['resolved'] ?? 0,
    );
  }
}

class AdminDashboardModel {
  final int totalUsers;
  final int totalPonds;
  final AdminDashboardTickets tickets;

  AdminDashboardModel({
    required this.totalUsers,
    required this.totalPonds,
    required this.tickets,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: json['total_users'] ?? 0,
      totalPonds: json['total_ponds'] ?? 0,
      tickets: AdminDashboardTickets.fromJson(json['tickets'] ?? {}),
    );
  }
}

class AdminUserDetailUser {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final String status;

  AdminUserDetailUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.status,
  });

  factory AdminUserDetailUser.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      status: (json['status'] ?? 'active').toString().toUpperCase(),
    );
  }
}

class AdminUserDetailPond {
  final String id;
  final String name;
  final String fishSpecies;
  final int fishUnits;
  final String status;

  AdminUserDetailPond({
    required this.id,
    required this.name,
    required this.fishSpecies,
    required this.fishUnits,
    required this.status,
  });

  factory AdminUserDetailPond.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailPond(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      fishSpecies: json['fish_species'] ?? 'Tilapia',
      fishUnits: json['fish_units'] ?? 0,
      status: json['status'] ?? 'INACTIVE',
    );
  }
}

class AdminUserDetailTicket {
  final String id;
  final String category;
  final String subject;
  final String status;
  final DateTime createdAt;

  AdminUserDetailTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  factory AdminUserDetailTicket.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailTicket(
      id: json['id'] ?? '',
      category: json['category'] ?? 'General',
      subject: json['subject'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class AdminUserDetailPonds {
  final int count;
  final List<AdminUserDetailPond> items;

  AdminUserDetailPonds({required this.count, required this.items});

  factory AdminUserDetailPonds.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailPonds(
      count: json['count'] ?? 0,
      items: (json['items'] as List? ?? []).map((x) => AdminUserDetailPond.fromJson(x)).toList(),
    );
  }
}

class AdminUserDetailTickets {
  final int count;
  final List<AdminUserDetailTicket> items;

  AdminUserDetailTickets({required this.count, required this.items});

  factory AdminUserDetailTickets.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailTickets(
      count: json['count'] ?? 0,
      items: (json['items'] as List? ?? []).map((x) => AdminUserDetailTicket.fromJson(x)).toList(),
    );
  }
}

class AdminUserDetail {
  final AdminUserDetailUser user;
  final AdminUserDetailPonds ponds;
  final AdminUserDetailTickets tickets;

  AdminUserDetail({
    required this.user,
    required this.ponds,
    required this.tickets,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserDetail(
      user: AdminUserDetailUser.fromJson(json['user'] ?? {}),
      ponds: AdminUserDetailPonds.fromJson(json['ponds'] ?? {}),
      tickets: AdminUserDetailTickets.fromJson(json['tickets'] ?? {}),
    );
  }
}
