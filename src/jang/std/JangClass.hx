package jang.std;

import jang.std.JangInstance;
import jang.runtime.Interpreter.JangValue;

class JangClass<T:JangInstance> {
    public var name:String;

    public function new(?name:String = "template") {
        this.name = name;
    }

    public function createInstance(args:Array<JangValue>):T {
        throw 'Class $name doenst have a constructor';
    }

    public function setVariable(name:String, value: JangValue) {
        throw 'Testing stuff';
    }

    public function getVariable(name:String):JangValue {
        if (name == "__name__") return VString(this.name);

        return VNull;
    }

    public function toString():String {
        return name;
    }
}