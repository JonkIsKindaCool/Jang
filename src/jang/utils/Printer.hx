package jang.utils;

import jang.runtime.Interpreter.JangValue;
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
		printWithSpaces('Start: ${e.posStart}', spaces + 4);
		printWithSpaces('End: ${e.posEnd}', spaces + 4);
		printWithSpaces('Line: ${e.line}', spaces + 4);
		switch (e.expr) {
			case Try(body, catchContent):
				printWithSpaces('Type: Try Statement', spaces + 4);
				for (expr in body)
					printExpr(expr, spaces + 8);
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
				printWithSpaces('Type: Block', spaces + 4);
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
				printWithSpaces('type: ${TypeUtils.getTypeName(type)}', spaces + 4);
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
			case For(v, iterator, body):
				printWithSpaces('Type: For Loop', spaces + 4);
				printWithSpaces('Variables: $v', spaces + 4);
				printWithSpaces('Iterator:', spaces + 4);
				printExpr(iterator, spaces + 8);
				if (body.length > 0) {
					printWithSpaces('Body: ', spaces + 4);
					for (expr in body) {
						printExpr(expr, spaces + 8);
					}
				}
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
					case Throw(e):
						printWithSpaces('Type: Throw', spaces + 4);
						printWithSpaces('Expression:', spaces + 4);
						printExpr(e, spaces + 8);
				}
			case Function(body, args, type, name):
				printWithSpaces('Type: Function', spaces + 4);
				if (name != null) {
					printWithSpaces('Name: $name', spaces + 4);
				}
				printWithSpaces('Function Type: ${TypeUtils.getTypeName(type)}', spaces + 4);
				if (args.length > 0) {
					printWithSpaces('Arguments:', spaces + 4);
					for (arg in args)
						printWithSpaces('Argument ${arg.name}, Type: ${TypeUtils.getTypeName(arg.type)}', spaces + 8);
				}
				if (body.length > 0) {
					printWithSpaces('Body:', spaces + 4);
					for (expr in body)
						printExpr(expr, spaces + 8);
				}

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
			case Class(c):
				printWithSpaces('Type: Class', spaces + 4);
				printWithSpaces('Variables:', spaces + 4);
				for (v in c.variables) {
					printWithSpaces('Name: ${v.name}', spaces + 8);
					printWithSpaces('Behaviour: ${v.behaviour}', spaces + 8);
					printWithSpaces('Constant: ${v.constant}', spaces + 8);
					printWithSpaces('Type: ${TypeUtils.getTypeName(v.type)}', spaces + 8);
					printWithSpaces('Value:', spaces + 8);
					if (v.value != null) {
						printExpr(v.value, spaces + 12);
					}
				}
				printWithSpaces('Functions:', spaces + 4);
				for (f in c.functions) {
					printWithSpaces('Name: ${f.name}', spaces + 8);
					printWithSpaces('Behaviour: ${f.behaviour}', spaces + 8);
					printWithSpaces('Type: ${f.type}', spaces + 8);
					if (f.args.length > 0) {
						printWithSpaces('Args:', spaces + 8);
						for (a in f.args) {
							printWithSpaces('Name: ${a.name}', spaces + 12);
							printWithSpaces('Type: ${TypeUtils.getTypeName(a.type)}', spaces + 12);
						}
					}
					if (f.body.length > 0) {
						printWithSpaces('Body:', spaces + 8);
						for (e in f.body) {
							printExpr(e, spaces + 12);
						}
					}
				}
			case Import(path, targets):
				printWithSpaces('Type: Import', spaces + 4);
				printWithSpaces('Path: $path', spaces + 4);
				if (targets.length > 0) {
					printWithSpaces('Targets:', spaces + 4);
					for (target in targets) {
						printWithSpaces('$target', spaces + 8);
					}
				}
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
