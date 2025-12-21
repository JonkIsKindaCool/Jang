package jang.runtime.custom;

import jang.runtime.Interpreter;
import jang.runtime.Interpreter.JangValue;
import jang.structures.ClassDeclaration;
import jang.std.JangClass;
import jang.std.JangInstance;
import jang.runtime.Scope;

class CustomClass extends JangClass<CustomInstance> {
	public var interpreter:Interpreter;
	public var decl:ClassDeclaration;

	public var publicVars:Array<String> = [];
	public var privateVars:Array<String> = [];
	public var instanceScope:Scope;

	public var publicStatic:Array<String> = [];
	public var privateStatic:Array<String> = [];
	public var staticScope:Scope;

	public function new(decl:ClassDeclaration, interpreter:Interpreter, name:String) {
		super(name);

		this.decl = decl;
		this.interpreter = interpreter;

		instanceScope = new Scope(interpreter, interpreter.scope);
		staticScope = new Scope(interpreter, interpreter.scope);

		for (v in decl.variables) {
			var isStatic:Bool = v.behaviour.contains(STATIC);
			var isPublic:Bool = v.behaviour.contains(PUBLIC);

			var scope:Scope = isStatic ? staticScope : instanceScope;
			var list:Array<String> = isStatic ? (isPublic ? publicStatic : privateStatic) : (isPublic ? publicVars : privateVars);

			list.push(v.name);
			scope.define(v.name, interpreter.executeExpr(v.value, scope), v.constant, v.type);
		}

		for (f in decl.functions) {
			var isStatic: Bool = f.behaviour.contains(STATIC);
			var isPublic:Bool = f.behaviour.contains(PUBLIC);

			var scope:Scope = isStatic ? staticScope : instanceScope;
			var list:Array<String> = isStatic ? (isPublic ? publicStatic : privateStatic) : (isPublic ? publicVars : privateVars);

			list.push(f.name);

			scope.define(f.name, VFunction({
				body: f.body,
				args: f.args,
				type: f.type,
				closure: null
			}), false, TFunction);
		}
	}

	override function createInstance(args:Array<JangValue>):CustomInstance {
		var inst:CustomInstance = new CustomInstance(interpreter, name, decl.extend);

		inst.variables = new Scope(interpreter, instanceScope);
		inst.publicVariables = publicVars;
		inst.privateVariables = privateVars;

		inst.init(args);
		return inst;
	}

	override function getVariable(name:String):JangValue {
		if (staticScope.exists(name)) {
			if (!publicStatic.contains(name))
				throw 'Static variable $name is private';
			return staticScope.get(name);
		}
		return super.getVariable(name);
	}
}

class CustomInstance extends JangInstance {
	public var variables:Scope;
	public var publicVariables:Array<String>;
	public var privateVariables:Array<String>;

	public var parentClass:JangClass<Dynamic>;
	public var parentInstance:JangInstance;

	private var extendName:String;
	private var superCalled:Bool = false;

	public var interpreter:Interpreter;

	public function new(interpreter:Interpreter, name:String, extendName:String) {
		super(name);
		this.interpreter = interpreter;
		this.extendName = extendName;
	}

	public function init(args:Array<JangValue>) {
		if (extendName != null) {
			var v:JangValue = interpreter.scope.get(extendName);
			switch (v) {
				case VClass(c):
					parentClass = c;
				default:
					throw 'Superclass $extendName is not a class';
			}

			variables.define("super", VHaxeFunction((args) -> {
				if (superCalled)
					throw 'super.new() already called';

				parentInstance = parentClass.createInstance(args);
				superCalled = true;

				variables.define("super", VInstance(parentInstance), true, TCustom(parentInstance.name));

				return VNull;
			}), true, TFunction);
		}

		variables.define("this", VInstance(this), true, TCustom(name));

		var ctor:JangValue = variables.get("new");
		if (ctor == null)
			throw 'Class $name has no constructor';

		if (privateVariables.contains("new"))
			throw 'Constructor must be public';

		switch (ctor) {
			case VFunction(f):
				var bound = {
					body: f.body,
					args: f.args,
					type: f.type,
					closure: variables
				};
				interpreter.callFunction(bound, args);

			case VHaxeFunction(f):
				f(args);

			default:
				throw 'Constructor is not callable';
		}

		if (extendName != null && !superCalled)
			throw 'Constructor must call super.new(...)';
	}

	private function bindMethodScope():Scope {
		var s:Scope = new Scope(interpreter, variables);

		s.define("this", VInstance(this), true, TCustom(this.name));

		if (parentInstance != null) {
			s.define("super", VInstance(parentInstance), true, TCustom(parentInstance.name));
		}

		return s;
	}

	override function getVariable(name:String):JangValue {
		if (name == "__name__")
			return VString(this.name);

		try {
			var v:JangValue = variables.get(name);

			switch (v) {
				case VFunction(f):
					return VFunction({
						body: f.body,
						args: f.args,
						type: f.type,
						closure: bindMethodScope()
					});

				default:
					return v;
			}
		} catch (_) {
			if (parentInstance != null)
				return parentInstance.getVariable(name);
			throw 'Variable $name is not defined';
		}
	}

	override function setVariable(name:String, value:JangValue) {
		variables.assign(name, value);
	}
}
