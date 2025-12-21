package jang.utils;

import haxe.DynamicAccess;
import jang.runtime.Interpreter.JangValue;
import jang.structures.Expr.Type;
import jang.std.JangInstance;
import jang.std.StringClass.StringInstance;
import jang.std.IntClass.IntInstance;
import jang.std.ArrayClass.ArrayInstance;
import jang.std.ObjectClass.ObjectInstance;

class TypeUtils {

	/* =========================================================
		JANG -> HAXE
	   ========================================================= */

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
				for (k => v in fields) obj[k] = jangToHaxe(v);
				obj;

			case VInstance(i): i;
			case VClass(c): c;
			case VFunction(f): f;
			case VHaxeFunction(f): f;
		}
	}

	/* =========================================================
		HAXE -> JANG
	   ========================================================= */

	public static function haxeToJang(v:Dynamic):JangValue {
		if (v == null) return VNull;

		if (Std.isOfType(v, JangValue)) return v;
		if (Std.isOfType(v, JangInstance)) return VInstance(v);

		if (Std.isOfType(v, String)) return VString(v);
		if (Std.isOfType(v, Bool)) return VBoolean(v);
		if (Std.isOfType(v, Int)) return VInt(v);
		if (Std.isOfType(v, Float)) return VFloat(v);

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

	/* =========================================================
		TYPE CHECKING
	   ========================================================= */

	public static function checkType(v:JangValue, t:Type):Bool {
		if (t.equals(TAny)) return true;

		return switch (v) {
			case VString(_): t.equals(TString);
			case VInt(_): t.equals(TInt);
			case VFloat(_): t.equals(TFloat) || t.equals(TInt);
			case VBoolean(_): t.equals(TBool);
			case VArray(_): t.equals(TArray);
			case VObject(_): t.equals(TObject);
			case VFunction(_) | VHaxeFunction(_): t.equals(TFunction);

			case VInstance(i):
				t.match(TCustom(_)) && i.name == t.getParameters()[0];

			default:
				false;
		}
	}

	/* =========================================================
		EXPECT HELPERS (OBLIGATORIOS)
	   ========================================================= */

	public static function expectString(v:JangValue):String {
		return switch (v) {
			case VString(s): s;
			default: error("String", v);
		}
	}

	public static function expectInt(v:JangValue):Int {
		return switch (v) {
			case VInt(i): i;
			case VFloat(f): Std.int(f);
			default: error("Int", v);
		}
	}

	public static function expectFloat(v:JangValue):Float {
		return switch (v) {
			case VFloat(f): f;
			case VInt(i): i;
			default: error("Float", v);
		}
	}

	public static function expectBool(v:JangValue):Bool {
		return switch (v) {
			case VBoolean(b): b;
			default: error("Bool", v);
		}
	}

	public static function expectArray(v:JangValue):Array<JangValue> {
		return switch (v) {
			case VArray(a): a;
			default: error("Array", v);
		}
	}

	public static function expectObject(v:JangValue):Map<String, JangValue> {
		return switch (v) {
			case VObject(o): o;
			default: error("Object", v);
		}
	}

	public static function expectInstance(v:JangValue):JangInstance {
		return switch (v) {
			case VInstance(i): i;
			default: error("Instance", v);
		}
	}

	/* =========================================================
		TRUTHINESS (IF / WHILE / && / ||)
	   ========================================================= */

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

	/* =========================================================
		EQUALITY (==)
	   ========================================================= */

	public static function equals(a:JangValue, b:JangValue):Bool {
		if (a.getIndex() != b.getIndex()) return false;

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

	/* =========================================================
		BOXING / UNBOXING
	   ========================================================= */

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

	/* =========================================================
		UTILIDADES
	   ========================================================= */

	public static function typeName(v:JangValue):String {
		return switch (v) {
			case VString(_): "String";
			case VInt(_): "Int";
			case VFloat(_): "Float";
			case VBoolean(_): "Bool";
			case VArray(_): "Array";
			case VObject(_): "Object";
			case VInstance(i): i.name;
			case VNull: "Null";
			default: "Unknown";
		}
	}

	static function error(expected:String, got:JangValue):Dynamic {
		throw 'Expected $expected, got ${typeName(got)}';
	}
}
