import 'package:archit/commands/cli.dart';

Future<void> main(List<String> args) async {
  final cli = Cli();
  await cli.run(args);
}
