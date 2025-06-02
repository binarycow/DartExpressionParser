enum BinaryOperator { add, subtract, multiply, divide }
enum UnaryOperator { plus, negate }

sealed class AstNode {
  num evaluate();
}

final class BinaryNode extends AstNode {
  BinaryNode(this.left, this.operator, this.right);
  final AstNode left;
  final AstNode right;
  final BinaryOperator operator;

  @override
  num evaluate() => switch(operator) {
    BinaryOperator.add => left.evaluate() + right.evaluate(),
    BinaryOperator.subtract => left.evaluate() - right.evaluate(),
    BinaryOperator.multiply => left.evaluate() * right.evaluate(),
    BinaryOperator.divide => left.evaluate() / right.evaluate(),
  };
}

final class UnaryNode extends AstNode {
  UnaryNode(this.operator, this.expression);
  final AstNode expression;
  final UnaryOperator operator;

  @override
  num evaluate() => switch(operator) {
    UnaryOperator.plus => expression.evaluate(),
    UnaryOperator.negate => -expression.evaluate(),
  };
}

final class IntegerNode extends AstNode {
  IntegerNode(this.value);
  final int value;

  @override
  num evaluate() => value;
}

final class DoubleNode extends AstNode {
  DoubleNode(this.value);
  final double value;

  @override
  num evaluate() => value;
}