package jang.utils;

import jang.structures.Expr;
import jang.structures.Token;

using StringTools;

class Printer {
	public static function printTokens(tokens:Array<Token>) {
		for (token in tokens) {
			Sys.println(token);
		}
	}

	public static function printExpr(expr:Expr, ?spaces:Int = 0) {
		switch (expr) {
			case New(e, args):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Function(');

				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Instance: $e');
				if (args.length > 0) {
					Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Argument:');
					for (arg in args) {
						printExpr(arg, spaces + 8);
					}
				}

				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Function(b, args, type, name):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Function(');

				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Name: $name');
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Type: $type');

				if (b.length > 0) {
					Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Body:');
					for (expr in b) {
						printExpr(expr, spaces + 8);
					}
				}

				if (args.length > 0) {
					Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Argument:');
					for (arg in args) {
						Sys.println('${[for (i in 0...spaces + 8) " "].join("")}Name: ${arg.name} | Type: ${arg.type}');
					}
				}
				Sys.println('${[for (i in 0...spaces) " "].join("")})');

			case While(c, b):
				Sys.println('${[for (i in 0...spaces) " "].join("")}While(');
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Condition:');

				printExpr(c, spaces + 8);

				if (b.length > 0) {
					Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Body:');
					for (expr in b) {
						printExpr(expr, spaces + 8);
					}
				}

				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Ender(e):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Ender($e)');
			case Import(p):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Import(${p.join(".")})');
			case NumberLiteral(value):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Number($value)');
			case BooleanLiteral(value):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Boolean($value)');
			case NullLiteral:
				Sys.println('${[for (i in 0...spaces) " "].join("")}Null');
			case Identifier(name):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Identifier($name)');
			case Call(f, args):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Call(');
				printExpr(f, spaces + 4);
				if (args.length > 0) {
					Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Arguments: ');
					for (expr in args) {
						printExpr(expr, spaces + 8);
					}
				}
				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Top(e):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Top(');
				printExpr(e, spaces + 4);
				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Field(p, f):
				Sys.println('${[for (i in 0...spaces) " "].join("")}FieldAccess(');
				printExpr(p, spaces + 4);
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Field: $f');
				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Block(statements):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Block(');
				for (statement in statements) {
					printExpr(statement, spaces + 4);
				}
				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case BinaryOp(left, op, right):
				Sys.println('${[for (i in 0...spaces) " "].join("")}BinaryOp(');

				printExpr(left, spaces + 4);

				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}$op');

				printExpr(right, spaces + 4);

				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case Assignment(name, right, isConstant, t):
				Sys.println('${[for (i in 0...spaces) " "].join("")}Assignment(');
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}Value name: $name');

				printExpr(right, spaces + 4);
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}isConstant: $isConstant');
				Sys.println('${[for (i in 0...spaces + 4) " "].join("")}type: $t');

				Sys.println('${[for (i in 0...spaces) " "].join("")})');
			case StringLiteral(value):
				Sys.println('${[for (i in 0...spaces) " "].join("")}String($value)');
		}
	}
}
