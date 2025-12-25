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
	public static final GLOBALS:Scope = {
		var scope:Scope = new Scope(null, null);
		scope.define("IO", VClass(new IO()), true, TCustom("IO"));
		scope.define("Math", VClass(new Math()), true, TCustom("Math"));
		scope.define("StringBuffer", VClass(new StringBuffer()), true, TCustom("StringBuffer"));
		scope.define("Time", VClass(new Time()), true, TCustom("Time"));
		scope.define("String", VClass(new StringClass()), true, TCustom("String"));
		scope.define("Int", VClass(new IntClass()), true, TCustom("Int"));
		scope.define("Object", VClass(new ObjectClass()), true, TCustom("Object"));
		scope.define("Array", VClass(new ArrayClass()), true, TCustom("Array"));
		scope.define("print", IO.instance.getVariable('println'), true, TFunction);
		scope;
	}

	public static var alivesInterpreters:Map<String, JangOutput> = new Map();

	public static dynamic function resolveScript(path:String):JangOutput {
		if (alivesInterpreters.exists(path))
			return alivesInterpreters.get(path);

		path = path.replace('.', '/') + '.jn';

		var content:String = null;

		#if sys
		if (!sys.FileSystem.exists(path))
			throw 'Script $path doesnt exists';

		content = sys.io.File.getContent(path);
		#else
		if (!Resource.listNames().contains(path))
			throw 'Script $path doesnt exists';

		content = Resource.getString(path);
		#end

		var parser:Parser = new Parser();
		var ast:ExprInfo = parser.parseString(content);

		#if JANG_DEVELOPING
		Printer.printExpr(ast);
		#end

		var interp:Interpreter = new Interpreter();
		var result:JangOutput = {
			result: interp.execute(ast, content),
			interp: interp
		};
		alivesInterpreters.set(path, result);
		return result;
	}
}

typedef JangOutput = {
	interp:Interpreter,
	result:JangValue
}
