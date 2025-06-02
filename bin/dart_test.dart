import 'package:dart_test/parser.dart' as parser;

void main(List<String> arguments) {
  var expression = "1+2";
  var node = parser.parse(expression);
  ;
  print('$expression: ${node.evaluate()}');
}
