package jang.runtime;

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
		if (checkType(value, type)) {
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
				if (checkType(value, type)) {
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

	public static function checkType(v:JangValue, t:Type) {
		if (t.equals(TAny))
			return true;

		switch (v) {
			case VString(_):
				return t.equals(TString);
			case VInt(i):
				return t.equals(TInt);
			case VFloat(f):
				return t.equals(TFloat) || t.equals(TInt);
			case VBoolean(b):
				return t.equals(TBool);
			case VInstance(i):
				if (t.match(TCustom(_))) {
					var name:String = t.getParameters()[0];
					if (i.name == name)
						return true;
				}
				return false;
			case VFunction(f):
				return t.equals(TFunction);
			case VHaxeFunction(f):
				return t.equals(TFunction);
			default:
				return false;
		}
	}
}

typedef JangVariable = {
	value:JangValue,
	constant:Bool,
	type:Type
}
