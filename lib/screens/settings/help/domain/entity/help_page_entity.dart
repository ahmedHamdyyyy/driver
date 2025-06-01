class HelpPageEntity {
  final String title;
  final String content;
  final void Function()? onTap;

  HelpPageEntity({
    required this.title,
    this.onTap,
    required this.content,
  });
}
