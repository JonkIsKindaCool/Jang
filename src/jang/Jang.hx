package jang;

import haxe.Resource;
import haxe.io.Path;
import jang.structures.Expr;
import jang.runtime.Parser;
import jang.runtime.Interpreter;

using StringTools;

class Jang {
	public static var alivesInterpreters:Map<String, JangOutput> = new Map();

	public static dynamic function resolveScript(path:String):JangOutput {
		if (alivesInterpreters.exists(path)) return alivesInterpreters.get(path);

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

		var interp:Interpreter = new Interpreter();
		var result:JangOutput = {
			result: interp.execute(ast, Path.withoutDirectory(path)),
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
