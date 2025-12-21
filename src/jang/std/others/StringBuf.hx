package jang.std.others;

import jang.utils.TypeUtils;
import jang.runtime.Interpreter.JangValue;
import jang.std.JangClass;
import jang.std.JangInstance;

using StringTools;

class StringBuffer extends JangClass<StringBufferInstance> {
	public function new() {
		super("StringBuffer");
	}

	override function createInstance(args:Array<JangValue>):StringBufferInstance {
		if (args.length > 0)
			throw "StringBuffer does not take constructor arguments";
		return new StringBufferInstance();
	}
}

class StringBufferInstance extends JangInstance {
	public var value:StringBuf;

	public function new() {
		super("StringBuffer");
		value = new StringBuf();
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "add":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "add expects 1 parameter";
					value.add(TypeUtils.expectString(args[0]));
					return VNull;
				});

			case "addAt", "insert":
				return VHaxeFunction(args -> {
					if (args.length != 2)
						throw "addAt expects 2 parameters";

					var str = TypeUtils.expectString(args[0]);
					var index = TypeUtils.expectInt(args[1]);

					var arr = value.toString().split("");
					if (index < 0 || index > arr.length)
						throw "Index out of bounds";

					arr.insert(index, str);

					value = new StringBuf();
					value.add(arr.join(""));
					return VNull;
				});

			case "clear":
				return VHaxeFunction(_ -> {
					value = new StringBuf();
					return VNull;
				});

			case "toString":
				return VHaxeFunction(_ -> {
					return VString(value.toString());
				});

			case "length":
				return VHaxeFunction(_ -> {
					return VInt(value.toString().length);
				});

			case "isEmpty":
				return VHaxeFunction(_ -> {
					return VBoolean(value.toString().length == 0);
				});

			case "charAt":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "charAt expects 1 parameter";

					var i = TypeUtils.expectInt(args[0]);
					var s = value.toString();

					if (i < 0 || i >= s.length)
						throw "Index out of bounds";

					return VString(s.charAt(i));
				});

			case "removeAt":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "removeAt expects 1 parameter";

					var i = TypeUtils.expectInt(args[0]);
					var arr = value.toString().split("");

					if (i < 0 || i >= arr.length)
						throw "Index out of bounds";

					arr.splice(i, 1);

					value = new StringBuf();
					value.add(arr.join(""));
					return VNull;
				});

			case "substring":
				return VHaxeFunction(args -> {
					if (args.length < 1 || args.length > 2)
						throw "substring expects 1 or 2 parameters";

					var s = value.toString();
					var start = TypeUtils.expectInt(args[0]);
					var end = args.length == 2 ? TypeUtils.expectInt(args[1]) : s.length;

					if (start < 0 || end < start || end > s.length)
						throw "Invalid range";

					return VString(s.substr(start, end - start));
				});

			case "appendLine":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "appendLine expects 1 parameter";

					value.add(TypeUtils.expectString(args[0]));
					value.add("\n");
					return VNull;
				});

			case "repeat":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "repeat expects 1 parameter";

					var n = TypeUtils.expectInt(args[0]);
					if (n < 0)
						throw "repeat expects positive integer";

					var s = value.toString();
					value = new StringBuf();

					for (_ in 0...n)
						value.add(s);

					return VNull;
				});

			case "equals":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "equals expects 1 parameter";

					var other = TypeUtils.expectString(args[0]);
					return VBoolean(value.toString() == other);
				});

			case "indexOf":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "indexOf expects 1 parameter";

					var needle = TypeUtils.expectString(args[0]);
					return VInt(value.toString().indexOf(needle));
				});

			case "startsWith":
				return VHaxeFunction(args -> {
					var s = TypeUtils.expectString(args[0]);
					return VBoolean(value.toString().startsWith(s));
				});

			case "endsWith":
				return VHaxeFunction(args -> {
					var s:String = TypeUtils.expectString(args[0]);
					return VBoolean(value.toString().endsWith(s));
				});

			case "trim":
				return VHaxeFunction(_ -> {
					var s:String = value.toString().trim();
					value = new StringBuf();
					value.add(s);
					return VNull;
				});
		}

		return super.getVariable(name);
	}
}
