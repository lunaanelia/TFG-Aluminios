class OpcionEntrega {
  final String id;
  final String label;

  OpcionEntrega({required this.id, required this.label});

  factory OpcionEntrega.fromJson(Map<String, dynamic> json) {
    return OpcionEntrega(
      id: json['id'],
      label: json['label'],
    );
  }
}

