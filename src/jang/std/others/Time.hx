package jang.std.others;

import haxe.Timer;
import jang.runtime.Interpreter.JangValue;
import jang.std.JangClass;
import jang.std.JangInstance;
#if js
import js.Syntax;
#end

class Time extends JangClass<JangInstance> {
	public function new() {
		super("Time");
	}

	static inline function nowSeconds():Float {
		#if js
		return js.Syntax.code("Date.now()") / 1000;
		#else
		return Sys.time();
		#end
	}

	static inline function sleepSeconds(sec:Float):Void {
		#if js
		throw 'impossible in js';
		#else
		Sys.sleep(sec);
		#end
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "now":
				return VHaxeFunction(_ -> {
					return VFloat(nowSeconds());
				});

			case "nowMs":
				return VHaxeFunction(_ -> {
					return VFloat(nowSeconds() * 1000);
				});

			case "elapsed":
				return VHaxeFunction(args -> {
					return VFloat(Timer.stamp());
				});

			case "elapsedMs":
				return VHaxeFunction(args -> {
					return VFloat(Timer.stamp() * 1000);
				});

			case "sleep":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "sleep expects 1 parameter";

					var sec:Float = switch (args[0]) {
						case VFloat(f): f;
						case VInt(i): i;
						default: throw "sleep expects a number";
					};

					if (sec < 0)
						throw "sleep expects positive number";

					sleepSeconds(sec);
					return VNull;
				});

			case "sleepMs":
				return VHaxeFunction(args -> {
					if (args.length != 1)
						throw "sleepMs expects 1 parameter";

					var ms:Float = switch (args[0]) {
						case VFloat(f): f;
						case VInt(i): i;
						default: throw "sleepMs expects a number";
					};

					if (ms < 0)
						throw "sleepMs expects positive number";

					sleepSeconds(ms / 1000);
					return VNull;
				});
		}

		return super.getVariable(name);
	}
}
