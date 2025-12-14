package jang.std;

import jang.runtime.Interpreter;
import jang.runtime.Interpreter.JangValue;

class IO extends JangClass<JangInstance> {
	public function new() {
		super("IO");
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "print":
				return VHaxeFunction(args -> {
					#if js
					js.Syntax.code("console.log({0})", [for (arg in args) Interpreter.unwrapAny(arg)].join(", "));
					#else
					Sys.print([for (arg in args) Interpreter.unwrapAny(arg)].join(", "));
					#end
					return VNull;
				});
			case "println":
				return VHaxeFunction(args -> {
					#if js
					js.Syntax.code("console.log({0})", [for (arg in args) Interpreter.unwrapAny(arg)].join(", "));
					#else
					Sys.println([for (arg in args) Interpreter.unwrapAny(arg)].join(", "));
					#end
					return VNull;
				});
		}
		return super.getVariable(name);
	}
}
