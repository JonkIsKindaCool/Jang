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

	var output:JangOutput = Jang.resolveScript("main");

	var interpreter:Interpreter = output.interp;
	var result:JangValue = output.result;

	Printer.println('Execution Time: ${(Timer.stamp() - t0) * 1000.0} ms');
	Printer.println('Result: $result');
}
