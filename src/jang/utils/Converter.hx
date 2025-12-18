package jang.utils;

import jang.runtime.Interpreter.JangValue;

class Converter {
	public static function jangToHaxe(v:JangValue):Dynamic {
		return switch (v) {
			case VString(s):
				s;
			case VInt(i):
				i;
			case VFloat(f):
				f;
			case VBoolean(b):
				b;
			case VNull:
				null;
			case VClass(c):
				c;
			case VInstance(i):
				i;
			case VFunction(f):
				f;
			case VHaxeFunction(f):
				f;
		}
	}

	public static function haxeToJang(v:Dynamic):JangValue {
		if (Std.isOfType(v, String)) {
			return VString(v);
		} else if (!Math.isNaN(Std.parseFloat(Std.string(v)))) {
			if (v == Math.floor(v)) {
				return VInt(v);
			} else {
				return VFloat(v);
			}
		} else if (Std.isOfType(v, Bool)) {
			return VBoolean(v);
		} else if (v == null) {
			return VNull;
		} else if (Reflect.isFunction(v)) {
			return VHaxeFunction(args -> {
				var hxArgs:Array<Dynamic> = [for (arg in args) jangToHaxe(arg)];

				if (hxArgs.length <= 0) {
					return haxeToJang(v());
				} else {
					return haxeToJang(Reflect.callMethod(null, v, hxArgs));
				}
			});
		}

		return VNull;
	}
}
