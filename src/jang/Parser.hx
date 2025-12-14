package jang;

import haxe.macro.Expr;
import jang.structures.Expr;
import jang.structures.Token;

class Parser {
	public function new() {}

	private var tokens:Array<Token>;
	private var inClass:Bool = false;

	public function parse(tokens:Array<Token>) {
		this.tokens = tokens;

		var ast:Array<Expr> = [];

		while (true) {
			if (isEof())
				break;

			ast.push(parseExpressions());

			if (isEof())
				break;

			if (peak().equals(SEMICOLON)) {
				advance();
			}
		}

		return Block(ast);
	}

	private function parseExpressions() {
		var left:Expr = parseStatements();

		return left;
	}

	private function parseStatements() {
		switch (peak()) {
			case IDENTIFIER("let"), IDENTIFIER("const"):
				var isConstant:Bool = peak().equals(IDENTIFIER("const"));
				advance();

				var name:String = getIdent();
				var expr:Expr = NullLiteral;

				var type:Type = TAny;

				if (peak().equals(COLON)) {
					advance();
					type = getType();
				}

				if (isConstant) {
					expect(OPERATOR("="));
					expr = parseAssigment();
				} else {
					if (peak().equals(OPERATOR("="))) {
						advance();
						expr = parseAssigment();
					}
				}

				return Assignment(name, expr, isConstant, type);
			case IDENTIFIER("while"):
				advance();
				expect(LPAREN);
				final cond = parseAssigment();
				expect(RPAREN);
				expect(LBRACE);

				var body:Array<Expr> = [];

				while (!peak().equals(RBRACE)) {
					body.push(parseStatements());
					if (peak().equals(SEMICOLON))
						advance();
				}

				expect(RBRACE);

				return While(cond, body);
			case IDENTIFIER("fn"):
				advance();

				var name:String = null;
				var type:Type = TAny;
				var args:Array<Argument> = [];
				var body:Array<Expr> = [];

				if (peak().match(IDENTIFIER(_)))
					name = advance().getParameters()[0];

				expect(LPAREN);

				while (!peak().equals(RPAREN)) {
					var name:String = getIdent();
					var type:Type = TAny;
					if (peak().equals(COLON)) {
						advance();
						type = getType();
					}

					args.push({name: name, type: type});

					if (!peak().equals(RPAREN))
						expect(COMMA);
				}

				expect(RPAREN);

				if (peak().equals(COLON)) {
					advance();
					type = getType();
				}

				expect(LBRACE);

				while (!peak().equals(RBRACE)) {
					body.push(parseStatements());
					if (peak().equals(SEMICOLON))
						advance();
				}

				expect(RBRACE);

				return Function(body, args, type, name);

			case IDENTIFIER("import"):
				advance();
				var path:Array<String> = [];

				while (true) {
					if (peak().equals(SEMICOLON))
						break;

					path.push(getIdent());

					if (peak().equals(SEMICOLON))
						break;
					else
						expect(DOT);
				}
				return Import(path);
			case IDENTIFIER("return"):
				advance();
				return Ender(Return(parseAssigment()));

			case IDENTIFIER("break"):
				advance();
				return Ender(Break);
			case IDENTIFIER("continue"):
				advance();
				return Ender(Continue);
			default:
				return parseAssigment();
		}
	}

	private function parseAssigment():Expr {
		if (peak(1).equals(OPERATOR("=")) || peak(1).equals(OPERATOR("+=")) || peak(1).equals(OPERATOR("-=")) || peak(1).equals(OPERATOR("*="))
			|| peak(1).equals(OPERATOR("/="))) {
			var left:jang.structures.Expr = parseEquality();
			var op:String = advance().getParameters()[0];

			var expr:Expr = parseAssigment();
			return BinaryOp(left, op, expr);
		}

		return parseEquality();
	}

	private function parseEquality():Expr {
		var left:Expr = parseAdditive();

		if (peak().equals(OPERATOR("==")) || peak().equals(OPERATOR("!=")) || peak().equals(OPERATOR("<=")) || peak().equals(OPERATOR(">="))
			|| peak().equals(OPERATOR("<")) || peak().equals(OPERATOR(">"))) {
			var op = advance().getParameters()[0];
			var right:Expr = parseEquality();
			return BinaryOp(left, op, right);
		}

		return left;
	}

	private function parseAdditive():Expr {
		var left:Expr = parseMultiplicative();

		if (peak().equals(OPERATOR("+")) || peak().equals(OPERATOR("-"))) {
			var op = advance().getParameters()[0];
			var right:Expr = parseAdditive();
			return BinaryOp(left, op, right);
		}

		return left;
	}

	private function parseMultiplicative():Expr {
		var left:Expr = parsePrimitives();

		if (peak().equals(OPERATOR("*")) || peak().equals(OPERATOR("/")) || peak().equals(OPERATOR("%"))) {
			var op = advance().getParameters()[0];
			var right:Expr = parseMultiplicative();
			return BinaryOp(left, op, right);
		}

		return left;
	}

	private function parsePrimitives():Expr {
		switch (peak()) {
			case NUMBER(value):
				advance();
				return NumberLiteral(value);
			case LPAREN:
				advance();
				var parent:Expr = parseAssigment();

				expect(RPAREN);
				return parsePostfix(Top(parent));
			case STRING(value):
				advance();
				return parsePostfix(StringLiteral(value));
			case IDENTIFIER("true"), IDENTIFIER("false"):
				var boolValue = (peak().equals(IDENTIFIER("true")));
				advance();
				return BooleanLiteral(boolValue);
			case IDENTIFIER("null"):
				advance();
				return NullLiteral;
			case IDENTIFIER("new"):
				advance();
				var name:String = getIdent();

				var args:Array<Expr> = [];
				expect(LPAREN);
				while (true) {
					if (peak().equals(RPAREN))
						break;

					args.push(parseAssigment());

					if (peak().equals(RPAREN))
						break;
					else
						expect(COMMA);
				}
				expect(RPAREN);

				return parsePostfix(New(name, args));
			case IDENTIFIER(name):
				advance();
				return parsePostfix(Identifier(name));
			default:
				throw "Unexpected token: " + peak();
		}
	}

	private function parsePostfix(e:Expr):Expr {
		switch (peak()) {
			case DOT:
				advance();
				var field:String = getIdent();
				return parsePostfix(Field(e, field));
			case LPAREN:
				advance();
				var args:Array<Expr> = [];
				while (true) {
					if (peak().equals(RPAREN))
						break;

					args.push(parseAssigment());

					if (peak().equals(RPAREN))
						break;
					else
						expect(COMMA);
				}
				expect(RPAREN);
				return parsePostfix(Call(e, args));
			default:
				return e;
		}
	}

	private function getIdent():String {
		var token:Token = advance();
		if (!token.match(IDENTIFIER(_)))
			throw 'Expected Identifier';

		return token.getParameters()[0];
	}

	private function isEof():Bool {
		return peak().equals(EOF);
	}

	private function peak(offset:Int = 0) {
		return tokens[offset];
	}

	private function expect(t:Token) {
		if (peak().equals(t)) {
			advance();
			return;
		}

		throw 'Expected $t, not ${peak()}';
	}

	private function advance() {
		return tokens.shift();
	}

	private function getType():Type {
		var type:String = getIdent();
		return switch (type) {
			case 'string': TString;
			case 'int': TInt;
			case 'float': TFloat;
			case 'boolean': TBool;
			case 'any': TAny;
			default: TCustom(type);
		}
	}
}
