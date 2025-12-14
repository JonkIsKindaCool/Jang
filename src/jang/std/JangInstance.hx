package jang.std;

import jang.runtime.Interpreter.JangValue;
import jang.std.JangClass;

class JangInstance {
    public var name:String;

	public function new(?name:String = "template") {
        this.name = name;
	}

	public function setVariable(name:String, value:JangValue) {}

	public function getVariable(name:String):JangValue {
		if (name == "__name__")
			return VString(this.name);

		return VNull;
	}
}
