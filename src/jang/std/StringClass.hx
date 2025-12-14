package jang.std;

import jang.runtime.Interpreter.JangValue;

class StringClass extends JangClass<StringInstance> {
	public function new() {
		super("String");
	}

    override function createInstance(args:Array<JangValue>):StringInstance {
        if (args.length > 1) throw 'Too many parameters';

		var arg:String = switch (args[0]){
			case VString(s):
				s;
			case VInt(i):
				Std.string(i);
			case VFloat(f):
				Std.string(f);
			case VBoolean(b):
				Std.string(b);
			case VNull:
				'null';
			case VClass(c):
				c.toString();
			case VInstance(i):
				i.name;
			case VFunction(expr, args):
				'function';
			case VHaxeFunction(f):
				'native function';
		}

        return new StringInstance(arg);
    }

	override function getVariable(name:String):JangValue {
		return super.getVariable(name);
	}

	override function setVariable(name:String, value:JangValue) {
		super.setVariable(name, value);
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
			case "value":
				return VString(value);
			case "split":
				return VHaxeFunction(args -> {
					var delimeter:String = "";

					switch (args[0]) {
						case VString(s):
							delimeter = s;
						default:
							throw 'Expected String, not ${args[0]}';
					}

					return VString(value.split(delimeter).join("\n"));
				});
			case "lenght":
				return VInt(value.length);
		}

		return super.getVariable(name);
	}
}
