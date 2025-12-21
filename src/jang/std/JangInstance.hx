package jang.std;

import jang.utils.TypeUtils;
import jang.runtime.Interpreter.JangValue;
import jang.std.JangClass;

class JangInstance {
    public var name:String;

	public function new(?name:String = "template") {
        this.name = name;
	}

	public function setVariable(name:String, value:JangValue) {}

	public function getVariable(name:String):JangValue {
		switch (name){
			case '__name__': return VString(this.name);
			case '__index_access__': return VHaxeFunction(args -> getVariable(TypeUtils.jangToHaxe(args[0])));
			case '__index_setter__': return VHaxeFunction(args -> {
				setVariable(TypeUtils.jangToHaxe(args[0]), args[1]);
				return VNull;
			});
		}

		return VNull;
	}
}
