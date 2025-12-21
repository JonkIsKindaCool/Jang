package jang.runtime;

import jang.std.primitives.ObjectClass;
import jang.utils.TypeUtils;
import jang.std.primitives.StringClass;
import jang.std.primitives.IntClass;
import jang.std.system.IO;
import jang.std.JangInstance;
import jang.runtime.Scope;
import jang.std.primitives.ArrayClass;
import jang.std.JangClass;
import jang.runtime.Scope.JangVariable;
import jang.structures.Expr;
import jang.errors.JangError;
import haxe.ds.StringMap;

using StringTools;

class Interpreter {
	public static var OPERATORS:Map<String, (JangValue, JangValue) -> JangValue> = [
		/* ===== ARITMÉTICOS ===== */
		"+" => (l, r) -> {
			var lv = TypeUtils.jangToHaxe(l);
			var rv = TypeUtils.jangToHaxe(r);
			// concatenación string
			if (Std.isOfType(lv, String) || Std.isOfType(rv, String))
				return VString(Std.string(lv) + Std.string(rv));
			var a = unwrapNum(l, "Operator '+' expects numbers");
			var b = unwrapNum(r, "Operator '+' expects numbers");
			var res = a + b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"-" => (l, r) -> {
			var a = unwrapNum(l, "Operator '-' expects numbers");
			var b = unwrapNum(r, "Operator '-' expects numbers");
			var res = a - b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"*" => (l, r) -> {
			var a = unwrapNum(l, "Operator '*' expects numbers");
			var b = unwrapNum(r, "Operator '*' expects numbers");
			var res = a * b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"/" => (l, r) -> {
			var a = unwrapNum(l, "Operator '/' expects numbers");
			var b = unwrapNum(r, "Operator '/' expects numbers");
			if (b == 0)
				throw "Division by zero";
			var res = a / b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"%" => (l, r) -> {
			var a = switch (l) {
					case VInt(i): i;
					default: throw "Operator '%' expects int";
				}
			var b = switch (r) {
					case VInt(i): i;
					default: throw "Operator '%' expects int";
				}
			return VInt(a % b);
		},
		/* ===== COMPARACIÓN ===== */
		"==" => (l, r) -> {
			return switch [l, r] {
				case [VNull, VNull]: VBoolean(true);
				case [VNull, _] | [_, VNull]: VBoolean(false);
				default:
					VBoolean(TypeUtils.jangToHaxe(l) == TypeUtils.jangToHaxe(r));
			}
		},
		"!=" => (l, r) -> {
			var eq = OPERATORS["=="](l, r);
			return VBoolean(!unwrapBool(eq, "Internal error"));
		},
		"<" => (l, r) -> VBoolean(unwrapNum(l, "< expects numbers") < unwrapNum(r, "< expects numbers")),
		"<=" => (l, r) -> VBoolean(unwrapNum(l, "<= expects numbers") <= unwrapNum(r, "<= expects numbers")),
		">" => (l, r) -> VBoolean(unwrapNum(l, "> expects numbers") > unwrapNum(r, "> expects numbers")),
		">=" => (l, r) -> VBoolean(unwrapNum(l, ">= expects numbers") >= unwrapNum(r, ">= expects numbers")),
		/* ===== LÓGICOS ===== */
		"&&" => (l, r) -> {
			var a = unwrapBool(l, "Operator '&&' expects boolean");
			if (!a)
				return VBoolean(false); // preparado para short-circuit real
			return VBoolean(unwrapBool(r, "Operator '&&' expects boolean"));
		},
		"||" => (l, r) -> {
			var a = unwrapBool(l, "Operator '||' expects boolean");
			if (a)
				return VBoolean(true);
			return VBoolean(unwrapBool(r, "Operator '||' expects boolean"));
		}
	];

	public static final GLOBALS:Map<String, JangVariable> = [
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
		},
		"Object" => {
			constant: true,
			value: VClass(new ObjectClass()),
			type: TCustom("Object")
		},
		"Array" => {
			constant: true,
			value: VClass(new ArrayClass()),
			type: TCustom("Array")
		},
		"print" => {
			constant: true,
			value: IO.instance.getVariable("println"),
			type: TFunction
		}
	];

	public var scope:Scope;
	public var source:String = "";

	public function new() {
		scope = new Scope(this);
		scope.variables = GLOBALS.copy();
	}

	public function execute(e:ExprInfo, ?src:String):JangValue {
		if (src != null)
			this.source = src;
		if (scope.variables != GLOBALS.copy()) {
			scope.variables = GLOBALS.copy();
		}

		try {
			return executeExpr(e, scope);
		} catch (e:Ender){
			switch (e){
				case Return(e):
					return executeExpr(e, scope);
				default:
					throw 'Unexpected Ender $e';
			}
		}
	}

	public function executeExpr(e:ExprInfo, scope:Scope):JangValue {
		try {
			switch (e.expr) {
				case Ender(en):
					throw en;
				case Block(statements):
					var last:JangValue = VNull;

					for (expr in statements) {
						try {
							last = executeExpr(expr, scope);
						} catch (ex) {
							throw ex;
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
					if (op == "=" || op == "+=" || op == "-=" || op == "*=" || op == "/=") {
						if (left.expr.match(Identifier(_))) {
							var name:String = left.expr.getParameters()[0];
							var value:JangValue = VNull;
							if (op != "=") {
								value = executeExpr(Parser.makeExprInfo(e.posStart, e.posEnd, e.line, BinaryOp(left, op.split("=")[0], right)), scope);
							} else {
								value = executeExpr(right, scope);
							}
							scope.assign(name, value);
							return value;
						} else if (left.expr.match(Field(_, _))) {
							var parent:JangInstance = TypeUtils.primitiveToInstance(executeExpr(left.expr.getParameters()[0], scope));
							var name:String = left.expr.getParameters()[1];
							var value:JangValue = VNull;
							if (op != "=") {
								value = executeExpr(Parser.makeExprInfo(e.posStart, e.posEnd, e.line, BinaryOp(left, op.split("=")[0], right)), scope);
							} else {
								value = executeExpr(right, scope);
							}
							parent.setVariable(name, value);

							return value;
						} else if (left.expr.match(Index(_, _))) {
							var parent:JangInstance = TypeUtils.primitiveToInstance(executeExpr(left.expr.getParameters()[0], scope));
							var index:JangValue = executeExpr(left.expr.getParameters()[1], scope);
							var value:JangValue = VNull;
							if (op != "=") {
								value = executeExpr(Parser.makeExprInfo(e.posStart, e.posEnd, e.line, BinaryOp(left, op.split("=")[0], right)), scope);
							} else {
								value = executeExpr(right, scope);
							}

							var f:JangValue = parent.getVariable('__index_setter__');

							switch (f) {
								case VFunction(f):
									callFunction(f, [index, value]);
								case VHaxeFunction(f):
									f([index, value]);
								default:
									throw 'Index setter (__index_setter__) doesnt exists';
							}

							return value;
						}
					}

					var lv = executeExpr(left, scope);
					var rv = executeExpr(right, scope);

					try {
						var opFunc = OPERATORS.get(op);
						if (opFunc == null)
							throw "Unknown operator: " + op;
						return opFunc(lv, rv);
					} catch (opErr) {
						throw opErr;
					}
				case Object(fields):
					var fMap:Map<String, JangValue> = new Map();
					for (field in fields) {
						fMap.set(field.name, executeExpr(field.value, scope));
					}
					return VObject(fMap);
				case Array(inner):
					var arr:Array<JangValue> = [for (v in inner) executeExpr(v, scope)];
					return VArray(arr);
				case Function(exprs, args, type, name):
					var func:JangFunction = {
						body: exprs,
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
					var argVals:Array<JangValue> = [for (expr in args) executeExpr(expr, scope)];

					try {
						switch (v) {
							case VHaxeFunction(fn):
								return fn(argVals);
							case VFunction(fn):
								return callFunction(fn, argVals);
							default:
								throw 'You can only call functions';
						}
					} catch (callErr) {
						throw callErr;
					}
				case Field(p, f):
					var parent:JangValue = executeExpr(p, scope);
					if (parent.match(VClass(_))) {
						var c:JangClass<Dynamic> = parent.getParameters()[0];
						return c.getVariable(f);
					}
					var instance:JangInstance = TypeUtils.primitiveToInstance(parent);
					if (instance == null)
						throw "Cannot access field on non-instance";
					return instance.getVariable(f);
				case Index(p, i):
					var parent:JangValue = executeExpr(p, scope);
					if (parent.match(VClass(_))) {
						throw "Index access not allowed in classes";
					}

					var instance:JangInstance = TypeUtils.primitiveToInstance(parent);
					if (instance == null)
						throw "Cannot use Index on non-instance";

					var f:JangValue = instance.getVariable('__index_access__');

					switch (f) {
						case VFunction(f):
							return callFunction(f, [executeExpr(i, scope)]);
						case VHaxeFunction(f):
							return f([executeExpr(i, scope)]);
						default:
							throw 'Index access (__index_access__) doesnt exists';
					}
				case Top(inner):
					return executeExpr(inner, scope);
				case If(cond, body, elsE):
					var condValue:JangValue = executeExpr(cond, scope);
					if (!condValue.match(VBoolean(_)))
						throw 'If statement condition should be a boolean';

					if (TypeUtils.jangToHaxe(condValue)) {
						var local:Scope = new Scope(this, scope);
						executeExpr(body, local);
					} else {
						if (elsE != null) {
							var local:Scope = new Scope(this, scope);
							executeExpr(elsE, local);
						}
					}
				case While(c, b):
					while (true) {
						var condValue:JangValue = executeExpr(c, scope);

						var cond:Bool = switch (condValue) {
							case VBoolean(b): b;
							default:
								throw "While condition must be boolean";
						}

						if (!cond)
							break;

						var local:Scope = new Scope(this, scope);

						try {
							for (expr in b) {
								executeExpr(expr, local);
							}
						} catch (err:Ender) {
							switch (err) {
								case Return(ret):
									return executeExpr(ret, local);

								case Break:
									break;

								case Continue:
									continue;
							}
						}
					}

					return VNull;

				case New(name, args):
					var cval:JangValue = scope.get(name);
					switch (cval) {
						case VClass(clazz):
							return VInstance(clazz.createInstance([for (arg in args) executeExpr(arg, scope)]));
						default:
							throw 'Value is not a class/constructor';
					}
				default:
					throw 'Unhandled expression: ' + Std.string(e.expr);
			}
		} catch (ender:Ender) {
			throw ender;
		} catch (err) {
			var msg:String = err.details();
			new JangError(this.source, if (e == null) 1 else e.posStart, if (e == null) 1 else e.posEnd, if (e == null) 1 else e.line, msg,
				JangErrorType.RUNTIME_ERROR, "main.jn", null);
		}

		return VNull;
	}

	public function callFunction(f:JangFunction, args:Array<JangValue>) {
		var local:Scope = new Scope(this, f.closure);
		var body:Array<ExprInfo> = f.body;
		var type:Type = f.type;
		var arguments:Array<Argument> = f.args;

		if (args.length < arguments.length)
			throw 'Missing arguments';
		else if (args.length > arguments.length)
			throw 'Too many arguments';

		for (i => arg in arguments) {
			var val:JangValue = args[i];

			if (TypeUtils.checkType(val, arg.type)) {
				local.define(arg.name, val, false, arg.type);
			} else {
				throw 'Expected ' + Std.string(arg.type) + ', not ' + (val == null ? "null" : val.getName());
			}
		}

		for (expr in body) {
			try {
				executeExpr(expr, local);
			} catch (e:Ender) {
				switch (e) {
					case Return(ret):
						var value:JangValue = executeExpr(ret, local);
						if (TypeUtils.checkType(value, type)) {
							return value;
						} else {
							throw 'Expected ' + Std.string(type) + ', not ' + (value == null ? "null" : value.getName());
						}
					default:
						throw 'Unexpected ender ' + Std.string(e);
				}
			}
		}

		return VNull;
	}

	public inline static function unwrapNum(v:JangValue, error:String):Float {
		return switch (v) {
			case VInt(i): i;
			case VFloat(f): f;
			default: throw error;
		}
	}

	static inline function unwrapBool(v:JangValue, err:String):Bool {
		return switch (v) {
			case VBoolean(b): b;
			default: throw err;
		}
	}
}

enum JangValue {
	VString(s:String);
	VInt(i:Int);
	VFloat(f:Float);
	VBoolean(b:Bool);
	VNull;
	VObject(obj:Map<String, JangValue>);
	VArray(arr:Array<JangValue>);
	VClass(c:JangClass<Dynamic>);
	VInstance(i:JangInstance);
	VFunction(f:JangFunction);
	VHaxeFunction(f:(args:Array<JangValue>) -> JangValue);
}

typedef JangFunction = {
	body:Array<ExprInfo>,
	args:Array<Argument>,
	type:Type,
	closure:Scope
}
