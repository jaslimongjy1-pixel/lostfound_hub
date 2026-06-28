class ReportModel {
  final int reportId;
  final int userId;
  final String title;
  final String description;
  final String type;
  final String category;
  final String location;
  final String status;
  final String image; // Stores the filename
  final String date;

  const ReportModel({
    required this.reportId,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.location,
    required this.status,
    required this.image,
    required this.date,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: int.tryParse(json["report_id"].toString()) ?? 0,
      userId: int.tryParse(json["user_id"].toString()) ?? 0,
      title: (json["report_title"] ?? "").toString(),
      description: (json["report_description"] ?? "").toString(),
      type: (json["report_type"] ?? "").toString(),
      category: (json["report_category"] ?? "").toString(),
      location: (json["report_location"] ?? "").toString(),
      status: (json["report_status"] ?? "").toString(),
      image: (json["report_image"] ?? "").toString(),
      date: (json["report_date"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "report_id": reportId,
      "user_id": userId,
      "report_title": title,
      "report_description": description,
      "report_type": type,
      "report_category": category,
      "report_location": location,
      "report_status": status,
      "report_image": image,
      "report_date": date,
    };
  }
}
