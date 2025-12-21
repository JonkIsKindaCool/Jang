package jang.utils;

import haxe.Rest;
import jang.structures.Expr;
import jang.structures.Token;

using StringTools;

class Printer {
	public static function printTokens(tokens:Array<TokenInfo>) {
		for (token in tokens) {
			Printer.println(token);
		}
	}

	public static function printExpr(e:ExprInfo, ?spaces:Int = 0) {
		printWithSpaces('{', spaces);
		switch (e.expr) {
			case NumberLiteral(value):
				printWithSpaces('Type: Number Literal', spaces + 4);
				printWithSpaces('Value: $value', spaces + 4);
			case BooleanLiteral(value):
				printWithSpaces('Type: Boolean Literal', spaces + 4);
				printWithSpaces('Value: $value', spaces + 4);
			case NullLiteral:
				printWithSpaces('Type: Null Literal', spaces + 4);
			case Identifier(name):
				printWithSpaces('Type: Identifier', spaces + 4);
				printWithSpaces('Name: $name', spaces + 4);
			case Block(statements):
				for (expr in statements)
					printExpr(expr, spaces + 4);
			case BinaryOp(left, op, right):
				printWithSpaces('Type: BinaryOp', spaces + 4);
				printWithSpaces('Operator: $op', spaces + 4);
				printWithSpaces('Left: ', spaces + 4);
				printExpr(left, spaces + 8);
				printWithSpaces('Right: ', spaces + 4);
				printExpr(right, spaces + 8);
			case Assignment(name, right, isConstant, type):
				printWithSpaces('Type: Assignment', spaces + 4);
				printWithSpaces('name: $name', spaces + 4);
				printWithSpaces('isConstant: $isConstant', spaces + 4);
				printWithSpaces('type: ${type.getName()}', spaces + 4);
				printWithSpaces('Value: ', spaces + 4);
				printExpr(right, spaces + 8);
			case StringLiteral(value):
				printWithSpaces('Type: String Literal', spaces + 4);
				printWithSpaces('Value: $value', spaces + 4);
			case Field(p, f):
				printWithSpaces('Type: Field Access', spaces + 4);
				printWithSpaces('Parent:', spaces + 4);
				printExpr(p, spaces + 8);
				printWithSpaces('Field: $f', spaces + 4);
			case Call(f, args):
				printWithSpaces('Type: Function Call', spaces + 4);
				printWithSpaces('Function:', spaces + 4);
				printExpr(f, spaces + 8);
				printWithSpaces('Arguments:', spaces + 4);
				for (arg in args) {
					printExpr(arg, spaces + 8);
				}
			case Top(e):
				printExpr(e, spaces);
			case While(c, b):
				printWithSpaces('Type: While Loop', spaces + 4);
				printWithSpaces('Condition:', spaces + 4);
				printExpr(c, spaces + 8);
				printWithSpaces('Body:', spaces + 4);
				for (expr in b) {
					printExpr(expr, spaces + 8);
				}
			case New(e, args):
				printWithSpaces('Type: New', spaces + 4);
				printWithSpaces('Class: $e', spaces + 4);
				printWithSpaces('Arguments:', spaces + 4);
				for (arg in args) {
					printExpr(arg, spaces + 8);
				}
			case Import(p):
				printWithSpaces('Type: Import', spaces + 4);
				printWithSpaces('Path: ${p.join(".")}', spaces + 4);
			case Ender(e):
				switch (e) {
					case Return(e):
						printWithSpaces('Type: Return', spaces + 4);
						printWithSpaces('Expression:', spaces + 4);
						printExpr(e, spaces + 8);
					case Break:
						printWithSpaces('Type: Break', spaces + 4);
					case Continue:
						printWithSpaces('Type: Continue', spaces + 4);
				}
			case Function(expr, args, type, name):
			case If(cond, body, elsE):
				printWithSpaces('Type: If Statement', spaces + 4);
				printWithSpaces('Condition:', spaces + 4);
				printExpr(cond, spaces + 8);
				printWithSpaces('Body:', spaces + 4);
				printExpr(body, spaces + 8);

				if (elsE != null) {
					printWithSpaces('Else Statement:', spaces + 4);
					printExpr(elsE, spaces + 8);
				}
			case Object(fields):
				printWithSpaces('Type: Object Literal', spaces + 4);
				printWithSpaces('Fields: ', spaces + 4);
				for (field in fields) {
					printWithSpaces('Name: ${field.name}', spaces + 8);
					printExpr(field.value, spaces + 8);
				}
			case Array(inner):
				printWithSpaces('Type: Array Literal', spaces + 4);
				printWithSpaces('Fields: ', spaces + 4);
				for (f in inner) {
					printExpr(f, spaces + 8);
				}
			case Index(p, i):
				printWithSpaces('Type: Index', spaces + 4);
				printWithSpaces('Parent:', spaces + 4);
				printExpr(p, spaces + 8);
				printWithSpaces('Index:', spaces + 4);
				printExpr(i, spaces + 8);
		}
		printWithSpaces('}', spaces);
	}

	private static function printWithSpaces(msg:String, spaces:Int) {
		println('${[for (i in 0...spaces) " "].join("")}$msg');
	}

	public static function println(content:Rest<Dynamic>) {
		#if js
		js.Syntax.code("console.log({0})", content.toArray().join(", "));
		#else
		Sys.println(content.toArray().join(", "));
		#end
	}
}
