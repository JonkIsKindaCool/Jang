package jang.std.system;

import jang.utils.TypeUtils;
import jang.runtime.Interpreter.JangValue;

class IO extends JangClass<JangInstance> {
	public static var instance:IO;

	public function new() {
		super("IO");
		instance = this;
	}

	override function getVariable(name:String):JangValue {
		switch (name) {
			case "print":
				return VHaxeFunction(args -> {
					var out:String = [for (a in args) Std.string(TypeUtils.jangToHaxe(a))].join(" ");
					#if js
					js.Syntax.code("process.stdout.write({0})", out);
					#else
					Sys.print(out);
					#end
					return VNull;
				});

			case "println":
				return VHaxeFunction(args -> {
					var out:String = [for (a in args) Std.string(TypeUtils.jangToHaxe(a))].join(" ");
					#if js
					js.Syntax.code("console.log({0})", out);
					#else
					Sys.println(out);
					#end
					return VNull;
				});

			case "readLine":
				return VHaxeFunction(_ -> {
					#if js
					var line:String = js.Syntax.code("require('fs').readFileSync(0,'utf8').trim()");
					return VString(line);
					#else
					return VString(Sys.stdin().readLine());
					#end
				});

			case "readInt":
				return VHaxeFunction(_ -> {
					#if js
					var line:String = js.Syntax.code("require('fs').readFileSync(0,'utf8').trim()");
					return VInt(Std.parseInt(line));
					#else
					return VInt(Std.parseInt(Sys.stdin().readLine()));
					#end
				});

			case "readFloat":
				return VHaxeFunction(_ -> {
					#if js
					var line:String = js.Syntax.code("require('fs').readFileSync(0,'utf8').trim()");
					return VFloat(Std.parseFloat(line));
					#else
					return VFloat(Std.parseFloat(Sys.stdin().readLine()));
					#end
				});

			case "readBool":
				return VHaxeFunction(_ -> {
					#if js
					var line:String = js.Syntax.code("require('fs').readFileSync(0,'utf8').trim()");
					return VBoolean(line == "true");
					#else
					return VBoolean(Sys.stdin().readLine() == "true");
					#end
				});

			case "error":
				return VHaxeFunction(args -> {
					var out = [for (a in args) Std.string(TypeUtils.jangToHaxe(a))].join(" ");
					#if js
					js.Syntax.code("console.error({0})", out);
					#else
					Sys.stderr().writeString(out + "\n");
					#end
					return VNull;
				});

			case "debug":
				return VHaxeFunction(args -> {
					var out = "[DEBUG] " + [for (a in args) Std.string(TypeUtils.jangToHaxe(a))].join(" ");
					#if js
					js.Syntax.code("console.log({0})", out);
					#else
					Sys.println(out);
					#end
					return VNull;
				});

			case "exit":
				return VHaxeFunction(args -> {
					var code:Int = args.length > 0 ? TypeUtils.expectInt(args[0]) : 0;
					#if js
					js.Syntax.code("process.exit({0})", code);
					#else
					Sys.exit(code);
					#end
					return VNull;
				});
		}

		return super.getVariable(name);
	}
}
