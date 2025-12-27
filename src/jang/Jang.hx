package jang;

import jang.utils.Printer;
import jang.std.primitives.ArrayClass;
import jang.std.primitives.ObjectClass;
import jang.std.primitives.IntClass;
import jang.std.primitives.StringClass;
import jang.std.others.Time;
import jang.std.others.StringBuf.StringBuffer;
import jang.std.system.Math;
import jang.std.system.IO;
import jang.runtime.Scope;
import haxe.Resource;
import haxe.io.Path;
import jang.runtime.Interpreter;
import jang.runtime.Parser;
import jang.structures.Expr;

using StringTools;

class Jang {
	public static var allowHaxeImports:Bool = false;

	public static final Script_Paths:Map<String, Map<String, JangVariable>> = [
		"std" => [
			"IO" => {
					value: VClass(new IO()),
					constant: true,
					type: TCustom("IO")
				},
			"Math" => {
					value: VClass(new Math()),
					constant: true,
					type: TCustom("Math")
				}
		]
	];

	public static final ALIVE_INTERPRETERS:Map<String, Interpreter> = [];

	public static final GLOBALS:Scope = {
		var scope:Scope = new Scope(null, null);
		scope.define("String", VClass(new StringClass()), true, TCustom("String"));
		scope.define("Int", VClass(new IntClass()), true, TCustom("Int"));
		scope.define("Object", VClass(new ObjectClass()), true, TCustom("Object"));
		scope.define("Array", VClass(new ArrayClass()), true, TCustom("Array"));
		scope;
	}

	public static function getImportVariable(path:String, value:String): JangVariable {
		if (!Script_Paths.exists(path)){
			Script_Paths.set(path, []);
			var content:String = getFile(path.replace(".", "/") + ".jn");

			if (content == null){
				return null;
			}

			var ast:ExprInfo = new Parser().parseString(content);

			var interp:Interpreter =  new Interpreter(Path.directory(path), (Path.withoutDirectory(path)));
			interp.execute(ast, content);
			ALIVE_INTERPRETERS.set(path, interp);
		}

		var variables: Map<String, JangVariable> = Script_Paths.get(path);

		if (!variables.exists(value)){
			var interp:Interpreter = ALIVE_INTERPRETERS.get(path);
			variables.set(value, interp.scope.variables.get(value));
		}

		var val:JangVariable = variables.get(value);

		return val;
	}

	private static function getFile(f:String): String {
		#if sys
		return sys.io.File.getContent(f);
		#end

		return Resource.getString(f);
	}
}

typedef JangImportVariable = {
	name:String,
	value: JangVariable
}

typedef JangOutput = {
	interp:Interpreter,
	result:JangValue
}
