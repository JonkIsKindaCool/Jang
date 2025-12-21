import jang.structures.Token;
import jang.runtime.Interpreter;
import jang.structures.Expr;
import haxe.Resource;
import haxe.Timer;
import jang.runtime.*;
import jang.utils.Printer;

function main() {
	var input = Resource.getString("test.jn");

	var t0:Float = Timer.stamp();

	var ast:ExprInfo = new Parser().parseString(input);

	var interpreter:Interpreter = new Interpreter();
	var result:JangValue = interpreter.execute(ast, input);

	Printer.println('Execution Time: ${(Timer.stamp() - t0) * 1000.0} ms');
	Printer.println('Result: $result');
}
