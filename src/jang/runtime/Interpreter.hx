package jang.runtime;

import jang.structures.JangFunction;
import jang.std.StringClass;
import jang.std.IntClass;
import jang.std.IO;
import jang.std.JangInstance;
import jang.runtime.Scope;
import jang.std.JangClass;
import jang.runtime.Scope.JangVariable;
import jang.structures.Expr;
import haxe.ds.StringMap;

using StringTools;

class Interpreter {
	public static var OPERATORS:Map<String, (JangValue, JangValue) -> JangValue> = [
		"+" => (l:JangValue, r:JangValue) -> {
			var lv:Dynamic = unwrapAny(l);
			var rv:Dynamic = unwrapAny(r);
			var isString:Bool = (Std.isOfType(lv, String) || Std.isOfType(rv, String));
			var isFloat:Bool = (!isString && (lv != Std.int(lv) || rv != Std.int(rv)));
			if (isString)
				return VString((lv : String) + (rv : String));
			var result:Float = (lv : Float) + (rv : Float);
			return isFloat ? VFloat(result) : VInt(Std.int(result));
		},
		"-" => (l:JangValue, r:JangValue) -> {
			var error:String = "Operator '-' only supports int or float";
			var lv:Float = unwrapNum(l, error);
			var rv:Float = unwrapNum(r, error);
			var result:Float = lv - rv;
			return (Math.floor(result) == result) ? VInt(Std.int(result)) : VFloat(result);
		},
		"*" => (l:JangValue, r:JangValue) -> {
			var error:String = "Operator '*' only supports int or float";
			var lv:Float = unwrapNum(l, error);
			var rv:Float = unwrapNum(r, error);
			var result:Float = lv * rv;
			return (Math.floor(result) == result) ? VInt(Std.int(result)) : VFloat(result);
		},
		"/" => (l:JangValue, r:JangValue) -> {
			var error:String = "Operator '/' only supports int or float";
			var lv:Float = unwrapNum(l, error);
			var rv:Float = unwrapNum(r, error);
			if (rv == 0)
				throw "Division by zero";
			var result:Float = lv / rv;
			return (Math.floor(result) == result) ? VInt(Std.int(result)) : VFloat(result);
		},
		"%" => (l:JangValue, r:JangValue) -> {
			var error:String = "Operator '%' only supports int";
			var lv:Int = switch (l) {
					case VInt(i): i;
					default: throw error;
				}
			var rv:Int = switch (r) {
					case VInt(i): i;
					default: throw error;
				}
			var result:Int = lv % rv;
			return VInt(result);
		},
		"==" => (l:JangValue, r:JangValue) -> {
			var lv:Dynamic = unwrapAny(l);
			var rv:Dynamic = unwrapAny(r);
			return VBoolean(lv == rv);
		},
		"!=" => (l:JangValue, r:JangValue) -> {
			var lv:Dynamic = unwrapAny(l);
			var rv:Dynamic = unwrapAny(r);
			return VBoolean(lv != rv);
		},
		"<" => (l:JangValue, r:JangValue) -> {
			var lv:Float = unwrapNum(l, "Operator '<' only supports numbers");
			var rv:Float = unwrapNum(r, "Operator '<' only supports numbers");
			return VBoolean(lv < rv);
		},
		"<=" => (l:JangValue, r:JangValue) -> {
			var lv:Float = unwrapNum(l, "Operator '<=' only supports numbers");
			var rv:Float = unwrapNum(r, "Operator '<=' only supports numbers");
			return VBoolean(lv <= rv);
		},
		">" => (l:JangValue, r:JangValue) -> {
			var lv:Float = unwrapNum(l, "Operator '>' only supports numbers");
			var rv:Float = unwrapNum(r, "Operator '>' only supports numbers");
			return VBoolean(lv > rv);
		},
		">=" => (l:JangValue, r:JangValue) -> {
			var lv:Float = unwrapNum(l, "Operator '>=' only supports numbers");
			var rv:Float = unwrapNum(r, "Operator '>=' only supports numbers");
			return VBoolean(lv >= rv);
		}
	];

	public static var GLOBALS:Map<String, JangVariable> = [
		"IO" => {
			constant: true,
			value: VClass(new IO()),
			type: TCustom("IO")
		},
		"String" => {
			constant: true,
			value: VClass(new StringClass()),
			type: TCustom("String")
		},
		"Int" => {
			constant: true,
			value: VClass(new IntClass()),
			type: TCustom("Int")
		}
	];

	public var scope:Scope;

	public function new() {
		scope = new Scope();
		scope.variables = GLOBALS;
	}

	public function execute(e:Expr):JangValue {
		scope = new Scope();
		scope.variables = GLOBALS.copy();

		return executeExpr(e, scope);
	}

	public function executeExpr(e:Expr, scope:Scope):JangValue {
		switch (e) {
			case Ender(e):
				throw e;
			case Block(statements):
				var last:JangValue = VNull;

				for (expr in statements) {
					try {
						last = executeExpr(expr, scope);
					} catch (e:Ender) {
						switch (e) {
							case Return(e):
								last = executeExpr(e, scope);
								break;
							default:
						}
					}
				}

				return last;
			case StringLiteral(value):
				return VString(value);
			case NumberLiteral(value):
				if (Math.floor(value) != value)
					return VFloat(value);
				else
					return VInt(Math.floor(value));
			case BooleanLiteral(value):
				return VBoolean(value);
			case NullLiteral:
				return VNull;
			case BinaryOp(left, op, right):
				if (op.contains("=")) {
					if (left.match(Identifier(_))) {
						var name:String = left.getParameters()[0];
						var value:JangValue = VNull;
						if (op.length > 1) {
							value = executeExpr(BinaryOp(Identifier(name), op.split("=")[0], right), scope);
						} else {
							value = executeExpr(right, scope);
						}
						scope.assign(name, value);
						return value;
					}
				}
				return OPERATORS.get(op)(executeExpr(left, scope), executeExpr(right, scope));
			case Function(expr, args, type, name):
				var func:JangFunction = {
					body: expr,
					args: args,
					closure: scope,
					type: type
				};

				var value:JangValue = VFunction(func);

				if (name != null)
					scope.define(name, value, false, TFunction);

				return value;
			case Identifier(name):
				return scope.get(name);
			case Assignment(name, right, isConstant, type):
				scope.define(name, executeExpr(right, scope), isConstant, type);
				return VNull;
			case Call(f, args):
				var v:JangValue = executeExpr(f, scope);
				var args:Array<JangValue> = [for (expr in args) executeExpr(expr, scope)];

				switch (v) {
					case VHaxeFunction(f):
						return f(args);
					case VFunction(f):
						var local:Scope = new Scope(f.closure);
						var body:Array<Expr> = f.body;
						var type:Type = f.type;
						var arguments:Array<Argument> = f.args;

						if (args.length < arguments.length)
							throw 'Missing arguments';
						else if (args.length > arguments.length)
							throw 'idk';

						for (i => arg in arguments) {
							var val:JangValue = args[i];

							if (Scope.checkType(val, arg.type)) {
								local.define(arg.name, val, false, arg.type);
							} else {
								throw 'Expected $type, not ${val.getName()}';
							}
						}

						for (expr in body) {
							try {
								executeExpr(expr, local);
							} catch (e:Ender) {
								switch (e) {
									case Return(e):
										var value:JangValue = executeExpr(e, local);
										if (Scope.checkType(value, type)) {
											return value;
										} else {
											throw 'Expected $type, not ${value.getName()}';
										}
									default:
										throw 'Unexpected ender $e';
								}
							}
						}

						return VNull;
					default:
						throw 'You can only call functions';
				}
			case Field(p, f):
				var parent:JangValue = executeExpr(p, scope);
				if (parent.match(VClass(_))) {
					var c:JangClass<Dynamic> = parent.getParameters()[0];
					return c.getVariable(f);
				}
				var instance:JangInstance = switch (parent) {
					case VString(s):
						new StringInstance(s);
					case VInstance(i):
						i;
					case VInt(i):
						new IntInstance(i);
					default:
						null;
				}
				return instance.getVariable(f);
			case New(e, args):
				var c:JangValue = scope.get(e);

				switch (c) {
					case VClass(c):
						return VInstance(c.createInstance([for (arg in args) executeExpr(arg, scope)]));
					default:
						throw 'XD';
				}
			default:
				throw 'Unhandler expression $e';
		}
	}

	public inline static function unwrapNum(v:JangValue, error:String):Float {
		return switch (v) {
			case VInt(i): i;
			case VFloat(f): f;
			default: throw error;
		}
	}

	public inline static function unwrapAny(v:JangValue):Dynamic {
		return switch (v) {
			case VString(s): s;
			case VInt(i): i;
			case VFloat(f): f;
			case VBoolean(b): b;
			case VNull: null;
			case VInstance(i): i;
			case VClass(c): c;
			case VFunction(f): f;
			case VHaxeFunction(f): f;
		}
	}
}

enum JangValue {
	VString(s:String);
	VInt(i:Int);
	VFloat(f:Float);
	VBoolean(b:Bool);
	VNull;
	VClass(c:JangClass<Dynamic>);
	VInstance(i:JangInstance);
	VFunction(f:JangFunction);
	VHaxeFunction(f:(args:Array<JangValue>) -> JangValue);
}
