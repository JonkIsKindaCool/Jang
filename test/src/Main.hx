import jang.Jang;
import jang.Jang.JangOutput;
import jang.structures.Token;
import jang.runtime.Interpreter;
import jang.structures.Expr;
import haxe.Resource;
import haxe.Timer;
import jang.runtime.*;
import jang.utils.Printer;

function main() {
	var t0:Float = Timer.stamp();

	Obj;

	Jang.allowHaxeImports = true;

	var interp:Interpreter = new Interpreter();
	var result = interp.execute(new Parser().parseString(sys.io.File.getContent("main.jn")), sys.io.File.getContent("main.jn"));

	Printer.println('Execution Time: ${(Timer.stamp() - t0) * 1000.0} ms');
	Printer.println('Result: $result');
}
