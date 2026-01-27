class InstallationChecklistItem {
  String title;
  bool completed;

  InstallationChecklistItem({
    required this.title,
    required this.completed,
  });

  factory InstallationChecklistItem.fromJson(Map<String, dynamic> json) {
    return InstallationChecklistItem(
      title: json["title"],
      completed: json["completed"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "title": title,
        "completed": completed,
      };
}
