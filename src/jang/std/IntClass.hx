package jang.std;

import jang.runtime.Interpreter.JangValue;

class IntClass extends JangClass<IntInstance> {
	public function new() {
		super("Int");
	}

	override function createInstance(args:Array<JangValue>):IntInstance {
		if (args.length > 1)
			throw 'Too many parameters';

		var arg:Int = switch (args[0]) {
			case VString(s):
				Std.parseInt(s);
			case VInt(i):
				i;
			case VFloat(f):
				Std.int(f);
			case VBoolean(b):
				b ? 1 : 0;
			default:
				throw 'Expected string, int, float, boolean';
		}

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
			case "toBool":
				return VHaxeFunction(_ -> {
					VBoolean(value == 1);
				});
		}

		return super.getVariable(name);
	}
}
