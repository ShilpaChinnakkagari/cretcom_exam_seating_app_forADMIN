// This is ONLY for Admin App - represents data from Google Sheet
class StudentModel {
  final String studentId;
  final String studentName;
  final String courseCode;
  final String courseName;
  final String department;
  final String section;
  final String roomNo;
  final String benchNo;

  StudentModel({
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.section,
    required this.roomNo,
    required this.benchNo,
  });

  // From Google Sheet JSON
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['StudentID']?.toString() ?? '',
      studentName: json['StudentName']?.toString() ?? '',
      courseCode: json['CourseCode']?.toString() ?? '',
      courseName: json['CourseName']?.toString() ?? '',
      department: json['Department']?.toString() ?? '',
      section: json['Section']?.toString() ?? '',
      roomNo: json['RoomNo']?.toString() ?? '',
      benchNo: json['BenchNo']?.toString() ?? '',
    );
  }

  // To Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'StudentID': studentId,
      'StudentName': studentName,
      'CourseCode': courseCode,
      'CourseName': courseName,
      'Department': department,
      'Section': section,
      'RoomNo': roomNo,
      'BenchNo': benchNo,
    };
  }
}