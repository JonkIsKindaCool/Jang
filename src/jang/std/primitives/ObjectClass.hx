package jang.std.primitives;

import jang.runtime.Interpreter.JangValue;
import jang.utils.TypeUtils;
import jang.errors.JangError;

class ObjectClass extends JangClass<ObjectInstance> {
	public function new() {
		super("Object");
	}

	override function createInstance(args:Array<JangValue>):ObjectInstance {
		if (args.length == 0)
			return new ObjectInstance(new Map());

		if (args.length == 1 && TypeUtils.checkType(args[0], TObject)) {
			return new ObjectInstance(args[0].getParameters()[0]);
		}

		throw "Invalid arguments for Object constructor";
	}
}

class ObjectInstance extends JangInstance {
	public var fields:Map<String, JangValue>;

	public function new(?initial:Map<String, JangValue>) {
		super("Object");
		fields = initial != null ? initial : new Map();
	}

	override function setVariable(name:String, value:JangValue) {
		fields.set(name, value);
		super.setVariable(name, value);
	}

	override function getVariable(name:String):JangValue {
		if (fields.exists(name))
			return fields.get(name);

		switch (name) {

			case "toString":
				return VHaxeFunction(_ -> {
					var parts:Array<String> = [];
					for (k => v in fields)
						parts.push(k + ": " + Std.string(TypeUtils.jangToHaxe(v)));
					return VString("{ " + parts.join(", ") + " }");
				});


			case "get":
				return VHaxeFunction(args -> {
					var k:String = TypeUtils.expectString(args[0]);
					return fields.exists(k) ? fields.get(k) : VNull;
				});

			case "set":
				return VHaxeFunction(args -> {
					var k:String = TypeUtils.expectString(args[0]);
					fields.set(k, args[1]);
					return VNull;
				});

			case "has":
				return VHaxeFunction(args -> VBoolean(fields.exists(TypeUtils.expectString(args[0]))));

			case "keys":
				return VHaxeFunction(_ -> TypeUtils.haxeToJang([for (k in fields.keys()) VString(k)]));

			case "values":
				return VHaxeFunction(_ -> TypeUtils.haxeToJang([for (v in fields) v]));

			case "size":
				return VHaxeFunction(_ -> VInt(Lambda.count(fields)));

			case "clear":
				return VHaxeFunction(_ -> {
					fields.clear();
					return VNull;
				});

			case "clone":
				return VHaxeFunction(_ -> VObject(fields.copy()));
		}

		return super.getVariable(name);
	}
}
