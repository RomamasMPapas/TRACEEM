import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Add top-level class comment if it doesn't have one
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)class (\w+) extends (StatefulWidget|StatelessWidget|State<.*?>) {'), (match) {
      final className = match.group(1);
      return '/// The [$className] class is responsible for managing its respective UI components and state.\nclass $className extends ${match.group(2)} {';
    });

    // Add build method comment
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  @override\n  Widget build\(BuildContext context\) {'), (match) {
      return '  /// Builds the visual structure of this widget, returning the widget tree.\n  @override\n  Widget build(BuildContext context) {';
    });

    // Add initState comment
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  @override\n  void initState\(\) {'), (match) {
      return '  /// Initializes the state of the widget before it is built.\n  @override\n  void initState() {';
    });

    // Add dispose comment
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  @override\n  void dispose\(\) {'), (match) {
      return '  /// Cleans up resources when the widget is permanently removed from the tree.\n  @override\n  void dispose() {';
    });

    // Add function comments for generic void functions (simple regex)
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  void (_[a-zA-Z0-9]+)\((.*?)\) {'), (match) {
      final funcName = match.group(1);
      return '  /// Executes the logic for $funcName.\n  void $funcName(${match.group(2)}) {';
    });
    
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  Future<void> (_[a-zA-Z0-9]+)\((.*?)\) async {'), (match) {
      final funcName = match.group(1);
      return '  /// Asynchronously executes the logic for $funcName.\n  Future<void> $funcName(${match.group(2)}) async {';
    });

    // Add function comments for Widget builder methods
    content = content.replaceAllMapped(RegExp(r'(?<!///.*\n)  Widget (_[a-zA-Z0-9]+)\((.*?)\) {'), (match) {
      final funcName = match.group(1);
      return '  /// Builds and returns the $funcName custom widget component.\n  Widget $funcName(${match.group(2)}) {';
    });

    file.writeAsStringSync(content);
  }
  print("Comments added successfully to all files.");
}
