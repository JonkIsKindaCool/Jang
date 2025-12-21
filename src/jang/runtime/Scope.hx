package jang.runtime;

import jang.utils.TypeUtils;
import jang.structures.Expr.Type;
import jang.runtime.Interpreter.JangValue;
import haxe.ds.StringMap;

class Scope {
	public var variables:Map<String, JangVariable>;
	public var parent:Scope;
	public var interp:Interpreter;

	public function new(interp:Interpreter, parent:Scope = null) {
		this.variables = [];
		this.interp = interp;
		this.parent = parent;
	}

	public function define(name:String, value:JangValue, isConst:Bool, ?type:Type = TAny):Void {
		if (TypeUtils.checkType(value, type)) {
			variables.set(name, {value: value, constant: isConst, type: type});
		} else {
			throw 'Expected $type got $value';
		}
	}

	public function exists(name:String):Bool {
		if (variables.exists(name))
			return true;
		if (parent != null)
			return parent.exists(name);
		return false;
	}

	public function get(name:String):JangValue {
		if (variables.exists(name))
			return variables.get(name).value;
		if (parent != null)
			return parent.get(name);
		throw "Undefined variable: " + name;
	}

	public function assign(name:String, value:JangValue):Void {
		if (variables.exists(name)) {
			var variable:JangVariable = variables.get(name);
			var type:Type = variable.type;

			if (variable.constant)
				throw 'Cannot modify a constant value';
			else {
				if (TypeUtils.checkType(value, type)) {
					variables.set(name, {value: value, constant: variable.constant, type: variable.type});
				} else {
					throw 'Expected $type got $value';
				}
			}
			return;
		}
		if (parent != null) {
			parent.assign(name, value);
			return;
		}
		throw "Undefined variable: " + name;
	}

	public function callFunction(name:String, args:Array<JangValue>):JangValue {
		var value:JangValue = get(name);

		switch (value){
			case VFunction(f):
				return interp.callFunction(f, args);
			case VHaxeFunction(f):
				return f(args);
			default:
				throw 'Value is not callable';
		}
	}
}

typedef JangVariable = {
	value:JangValue,
	constant:Bool,
	type:Type
}
