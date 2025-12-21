package jang.runtime.custom;

import haxe.macro.Expr;
import jang.structures.Expr.Argument;
import jang.runtime.Interpreter.JangFunction;
import jang.structures.Expr.Type;
import jang.structures.Expr.ExprInfo;
import jang.structures.ClassDeclaration;
import jang.std.JangClass;
import jang.runtime.Interpreter.JangValue;
import jang.std.JangInstance;

class CustomClass extends JangClass<CustomInstance> {
	public var parent:Interpreter;
	public var decl:ClassDeclaration;

	public var publicV:Array<String>;
	public var privateV:Array<String>;
	public var variables:Scope;

	public var publicStatic:Array<String>;
	public var privateStatic:Array<String>;
	public var staticVariables:Scope;

	public function new(decl:ClassDeclaration, parent:Interpreter, name:String) {
		super(name);

		this.decl = decl;
		this.parent = parent;

		publicStatic = [];
		privateStatic = [];

		privateV = [];
		publicV = [];

		variables = new Scope(parent, parent.scope);
		staticVariables = new Scope(parent, parent.scope);

		for (v in decl.variables) {
			var name:String = v.name;
			var constant:Bool = v.constant;
			var value:ExprInfo = v.value;
			var type:Type = v.type;
			if (v.behaviour.contains(STATIC)) {
				if (v.behaviour.contains(PUBLIC))
					publicStatic.push(name);
				else
					privateStatic.push(name);

				staticVariables.define(name, parent.executeExpr(value, staticVariables), constant, type);
			} else {
				if (v.behaviour.contains(PUBLIC))
					publicV.push(name);
				else
					privateV.push(name);

				variables.define(name, parent.executeExpr(value, staticVariables), constant, type);
			}
		}

		for (f in decl.functions) {
			var name:String = f.name;
			var type:Type = f.type;
			var args:Array<Argument> = f.args;
			var body:Array<ExprInfo> = f.body;
			var behaviour:Array<VariableBehaviour> = f.behaviour;

			if (behaviour.contains(STATIC)) {
				if (behaviour.contains(PUBLIC))
					publicStatic.push(name);
				else
					privateStatic.push(name);

				staticVariables.define(name, VFunction({
					body: body,
					args: args,
					type: type,
					closure: new Scope(parent, staticVariables)
				}), false, TFunction);
			} else {
				if (behaviour.contains(PUBLIC))
					publicV.push(name);
				else
					privateV.push(name);

				variables.define(name, VFunction({
					body: body,
					args: args,
					type: type,
					closure: new Scope(parent, variables)
				}), false, TFunction);
			}
		}
	}

	override function createInstance(args:Array<JangValue>):CustomInstance {
		var instance:CustomInstance = new CustomInstance(parent, name);
		instance.variables = variables;
		instance.publicVariables = publicV;
		instance.privateVariables = privateV;

		instance.init(args);

		return instance;
	}

	override function getVariable(name:String):JangValue {
		if (staticVariables.exists(name)) {
			if (publicStatic.contains(name)) {
				return staticVariables.get(name);
			} else {
				throw 'Variable $name is private';
			}
		}

		return super.getVariable(name);
	}
}

class CustomInstance extends JangInstance {
	public var publicVariables:Array<String>;
	public var privateVariables:Array<String>;

	public var variables:Scope;

	public var i:Interpreter;

	public function new(i:Interpreter, name:String) {
		super(name);
		this.i = i;
	}

	public function init(args:Array<JangValue>) {
		variables.define("this", VInstance(this), true, TCustom(name));

		var f:JangValue = variables.get("new");

		if (f == null)
			throw 'Class $name doesnt have a constructor (new)';

		if (privateVariables.contains("new")) throw '$name constructor should be a public function';

		switch (f) {
			case VFunction(f):
				i.callFunction(f, args);
			case VHaxeFunction(f):
				f(args);
			default:
				throw 'Constructor should be a callable';
		}
	}

	override function setVariable(name:String, value:JangValue) {
		variables.assign(name, value);

		super.setVariable(name, value);
	}

	override function getVariable(name:String):JangValue {
		var v:JangValue = variables.get(name);

		if (v != null) return v;

		return super.getVariable(name);
	}
}
