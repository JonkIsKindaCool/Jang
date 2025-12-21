package jang.std;

import jang.utils.TypeUtils;
import jang.runtime.Interpreter.JangValue;

using StringTools;

class StringClass extends JangClass<StringInstance> {
	public function new() {
		super("String");
	}

	override function createInstance(args:Array<JangValue>):StringInstance {
		if (args.length == 0)
			return new StringInstance("");
		if (args.length > 1)
			throw "Too many parameters";

		return new StringInstance(Std.string(TypeUtils.jangToHaxe(args[0])));
	}
}

class StringInstance extends JangInstance {
	public var value:String;

	public function new(value:String) {
		super("String");
		this.value = value;
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "length":
				return VInt(value.length);

			case "value":
				return VString(value);

			case "toString":
				return VHaxeFunction(_ -> VString(value));

			case "isEmpty":
				return VHaxeFunction(_ -> VBoolean(value.length == 0));

			case "equals":
				return VHaxeFunction(args -> {
					return VBoolean(TypeUtils.equals(VString(value), args[0]));
				});

			case "charAt":
				return VHaxeFunction(args -> {
					var i = TypeUtils.expectInt(args[0]);
					if (i < 0 || i >= value.length)
						return VString("");
					return VString(value.charAt(i));
				});

			case "substring":
				return VHaxeFunction(args -> {
					var start = TypeUtils.expectInt(args[0]);
					var end = args.length > 1 ? TypeUtils.expectInt(args[1]) : value.length;
					return VString(value.substring(start, end));
				});

			case "slice":
				return VHaxeFunction(args -> {
					var start = TypeUtils.expectInt(args[0]);
					var end = args.length > 1 ? TypeUtils.expectInt(args[1]) : value.length;
					return VString(value.substr(start, end - start));
				});

			case "toUpper":
				return VHaxeFunction(_ -> VString(value.toUpperCase()));

			case "toLower":
				return VHaxeFunction(_ -> VString(value.toLowerCase()));

			case "trim":
				return VHaxeFunction(_ -> VString(value.trim()));

			case "repeat":
				return VHaxeFunction(args -> {
					var n = TypeUtils.expectInt(args[0]);
					var out = "";
					for (_ in 0...n)
						out += value;
					return VString(out);
				});

			case "reverse":
				return VHaxeFunction(_ -> {
					var val:Array<String> = value.split("");
					val.reverse();

					return VString(val.join(""));
				});


			case "contains":
				return VHaxeFunction(args -> VBoolean(value.indexOf(TypeUtils.expectString(args[0])) != -1));

			case "startsWith":
				return VHaxeFunction(args -> VBoolean(value.startsWith(TypeUtils.expectString(args[0]))));

			case "endsWith":
				return VHaxeFunction(args -> VBoolean(value.endsWith(TypeUtils.expectString(args[0]))));

			case "indexOf":
				return VHaxeFunction(args -> VInt(value.indexOf(TypeUtils.expectString(args[0]))));

			case "lastIndexOf":
				return VHaxeFunction(args -> VInt(value.lastIndexOf(TypeUtils.expectString(args[0]))));


			case "split":
				return VHaxeFunction(args -> {
					var d = TypeUtils.expectString(args[0]);
					return TypeUtils.haxeToJang(value.split(d).map(s -> VString(s)));
				});

			case "replace":
				return VHaxeFunction(args -> VString(StringTools.replace(value, TypeUtils.expectString(args[0]), TypeUtils.expectString(args[1]))));


			case "toInt":
				return VHaxeFunction(_ -> {
					var v = Std.parseInt(value);
					return v == null ? VNull : VInt(v);
				});

			case "toFloat":
				return VHaxeFunction(_ -> {
					var v = Std.parseFloat(value);
					return Math.isNaN(v) ? VNull : VFloat(v);
				});

			case "toBool":
				return VHaxeFunction(_ -> VBoolean(value == "true"));
		}

		return super.getVariable(name);
	}
}
