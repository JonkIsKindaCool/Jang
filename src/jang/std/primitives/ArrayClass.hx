package jang.std.primitives;

import jang.utils.TypeUtils;
import jang.runtime.Interpreter.JangValue;
import jang.structures.Expr.Type;

class ArrayClass extends JangClass<ArrayInstance> {
	public function new() {
		super("Array");
	}

	override function createInstance(args:Array<JangValue>):ArrayInstance {
		if (args.length == 0)
			return new ArrayInstance([]);

		if (args.length == 1 && TypeUtils.checkType(args[0], TArray)) {
			var v:Array<JangValue> = args[0].getParameters()[0];
			return new ArrayInstance(v.copy());
		}

		throw "Expected array";
	}
}

class ArrayInstance extends JangInstance {
	var arr:Array<JangValue>;
	var _counter:Int = 0;

	public function new(v:Array<JangValue>) {
		super("Array");
		arr = v;
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "__index_access__":
				return VHaxeFunction(args -> {
					var i = TypeUtils.expectInt(args[0]);
					if (i < 0 || i >= arr.length)
						return VNull;
					return arr[i];
				});

			case "__hasNext__":
				return VHaxeFunction(args -> {
					var boolean:Bool = false;

					if (_counter < arr.length) {
						boolean = true;
					} else {
						_counter = 0;
						boolean = false;
					}
					return VBoolean(boolean);
				});

			case "__next__":
				return VHaxeFunction(args -> {
					var v:JangValue = arr[_counter];
					_counter++;
					return VArray([v]);
				});

			case "__index_setter__":
				return VHaxeFunction(args -> {
					var i = TypeUtils.expectInt(args[0]);
					arr[i] = args[1];
					return VNull;
				});

			case "length":
				return VInt(arr.length);

			case "toString":
				return VHaxeFunction(_ -> {
					var parts = [for (v in arr) Std.string(TypeUtils.jangToHaxe(v))];
					return VString("[" + parts.join(", ") + "]");
				});

			case "join":
				return VHaxeFunction(args -> {
					var sep = args.length > 0 ? TypeUtils.expectString(args[0]) : ",";
					var parts = [for (v in arr) Std.string(TypeUtils.jangToHaxe(v))];
					return VString(parts.join(sep));
				});

			case "push":
				return VHaxeFunction(args -> {
					arr.push(args[0]);
					return VInt(arr.length);
				});

			case "pop":
				return VHaxeFunction(_ -> {
					return arr.length == 0 ? VNull : arr.pop();
				});

			case "clear":
				return VHaxeFunction(_ -> {
					arr.resize(0);
					return VNull;
				});

			case "isEmpty":
				return VHaxeFunction(_ -> VBoolean(arr.length == 0));

			case "contains":
				return VHaxeFunction(args -> {
					for (v in arr)
						if (TypeUtils.equals(v, args[0]))
							return VBoolean(true);
					return VBoolean(false);
				});

			case "indexOf":
				return VHaxeFunction(args -> {
					for (i in 0...arr.length)
						if (TypeUtils.equals(arr[i], args[0]))
							return VInt(i);
					return VInt(-1);
				});

			case "clone":
				return VHaxeFunction(_ -> VArray(arr.copy()));
		}

		return super.getVariable(name);
	}
}
