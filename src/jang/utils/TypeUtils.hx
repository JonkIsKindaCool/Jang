package jang.utils;

import haxe.DynamicAccess;
import jang.runtime.Interpreter.JangValue;
import jang.structures.Expr.Type;
import jang.std.JangInstance;
import jang.std.primitives.StringClass;
import jang.std.primitives.IntClass;
import jang.std.primitives.ArrayClass;
import jang.std.primitives.ObjectClass;

class TypeUtils {
	public static function jangToHaxe(v:JangValue):Dynamic {
		return switch (v) {
			case VString(s): s;
			case VInt(i): i;
			case VFloat(f): f;
			case VBoolean(b): b;
			case VNull: null;

			case VArray(arr):
				[for (x in arr) jangToHaxe(x)];

			case VObject(fields):
				var obj:DynamicAccess<Dynamic> = {};
				for (k => v in fields)
					obj[k] = jangToHaxe(v);
				obj;

			case VInstance(i): i;
			case VClass(c): c;
			case VFunction(f): f;
			case VHaxeFunction(f): f;
		}
	}

	public static function haxeToJang(v:Dynamic):JangValue {
		if (v == null)
			return VNull;

		if (Std.isOfType(v, JangValue))
			return v;
		if (Std.isOfType(v, JangInstance))
			return VInstance(v);

		if (Std.isOfType(v, String))
			return VString(v);
		if (Std.isOfType(v, Bool))
			return VBoolean(v);
		if (Std.isOfType(v, Int))
			return VInt(v);
		if (Std.isOfType(v, Float))
			return VFloat(v);

		if (Std.isOfType(v, Array)) {
			var arr:Array<Dynamic> = v;
			return VArray([for (va in arr) haxeToJang(va)]);
		}

		if (Reflect.isFunction(v)) {
			return VHaxeFunction(args -> {
				var hxArgs = [for (a in args) jangToHaxe(a)];
				return haxeToJang(Reflect.callMethod(null, v, hxArgs));
			});
		}

		return VNull;
	}

	public static function checkType(v:JangValue, expected:Type):Bool {
		if (expected == TAny)
			return true;

		return switch ([v, expected]) {
			case [VInt(_), TInt]:
				true;

			case [VFloat(_), TFloat]:
				true;

			case [VInt(_), TFloat]:
				true;

			case [VFloat(_), TInt]:
				true;

			case [VString(_), TString]:
				true;

			case [VBoolean(_), TBool]:
				true;

			case [VNull, TObject]:
				true;

			case [VNull, TArray]:
				true;

			case [VNull, TCustom(_)]:
				true;

			case [VArray(_), TArray]:
				true;

			case [VObject(_), TObject]:
				true;

			case [VFunction(_), TFunction]:
				true;

			case [VHaxeFunction(_), TFunction]:
				true;

			case [VClass(c), TCustom(name)]:
				c.name == name;

			case [VInstance(i), TCustom(name)]: i.name == name;

			default:
				false;
		}
	}
	public static function expectString(v:JangValue):String {
		return switch (v) {
			case VString(s): s;
			default: error("string", v);
		}
	}

	public static function expectInt(v:JangValue):Int {
		return switch (v) {
			case VInt(i): i;
			case VFloat(f): Std.int(f);
			default: error("int", v);
		}
	}

	public static function expectFloat(v:JangValue):Float {
		return switch (v) {
			case VFloat(f): f;
			case VInt(i): i;
			default: error("float", v);
		}
	}

	public static function expectBool(v:JangValue):Bool {
		return switch (v) {
			case VBoolean(b): b;
			default: error("bool", v);
		}
	}

	public static function expectArray(v:JangValue):Array<JangValue> {
		return switch (v) {
			case VArray(a): a;
			default: error("array", v);
		}
	}

	public static function expectObject(v:JangValue):Map<String, JangValue> {
		return switch (v) {
			case VObject(o): o;
			default: error("object", v);
		}
	}

	public static function expectInstance(v:JangValue):JangInstance {
		return switch (v) {
			case VInstance(i): i;
			default: error("instance", v);
		}
	}

	public static function isTruthy(v:JangValue):Bool {
		return switch (v) {
			case VNull: false;
			case VBoolean(b): b;
			case VInt(i): i != 0;
			case VFloat(f): f != 0;
			case VString(s): s.length > 0;
			case VArray(a): a.length > 0;
			case VObject(o): o.keys().hasNext();
			default: true;
		}
	}

	public static function equals(a:JangValue, b:JangValue):Bool {
		if (a.getIndex() != b.getIndex())
			return false;

		return switch ([a, b]) {
			case [VString(x), VString(y)]: x == y;
			case [VInt(x), VInt(y)]: x == y;
			case [VFloat(x), VFloat(y)]: x == y;
			case [VBoolean(x), VBoolean(y)]: x == y;
			case [VNull, VNull]: true;
			case [VInstance(x), VInstance(y)]: x == y;
			default: false;
		}
	}

	public static function primitiveToInstance(v:JangValue):JangInstance {
		return switch (v) {
			case VString(s): new StringInstance(s);
			case VInt(i): new IntInstance(i);
			case VArray(a): new ArrayInstance(a);
			case VObject(o): new ObjectInstance(o);
			case VInstance(i): i;
			default: null;
		}
	}

	static function error(expected:String, got:JangValue):Dynamic {
		throw 'Expected $expected, got ${getValueName(got)}';
	}

	public static function getTypeName(t:Type):String {
		return switch (t) {
			case TInt:
				'int';
			case TFloat:
				'float';
			case TFunction:
				'callable';
			case TArray:
				'array';
			case TObject:
				'object';
			case TBool:
				'boolean';
			case TAny:
				'any';
			case TString:
				'string';
			case TCustom(c):
				c;
		}
	}

	public static function getValueName(v:JangValue):String {
		return switch (v) {
			case VString(s):
				'string';
			case VInt(i):
				'int';
			case VFloat(f):
				'float';
			case VBoolean(b):
				'boolean';
			case VNull:
				'null';
			case VObject(obj):
				'object';
			case VArray(arr):
				'array';
			case VClass(c):
				c.name;
			case VInstance(i):
				i.name;
			case VFunction(f):
				'callable';
			case VHaxeFunction(f):
				'callable';
		}
	}
}
