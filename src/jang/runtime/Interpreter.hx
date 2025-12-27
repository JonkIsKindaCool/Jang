package jang.runtime;

import haxe.Exception;
import jang.Jang.JangImportVariable;
import jang.Jang.JangOutput;
import jang.errors.JangError;
import jang.runtime.Scope;
import jang.runtime.custom.CustomClass;
import jang.std.JangClass;
import jang.std.JangInstance;
import jang.std.system.Math;
import jang.structures.Expr;
import jang.utils.TypeUtils;

using StringTools;

class Interpreter {
	public static var OPERATORS:Map<String, (JangValue, JangValue) -> JangValue> = [
		"+" => (l, r) -> {
			var lv = TypeUtils.jangToHaxe(l);
			var rv = TypeUtils.jangToHaxe(r);
			if (Std.isOfType(lv, String) || Std.isOfType(rv, String))
				return VString(Std.string(lv) + Std.string(rv));
			var a:Float = TypeUtils.expectFloat(l);
			var b:Float = TypeUtils.expectFloat(r);
			var res = a + b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"-" => (l, r) -> {
			var a:Float = TypeUtils.expectFloat(l);
			var b:Float = TypeUtils.expectFloat(r);
			var res = a - b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"*" => (l, r) -> {
			var a:Float = TypeUtils.expectFloat(l);
			var b:Float = TypeUtils.expectFloat(r);
			var res = a * b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"/" => (l, r) -> {
			var a:Float = TypeUtils.expectFloat(l);
			var b:Float = TypeUtils.expectFloat(r);
			if (b == 0)
				throw "Division by zero";
			var res = a / b;
			return (Math.floor(res) == res) ? VInt(Std.int(res)) : VFloat(res);
		},
		"%" => (l, r) -> {
			var a:Int = TypeUtils.expectInt(l);
			var b:Int = TypeUtils.expectInt(r);
			return VInt(a % b);
		},
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
			return VBoolean(!TypeUtils.expectBool(eq));
		},
		"<" => (l, r) -> VBoolean(TypeUtils.expectFloat(l) < TypeUtils.expectFloat(r)),
		"<=" => (l, r) -> VBoolean(TypeUtils.expectFloat(l) <= TypeUtils.expectFloat(r)),
		">" => (l, r) -> VBoolean(TypeUtils.expectFloat(l) > TypeUtils.expectFloat(r)),
		">=" => (l, r) -> VBoolean(TypeUtils.expectFloat(l) >= TypeUtils.expectFloat(r)),
		"&&" => (l, r) -> {
			var a:Bool = TypeUtils.expectBool(l);
			if (!a)
				return VBoolean(false);
			return VBoolean(TypeUtils.expectBool(r));
		},
		"||" => (l, r) -> {
			var a:Bool = TypeUtils.expectBool(l);
			if (a)
				return VBoolean(true);
			return VBoolean(TypeUtils.expectBool(r));
		}
	];

	public var scope:Scope;
	public var directory:String = null;
	public var fileName:String = "main.jn";
	public var source:String = "";

	public function new(directory:String = "", fileName:String = "main.jn") {
		scope = new Scope(this, Jang.GLOBALS);
		this.directory = directory;
		this.fileName = fileName;
	}

	public function execute(e:ExprInfo, ?src:String):JangValue {
		if (src != null)
			this.source = src;

		try {
			return executeExpr(e, scope);
		} catch (e:JangEnders) {
			switch (e) {
				case Return(e):
					return e;
				case Throw(e, info):
					new JangError(src, info.posStart, info.posEnd, info.line, Std.string(TypeUtils.jangToHaxe(e)), RUNTIME_ERROR, fileName);
					return VNull;
				default:
					throw 'Unexpected Ender $e';
			}
		}
	}

	public function executeExpr(e:ExprInfo, scope:Scope):JangValue {
		try {
			switch (e.expr) {
				case Ender(en):
					switch (en) {
						case Return(e):
							throw JangEnders.Return(executeExpr(e, scope));
						case Break:
							throw JangEnders.Break;
						case Continue:
							throw JangEnders.Continue;
						case Throw(v):
							throw JangEnders.Throw(executeExpr(v, scope), e);
					}
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
							var jv:JangValue = executeExpr(left.expr.getParameters()[0], scope);
							var name:String = left.expr.getParameters()[1];
							var value:JangValue = VNull;
							if (op != "=") {
								value = executeExpr(Parser.makeExprInfo(e.posStart, e.posEnd, e.line, BinaryOp(left, op.split("=")[0], right)), scope);
							} else {
								value = executeExpr(right, scope);
							}

							switch (jv) {
								case VHaxeObject(obj):
									Reflect.setProperty(obj, name, TypeUtils.jangToHaxe(value));
									return value;
								case VHaxeClass(c):
									Reflect.setProperty(c, name, TypeUtils.jangToHaxe(value));
									return value;
								default:
							}

							var parent:JangInstance = TypeUtils.primitiveToInstance(jv);

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
				case Import(path, targets):
					for (target in targets){
						var value:JangVariable = Jang.getImportVariable(path, target);
						scope.define(target, value.value, value.constant, value.type);
					}
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
								throw 'You can only call functions: ' + v;
						}
					} catch (callErr) {
						throw callErr;
					}
				case Field(p, f):
					var parent:JangValue = executeExpr(p, scope);

					switch (parent) {
						case VClass(c):
							return c.getVariable(f);
						case VHaxeClass(c):
							var value:Dynamic = Reflect.getProperty(c, f);

							if (Reflect.isFunction(value)) {
								return VHaxeFunction(args -> {
									var hxArgs = [for (a in args) TypeUtils.jangToHaxe(a)];
									return TypeUtils.haxeToJang(Reflect.callMethod(c, value, hxArgs));
								});
							}

							return TypeUtils.haxeToJang(value);
						case VHaxeObject(obj):
							var value:Dynamic = Reflect.getProperty(obj, f);

							if (Reflect.isFunction(value)) {
								return VHaxeFunction(args -> {
									var hxArgs = [for (a in args) TypeUtils.jangToHaxe(a)];
									return TypeUtils.haxeToJang(Reflect.callMethod(obj, value, hxArgs));
								});
							}

							return TypeUtils.haxeToJang(value);
						default:
							var instance:JangInstance = TypeUtils.primitiveToInstance(parent);
							if (instance == null)
								throw "Cannot access field on non-instance";
							return instance.getVariable(f);
					}
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
						} catch (err:JangEnders) {
							switch (err) {
								case Return(ret):
									return ret;

								case Break:
									break;

								case Continue:
									continue;
								default:
									throw err;
							}
						}
					}

					return VNull;

				case New(name, args):
					var cval:JangValue = scope.get(name);
					switch (cval) {
						case VHaxeClass(c):
							return VHaxeObject(std.Type.createInstance(c, [for (arg in args) TypeUtils.jangToHaxe(executeExpr(arg, scope))]));
						case VClass(clazz):
							return VInstance(clazz.createInstance([for (arg in args) executeExpr(arg, scope)]));
						default:
							throw 'Value is not a class/constructor';
					}
				case Class(c):
					var clazz:CustomClass = new CustomClass(c, this, c.name);
					var value:JangValue = VClass(clazz);

					scope.define(clazz.name, value, true, TCustom(clazz.name));
					return value;
				case Try(body, catchContent):
					var local:Scope = new Scope(this, scope);
					try {
						for (expr in body) {
							executeExpr(expr, local = new Scope(this, scope));
						}
					} catch (e:JangEnders) {
						switch (e) {
							case Return(e):
								return e;
							case Throw(e, info):
								if (catchContent == null) throw e; else {
									if (TypeUtils.checkType(e, catchContent.type)) {
										var catchLocal:Scope = new Scope(this, scope);
										catchLocal.define(catchContent.name, e, false, catchContent.type);

										for (expr in catchContent.body) {
											executeExpr(expr, catchLocal);
										}
										return VNull;
									} else {
										return VNull;
									}
								}
							default:
								throw e;
						}
					}
				case For(v, iterator, body):
					var it:JangInstance = TypeUtils.primitiveToInstance(executeExpr(iterator, scope));
					var hasNext:JangValue = it.getVariable('__hasNext__');
					var next:JangValue = it.getVariable('__next__');

					inline function callValueXD(v:JangValue, args):JangValue {
						switch (v){
							case VHaxeFunction(f):
								return f(args);
							case VFunction(f):
								return callFunction(f, args);
							default:
								return TypeUtils.error('function', v);
						}
					}

					while (TypeUtils.expectBool(callValueXD(hasNext, []))) {
						var local:Scope = new Scope(this, scope);
						var value:Array<JangValue> = TypeUtils.expectArray(callValueXD((next), []));
						for (i => n in v){
							local.define(n, value[i], false);
						}
						for (expr in body) {
							try {
								executeExpr(expr, local);
							} catch (ex) {
								throw ex;
							}
						}
					}

					return VNull;
				default:
					throw 'Unhandled expression: ' + Std.string(e.expr);
			}
		} catch (ender:JangEnders) {
			throw ender;
		} catch (err:Exception) {
			new JangError(this.source, if (e == null) 1 else e.posStart, if (e == null) 1 else e.posEnd, if (e == null) 1 else e.line, err.details(),
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
				throw 'Expected ' + TypeUtils.getTypeName(arg.type) + ', not ' + (val == null ? "null" : TypeUtils.getValueName(val));
			}
		}

		for (expr in body) {
			try {
				executeExpr(expr, local);
			} catch (e:JangEnders) {
				switch (e) {
					case Return(ret):
						if (TypeUtils.checkType(ret, type)) {
							return ret;
						} else {
							throw 'Expected ' + TypeUtils.getTypeName(type) + ', not ' + (ret == null ? "null" : TypeUtils.getValueName(ret));
						}
					case Throw(v, info):
						throw e;
					default:
						throw 'Unexpected ender ' + Std.string(e);
				}
			}
		}

		return VNull;
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
	VHaxeClass(c:Class<Dynamic>);
	VHaxeObject(obj:Dynamic);
}

enum JangEnders {
	Return(v:JangValue);
	Break;
	Continue;
	Throw(v:JangValue, info:ExprInfo);
}

typedef JangFunction = {
	body:Array<ExprInfo>,
	args:Array<Argument>,
	type:Type,
	closure:Scope
}
