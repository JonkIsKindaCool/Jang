package jang.std.system;

import Math as HaxeMath;
import jang.runtime.Interpreter.JangValue;
import jang.utils.TypeUtils;

class Math extends JangClass<JangInstance> {
	public function new() {
		super("Math");
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "PI":
				return VFloat(HaxeMath.PI);

			case "abs":
				return VHaxeFunction(args -> {
					var n:Float = TypeUtils.expectFloat(args[0]);
					var r:Float = HaxeMath.abs(n);
					return (HaxeMath.floor(r) == r) ? VInt(Std.int(r)) : VFloat(r);
				});

			case "min":
				return VHaxeFunction(args -> {
					var a:Float = TypeUtils.expectFloat(args[0]);
					var b:Float = TypeUtils.expectFloat(args[1]);
					return VFloat(HaxeMath.min(a, b));
				});

			case "max":
				return VHaxeFunction(args -> {
					var a:Float = TypeUtils.expectFloat(args[0]);
					var b:Float = TypeUtils.expectFloat(args[1]);
					return VFloat(HaxeMath.max(a, b));
				});

			case "pow":
				return VHaxeFunction(args -> {
					var a:Float = TypeUtils.expectFloat(args[0]);
					var b:Float = TypeUtils.expectFloat(args[1]);
					return VFloat(HaxeMath.pow(a, b));
				});

			case "sqrt":
				return VHaxeFunction(args -> {
					var n:Float = TypeUtils.expectFloat(args[0]);
					return VFloat(HaxeMath.sqrt(n));
				});

			case "floor":
				return VHaxeFunction(args -> {
					var n:Float = TypeUtils.expectFloat(args[0]);
					return VInt(Std.int(HaxeMath.floor(n)));
				});

			case "ceil":
				return VHaxeFunction(args -> {
					var n:Float = TypeUtils.expectFloat(args[0]);
					return VInt(Std.int(HaxeMath.ceil(n)));
				});

			case "round":
				return VHaxeFunction(args -> {
					var n:Float = TypeUtils.expectFloat(args[0]);
					return VInt(Std.int(HaxeMath.round(n)));
				});

			case "sin":
				return VHaxeFunction(args -> VFloat(HaxeMath.sin(TypeUtils.expectFloat(args[0]))));

			case "cos":
				return VHaxeFunction(args -> VFloat(HaxeMath.cos(TypeUtils.expectFloat(args[0]))));

			case "tan":
				return VHaxeFunction(args -> VFloat(HaxeMath.tan(TypeUtils.expectFloat(args[0]))));

			case "random":
				return VHaxeFunction(_ -> {
					return VFloat(HaxeMath.random());
				});
		}

		return super.getVariable(name);
	}
}
