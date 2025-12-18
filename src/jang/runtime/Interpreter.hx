package jang.runtime;

import jang.utils.Converter;
import jang.structures.JangFunction;
import jang.std.StringClass;
import jang.std.IntClass;
import jang.std.IO;
import jang.std.JangInstance;
import jang.runtime.Scope;
import jang.std.JangClass;
import jang.runtime.Scope.JangVariable;
import jang.structures.Expr;
import jang.errors.JangError;
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

		return executeExpr(e, scope);
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
					if (op.contains("=")) {
						if (left.expr.match(Identifier(_))) {
							var name:String = left.expr.getParameters()[0];
							var value:JangValue = VNull;
							if (op.length > 1) {
								value = executeExpr(Parser.makeExprInfo(e.posStart, e.posEnd, e.line,
									BinaryOp(Parser.makeExprInfo(e.posStart, e.posStart + name.length, e.line, Identifier(name)), op.split("=")[0], right)),
									scope);
							} else {
								value = executeExpr(right, scope);
							}
							scope.assign(name, value);
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
					if (instance == null)
						throw "Cannot access field on non-instance";
					return instance.getVariable(f);
				case Top(inner):
					return executeExpr(inner, scope);
				case If(cond, body, elsE):
					var condValue:JangValue = executeExpr(cond, scope);
					if (!condValue.match(VBoolean(_)))
						throw 'If statement condition should be a boolean';

					if (Converter.jangToHaxe(condValue)) {
						var local:Scope = new Scope(this, scope);
						executeExpr(body, local);
					} else {
						if (elsE != null) {
							var local:Scope = new Scope(this, scope);
							executeExpr(elsE, local);
						}
					}
				case While(c, b):
					var shouldRun:Bool = true;
					var shouldAdvance:Bool = false;
					while (unwrapAny(executeExpr(c, scope)) && shouldRun) {
						var local:Scope = new Scope(this, scope);

						for (expr in b) {
							try {
								executeExpr(expr, local);
							} catch (innerErr:Ender) {
								switch (innerErr) {
									case Return(ret):
										var value:JangValue = executeExpr(ret, local);
										return value;
									case Break:
										shouldRun = false;
									case Continue:
										shouldAdvance = true;
										break;
								}
							}
						}

						if (shouldAdvance) {
							shouldAdvance = false;
							continue;
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
			var msg:String = Std.string(err);
			throw new JangError(this.source, if (e == null) 1 else e.posStart, if (e == null) 1 else e.posEnd, if (e == null) 1 else e.line, msg,
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

			if (Scope.checkType(val, arg.type)) {
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
						if (Scope.checkType(value, type)) {
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
