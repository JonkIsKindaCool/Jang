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
	var _counter:Int = 0;

	public var fields:Map<String, JangValue>;
	public var len:Int;

	public function new(?initial:Map<String, JangValue>) {
		super("Object");
		fields = initial != null ? initial : new Map();
		len = Lambda.count(fields);
	}

	override function setVariable(name:String, value:JangValue) {
		fields.set(name, value);
		len = Lambda.count(fields);
		super.setVariable(name, value);
	}

	override function getVariable(name:String):JangValue {
		if (fields.exists(name))
			return fields.get(name);

		switch (name) {
			case "__hasNext__":
				return VHaxeFunction(args -> {
					var boolean:Bool = false;

					if (_counter < len) {
						boolean = true;
					} else {
						_counter = 0;
						boolean = false;
					}
					return VBoolean(boolean);
				});

			case "__next__":
				return VHaxeFunction(args -> {
					var n:String = null;
					var v:JangValue = null;
					var c:Int = 0;
					for (k => val in fields) {
						if (_counter == c) {
							n = k;
							v = val;
							break;
						} else {
							c++;
						}
					}

					_counter++;
					return VArray([VString(n), v]);
				});

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
				return VHaxeFunction(_ -> VInt(len));

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
