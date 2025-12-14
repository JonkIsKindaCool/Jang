import jang.runtime.Interpreter;
import jang.structures.Expr;
import haxe.Resource;
import haxe.Timer;
import jang.Parser;
import jang.utils.Printer;
import jang.Lexer;

function main() {
	var input = Resource.getString("test.jn");

	var t0:Float = Timer.stamp();

	Printer.println('\n==== TOKENS ====');
	Printer.printTokens(Lexer.tokenize(input));
	Printer.println('==== TOKENS ====');

	Printer.println('\n==== AST ====');

	var ast:Expr = new Parser().parse(Lexer.tokenize(input));

	Printer.printExpr(ast);
	Printer.println('==== AST ====');

	Printer.println('\n==== RUNTIME ====');

	var result:JangValue = new Interpreter().execute(ast);

	Printer.println('Result: $result');
	Printer.println('==== RUNTIME ====');

	Printer.println('Execution Time: ${(Timer.stamp() - t0) * 1000.0} ms');
}
