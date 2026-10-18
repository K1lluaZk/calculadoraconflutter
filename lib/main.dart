import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const ScientificCalculatorApp());

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora científica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B8CFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF141720),
        ),
        fontFamily: 'Roboto',
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String? _result;
  bool _degrees = true;
  bool _justEvaluated = false;

  static const _accent = Color(0xFFB5A8FF);
  static const _muted = Color(0xFF8B91A2);
  static const _keys = <List<String>>[
    ['sin', 'cos', 'tan', 'ln', 'log'],
    ['√', 'x²', 'exp', 'π', '÷'],
    ['(', ')', '7', '8', '9'],
    ['AC', '⌫', '4', '5', '6'],
    ['×', '1', '2', '3', '−'],
    ['±', '0', '.', '=', '+'],
  ];

  void _press(String key) {
    setState(() {
      if (key == 'AC') {
        _expression = '';
        _result = null;
        _justEvaluated = false;
        return;
      }
      if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _justEvaluated = false;
        _refreshResult();
        return;
      }
      if (key == '=') {
        _evaluateFinal();
        return;
      }
      if (key == '±') {
        _expression = _expression.isEmpty ? '−' : '−($_expression)';
        _justEvaluated = false;
        _refreshResult();
        return;
      }

      final isOperator = const {'+', '−', '×', '÷', '^'}.contains(key);
      if (_justEvaluated && !isOperator) _expression = '';
      _justEvaluated = false;

      switch (key) {
        case 'sin':
        case 'cos':
        case 'tan':
        case 'ln':
        case 'log':
        case 'exp':
          _expression += '$key(';
          break;
        case '√':
          _expression += 'sqrt(';
          break;
        case 'x²':
          _expression += '^2';
          break;
        case 'π':
        case 'e':
          _expression += key;
          break;
        default:
          _expression += key;
          break;
      }
      _refreshResult();
    });
  }

  void _refreshResult() {
    try {
      final value = _ExpressionParser(_expression, degrees: _degrees).parse();
      _result = _format(value);
    } on FormatException {
      _result = null;
    } on RangeError {
      _result = null;
    }
  }

  void _evaluateFinal() {
    try {
      final value = _ExpressionParser(_expression, degrees: _degrees).parse();
      _expression = _format(value);
      _result = null;
      _justEvaluated = true;
    } on Object {
      _result = 'Expresión inválida';
    }
  }

  String _format(double value) {
    if (!value.isFinite) throw const FormatException('Resultado no finito');
    if (value.abs() < 1e-12) value = 0;
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    final precise = value.toStringAsPrecision(10);
    if (precise.contains('e')) {
      final parts = precise.split('e');
      final mantissa = parts.first.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      return '${mantissa}e${parts.last}';
    }
    return precise.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 22,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      Expanded(child: _buildDisplay()),
                      const SizedBox(height: 18),
                      _buildKeypad(wide),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calculate_outlined, color: _accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calculadora MS',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('CIENTÍFICA',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 2.1,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _degrees = !_degrees;
              _refreshResult();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF292D39)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_degrees ? 'DEG' : 'RAD',
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          ),
        ],
      );

  Widget _buildDisplay() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 25),
        decoration: BoxDecoration(
          color: const Color(0xFF12151D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF20232E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('EXPRESIÓN',
                  style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _expression.isEmpty ? '0' : _expression,
                  style: TextStyle(
                    color: _expression.isEmpty ? const Color(0xFF646A78) : Colors.white,
                    fontSize: _expression.length > 18 ? 27 : 34,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Text('RESULTADO',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Flexible(
                  child: Text(
                    _result ?? ' ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _result == 'Expresión inválida' ? Colors.orangeAccent : _accent,
                      fontSize: _result == 'Expresión inválida' ? 15 : 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildKeypad(bool wide) {
    return Column(
      children: _keys
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: row
                      .map((key) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _key(key, wide),
                            ),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _key(String label, bool wide) {
    final isScientific = const {'sin', 'cos', 'tan', 'ln', 'log', 'exp', '√', 'x²', 'π', 'e', '(', ')'}
        .contains(label);
    final isOperator = const {'÷', '×', '−', '+'}.contains(label);
    final isAction = label == 'AC' || label == '⌫';
    final isEquals = label == '=';
    final background = isEquals
        ? _accent
        : isAction
            ? const Color(0xFF24202B)
            : isOperator
                ? const Color(0xFF222332)
                : isScientific
                    ? const Color(0xFF171A24)
                    : const Color(0xFF1B1F29);
    final foreground = isEquals
        ? const Color(0xFF15121E)
        : isAction
            ? const Color(0xFFF2A6B6)
            : isOperator || isScientific
                ? _accent
                : Colors.white;
    return SizedBox(
      height: wide ? 62 : 54,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _press(label),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: isScientific ? 14 : (label.length > 1 ? 14 : 20),
                fontWeight: isEquals || isOperator || isAction
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recursive descent parser with standard operator precedence.
class _ExpressionParser {
  _ExpressionParser(this.input, {required this.degrees});

  final String input;
  final bool degrees;
  int _index = 0;

  double parse() {
    if (input.trim().isEmpty) throw const FormatException('Expresión vacía');
    final value = _expression();
    _spaces();
    if (_index != input.length) throw const FormatException('Token inesperado');
    if (!value.isFinite) throw const FormatException('Resultado no finito');
    return value;
  }

  double _expression() {
    var value = _term();
    while (true) {
      _spaces();
      if (_take('+')) {
        value += _term();
      } else if (_take('−') || _take('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  double _term() {
    var value = _unary();
    while (true) {
      _spaces();
      if (_take('×') || _take('*')) {
        value *= _unary();
      } else if (_take('÷') || _take('/')) {
        final divisor = _unary();
        if (divisor == 0) throw const FormatException('División por cero');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _unary() {
    _spaces();
    if (_take('+')) return _unary();
    if (_take('−') || _take('-')) return -_unary();
    return _power();
  }

  double _power() {
    var value = _primary();
    _spaces();
    if (_take('^')) value = math.pow(value, _unary()).toDouble();
    return value;
  }

  double _primary() {
    _spaces();
    if (_take('(')) {
      final value = _expression();
      _expect(')');
      return value;
    }
    if (_index >= input.length) throw const FormatException('Falta un valor');
    if (_digit(input[_index]) || input[_index] == '.') return _number();

    final name = _identifier();
    if (name == 'π') return math.pi;
    if (name == 'e') return math.e;
    _spaces();
    _expect('(');
    final argument = _expression();
    _expect(')');
    switch (name) {
      case 'sin':
        return math.sin(_angle(argument));
      case 'cos':
        return math.cos(_angle(argument));
      case 'tan':
        final angle = _angle(argument);
        if ((math.cos(angle)).abs() < 1e-12) throw const FormatException('Tangente indefinida');
        return math.tan(angle);
      case 'ln':
        if (argument <= 0) throw const FormatException('Dominio inválido');
        return math.log(argument);
      case 'log':
        if (argument <= 0) throw const FormatException('Dominio inválido');
        return math.log(argument) / math.ln10;
      case 'sqrt':
        if (argument < 0) throw const FormatException('Dominio inválido');
        return math.sqrt(argument);
      case 'exp':
        return math.exp(argument);
      default:
        throw const FormatException('Función desconocida');
    }
  }

  double _angle(double value) => degrees ? value * math.pi / 180 : value;

  double _number() {
    final start = _index;
    var hasDigit = false;
    while (_index < input.length && _digit(input[_index])) {
      hasDigit = true;
      _index++;
    }
    if (_take('.')) {
      while (_index < input.length && _digit(input[_index])) {
        hasDigit = true;
        _index++;
      }
    }
    if (!hasDigit) throw const FormatException('Número inválido');
    if (_index < input.length && (input[_index] == 'e' || input[_index] == 'E')) {
      final exponentStart = _index++;
      if (_index < input.length && (input[_index] == '+' || input[_index] == '-')) _index++;
      final digitStart = _index;
      while (_index < input.length && _digit(input[_index])) _index++;
      if (digitStart == _index) _index = exponentStart;
    }
    return double.parse(input.substring(start, _index));
  }

  String _identifier() {
    final start = _index;
    if (input[_index] == 'π') return input[_index++];
    while (_index < input.length && RegExp(r'[a-zA-Z]').hasMatch(input[_index])) {
      _index++;
    }
    if (_index == start) throw const FormatException('Token inválido');
    return input.substring(start, _index);
  }

  bool _digit(String char) => char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  void _spaces() {
    while (_index < input.length && input[_index].trim().isEmpty) _index++;
  }

  bool _take(String char) {
    if (_index < input.length && input[_index] == char) {
      _index++;
      return true;
    }
    return false;
  }

  void _expect(String char) {
    _spaces();
    if (!_take(char)) throw FormatException('Se esperaba $char');
  }
}
