class Student {
  final String id;
  final String nisn;
  final String fullName;
  final int? classId;

  Student({
    required this.id,
    required this.nisn,
    required this.fullName,
    this.classId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      nisn: json['nisn'],
      fullName: json['full_name'],
      classId: json['class_id'],
    );
  }
}