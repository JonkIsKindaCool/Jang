package jang.utils;

import haxe.Rest;
import jang.structures.Expr;
import jang.structures.Token;

using StringTools;

class Printer {
	public static function printTokens(tokens:Array<Token>) {
		for (token in tokens) {
			Printer.println(token);
		}
	}

	public static function printExpr(expr:Expr, ?spaces:Int = 0) {
		switch (expr) {
			case New(e, args):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Function(');

				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Instance: $e');
				if (args.length > 0) {
					Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Argument:');
					for (arg in args) {
						printExpr(arg, spaces + 8);
					}
				}

				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Function(b, args, type, name):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Function(');

				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Name: $name');
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Type: $type');

				if (b.length > 0) {
					Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Body:');
					for (expr in b) {
						printExpr(expr, spaces + 8);
					}
				}

				if (args.length > 0) {
					Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Argument:');
					for (arg in args) {
						Printer.println('${[for (i in 0...spaces + 8) " "].join("")}Name: ${arg.name} | Type: ${arg.type}');
					}
				}
				Printer.println('${[for (i in 0...spaces) " "].join("")})');

			case While(c, b):
				Printer.println('${[for (i in 0...spaces) " "].join("")}While(');
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Condition:');

				printExpr(c, spaces + 8);

				if (b.length > 0) {
					Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Body:');
					for (expr in b) {
						printExpr(expr, spaces + 8);
					}
				}

				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Ender(e):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Ender($e)');
			case Import(p):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Import(${p.join(".")})');
			case NumberLiteral(value):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Number($value)');
			case BooleanLiteral(value):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Boolean($value)');
			case NullLiteral:
				Printer.println('${[for (i in 0...spaces) " "].join("")}Null');
			case Identifier(name):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Identifier($name)');
			case Call(f, args):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Call(');
				printExpr(f, spaces + 4);
				if (args.length > 0) {
					Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Arguments: ');
					for (expr in args) {
						printExpr(expr, spaces + 8);
					}
				}
				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Top(e):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Top(');
				printExpr(e, spaces + 4);
				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Field(p, f):
				Printer.println('${[for (i in 0...spaces) " "].join("")}FieldAccess(');
				printExpr(p, spaces + 4);
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Field: $f');
				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Block(statements):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Block(');
				for (statement in statements) {
					printExpr(statement, spaces + 4);
				}
				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case BinaryOp(left, op, right):
				Printer.println('${[for (i in 0...spaces) " "].join("")}BinaryOp(');

				printExpr(left, spaces + 4);

				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}$op');

				printExpr(right, spaces + 4);

				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case Assignment(name, right, isConstant, t):
				Printer.println('${[for (i in 0...spaces) " "].join("")}Assignment(');
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}Value name: $name');

				printExpr(right, spaces + 4);
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}isConstant: $isConstant');
				Printer.println('${[for (i in 0...spaces + 4) " "].join("")}type: $t');

				Printer.println('${[for (i in 0...spaces) " "].join("")})');
			case StringLiteral(value):
				Printer.println('${[for (i in 0...spaces) " "].join("")}String($value)');
		}
	}

	public static inline function println(content:Rest<Dynamic>) {
		#if js
		js.Syntax.code("console.log({0})", content.toArray().join(", "));
		#else
		Sys.println(content.toArray().join(", "));
		#end
	}
}
