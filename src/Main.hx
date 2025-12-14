import jang.runtime.Interpreter;
import jang.structures.Expr;
import haxe.Resource;
import jang.Parser;
import jang.utils.Printer;
import jang.Lexer;

function main() {
	var input = Resource.getString("test.jn");

	var t0:Float = Sys.time();

	Sys.println('\n==== TOKENS ====');
	Printer.printTokens(Lexer.tokenize(input));
	Sys.println('==== TOKENS ====');

	Sys.println('\n==== AST ====');

	var ast:Expr = new Parser().parse(Lexer.tokenize(input));

	Printer.printExpr(ast);
	Sys.println('==== AST ====');

	Sys.println('\n==== RUNTIME ====');

	var result:JangValue = new Interpreter().execute(ast);

	Sys.println('Result: $result');
	Sys.println('==== RUNTIME ====');

	Sys.println('Execution Time: ${(Sys.time() - t0) * 1000.0} ms');
}
