package jang.std.primitives;

import jang.runtime.Interpreter.JangValue;
import jang.utils.TypeUtils;

class IntClass extends JangClass<IntInstance> {
	public function new() {
		super("Int");
	}

	override function createInstance(args:Array<JangValue>):IntInstance {
		if (args.length == 0)
			return new IntInstance(0);
		if (args.length > 1)
			throw "Too many parameters";

		var v = args[0];

		var arg:Int = switch (v) {
			case VInt(i): i;
			case VFloat(f): Std.int(f);
			case VString(s):
				var p = Std.parseInt(s);
				if (p == null) throw "Invalid int string";
				p;
			case VBoolean(b): b ? 1 : 0;
			default:
				throw 'Expected string, int, float or bool';
		};

		return new IntInstance(arg);
	}
}

class IntInstance extends JangInstance {
	public var value:Int;

	public function new(value:Int) {
		super("Int");
		this.value = value;
	}

	override function getVariable(name:String):JangValue {
		switch (name) {

			case "value":
				return VInt(value);

			case "toString":
				return VHaxeFunction(_ ->
					VString(Std.string(value))
				);

			case "toBool":
				return VHaxeFunction(_ ->
					VBoolean(value != 0)
				);

			case "toFloat":
				return VHaxeFunction(_ ->
					VFloat(value)
				);

			case "equals":
				return VHaxeFunction(args ->
					VBoolean(
						args[0].getParameters()[0] == value
					)
				);


			case "abs":
				return VHaxeFunction(_ ->
					VInt(value < 0 ? -value : value)
				);

			case "negate":
				return VHaxeFunction(_ ->
					VInt(-value)
				);

			case "isZero":
				return VHaxeFunction(_ ->
					VBoolean(value == 0)
				);

			case "isPositive":
				return VHaxeFunction(_ ->
					VBoolean(value > 0)
				);

			case "isNegative":
				return VHaxeFunction(_ ->
					VBoolean(value < 0)
				);
		}

		return super.getVariable(name);
	}
}
