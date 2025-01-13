class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  // Convert Firestore document to Group model
  factory Group.fromFirestore(Map<String, dynamic> data, String id) {
    return Group(
      id: id,
      name: data['name'],
    );
  }

  // Convert Group model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }
}
