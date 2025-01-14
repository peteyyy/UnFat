class Group {
  final String id;
  final String name;
  final String admin;

  Group({required this.id, required this.name, required this.admin});

  factory Group.fromRealtime(String id, Map<dynamic, dynamic> data) {
    return Group(
      id: id,
      name: data['name'] ?? 'Unnamed Group',
      admin: data['admin'] ?? 'Unknown Admin',
    );
  }

  Map<String, dynamic> toRealtime() {
    return {
      'name': name,
      'admin': admin,
    };
  }
}
