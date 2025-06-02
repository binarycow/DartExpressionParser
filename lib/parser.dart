import 'ast.dart';

enum _TokenType {
  eof,
  whitespace,
  integer,
  plus,
  minus,
  asterisk,
  slash,
  parenOpen,
  parenClose,
}

typedef _TokenData = ({_TokenType tokenType, int length});

class _OperatorTokens {
  static const List<(_TokenType, BinaryOperator)> additiveOperators = [
    (_TokenType.plus, BinaryOperator.add),
    (_TokenType.minus, BinaryOperator.subtract),
  ];
  static const List<(_TokenType, BinaryOperator)> multiplicativeOperators = [
    (_TokenType.asterisk, BinaryOperator.multiply),
    (_TokenType.slash, BinaryOperator.divide),
  ];
  static const List<(_TokenType, UnaryOperator)> unaryOperators = [
    (_TokenType.plus, UnaryOperator.plus),
    (_TokenType.minus, UnaryOperator.negate),
  ];
}

class _Lexer {
  String _text;
  String tokenSpan = "";
  _TokenType tokenType = _TokenType.eof;
  _Lexer(this._text);

  _Lexer copy() {
    var result = _Lexer(_text);
    result.tokenSpan = tokenSpan;
    result.tokenType = tokenType;
    return result;
  }

  static List<(RegExp, _TokenType)> tokenRegexes = [
    (RegExp(r'^\s+'), _TokenType.whitespace),
    (RegExp(r'^\d+'), _TokenType.integer),
    (RegExp(r'^\+'), _TokenType.plus),
    (RegExp(r'^-'), _TokenType.minus),
    (RegExp(r'^\*'), _TokenType.asterisk),
    (RegExp(r'^/'), _TokenType.slash),
    (RegExp(r'\('), _TokenType.parenOpen),
    (RegExp(r'\)'), _TokenType.parenClose),
  ];

  bool read() {
    if(_text.isEmpty) {
      tokenType = _TokenType.eof;
      tokenSpan = "";
      return false;
    }
    var match = getMatch(_text);
    tokenType = match.tokenType;
    tokenSpan = _text.substring(0, match.length);
    _text = _text.substring(match.length);
    return true;
  }

  T? tryConsumeOperator<T>(List<(_TokenType, T)> expected) {
    for(var (type, result) in expected) {
      if(tryConsumeToken(type)) {
        return result;
      }
    }
    return null;
  }

  bool tryConsumeToken(_TokenType expectedTokenType)
  {
    if(tokenType != expectedTokenType) {
      return false;
    }
    read();
    return true;
  }

  String? consumeToken(_TokenType expectedTokenType)
  {
    if(tokenType != expectedTokenType) {
      return null;
    }
    var result = tokenSpan;
    read();
    return result;
  }

  static _TokenData getMatch(String text)
  {
    var bestType = _TokenType.eof;
    var bestLength = 0;
    for(var (regex, type) in tokenRegexes) {
        var match = regex.firstMatch(text);
        if(match == null) {
          continue;
        }
        assert(match.start == 0);
        if(match.end > bestLength) {
          bestType = type;
          bestLength = match.end;
        }
    }
    if(bestLength == 0) {
      return (tokenType: _TokenType.eof, length: 1);
    }
    return (tokenType: bestType, length: bestLength);
  }

}


AstNode parse(String text) {
  var lexer = _Lexer(text);
  if(!lexer.read()) {
    throw UnimplementedError();
  }
  var result = _parseExpression(lexer);
  if(result == null) {
    throw UnimplementedError();
  }
  if(lexer.read()) {
    throw UnimplementedError();
  }
  return result;
}

AstNode? _parseExpression(_Lexer lexer) {
  var left = _parseTerm(lexer);
  if(left == null) {
    return null;
  }
  var operator = lexer.tryConsumeOperator(_OperatorTokens.additiveOperators);
  while(operator != null) {
    var right = _parseTerm(lexer);
    if(right == null) {
      throw UnimplementedError();
    }
    left = BinaryNode(left!, operator, right);
    operator = lexer.tryConsumeOperator(_OperatorTokens.additiveOperators);
  }
  return left;
}

AstNode? _parseTerm(_Lexer lexer) {
  var left = _parseFactor(lexer);
  if(left == null) {
    return null;
  }
  var operator = lexer.tryConsumeOperator(_OperatorTokens.multiplicativeOperators);
  while(operator != null) {
    var right = _parseFactor(lexer);
    if(right == null) {
      throw UnimplementedError();
    }
    left = BinaryNode(left!, operator, right);
    operator = lexer.tryConsumeOperator(_OperatorTokens.multiplicativeOperators);
  }
  return left;
}



AstNode? _parseFactor(_Lexer lexer) {
  var operator = lexer.tryConsumeOperator(_OperatorTokens.unaryOperators);
  if(operator == null) {
    return _parsePrimary(lexer);
  }
  var operators = [ operator ];
  operator = lexer.tryConsumeOperator(_OperatorTokens.unaryOperators);
  while(operator != null) {
    operators.add(operator);
    operator = lexer.tryConsumeOperator(_OperatorTokens.unaryOperators);
  }
  var expression = _parsePrimary(lexer);
  if(expression == null) {
    throw UnimplementedError();
  }
  for(var op in operators.reversed) {
    expression = UnaryNode(op, expression!);
  }
  return expression;
}


AstNode? _parsePrimary(_Lexer lexer) {
  var result = _parseInteger(lexer)
      ?? _parseGrouping(lexer);
  return result;
}

AstNode? _parseInteger(_Lexer lexer)
  => switch(lexer.consumeToken(_TokenType.integer)) {
    var text? => IntegerNode(int.parse(text)),
    _ => null,
  };

AstNode? _parseGrouping(_Lexer lexer) {
  if(!lexer.tryConsumeToken(_TokenType.parenOpen)) {
    return null;
  }
  var result = _parseExpression(lexer);
  return result != null && lexer.tryConsumeToken(_TokenType.parenOpen)
    ? result
    : throw UnimplementedError();
}
