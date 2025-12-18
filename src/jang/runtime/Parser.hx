package jang.runtime;

import jang.structures.Expr;
import jang.structures.Token;
import jang.errors.JangError;

class Parser {
	public function new() {}

	private var tokens:Array<TokenInfo>;
	private var source:String = "";

	public function parseString(source:String):ExprInfo {
		this.source = source;
		return parse(Lexer.tokenize(source));
	}

	public function parse(tokens:Array<TokenInfo>):ExprInfo {
		this.tokens = tokens;

		var fileStart = peak();
		var ast:Array<ExprInfo> = [];

		while (!isEof()) {
			var e = parseExpressions();
			ast.push(e);

			if (isEof())
				break;

			if (peak().token.equals(SEMICOLON))
				advance();
		}

		return makeExprInfo(fileStart.startPos, peak().startPos, fileStart.line, Block(ast));
	}

	private function syntaxError(tok:TokenInfo, message:String, ?hint:String):Dynamic {
		throw new JangError(source, tok.startPos, tok.endPos, tok.line, message, JangErrorType.SYNTAX_ERROR, "main.jn", hint);
	}

	private function parseExpressions():ExprInfo {
		return parseStatements();
	}

	private function parseStatements():ExprInfo {
		switch (peak().token) {
			case IDENTIFIER("if"):
				var line:Int = peak().line;
				var startPos:Int = peak().startPos;
				var elsE:ExprInfo = null;

				advance();
				expect(LPAREN);
				var cond:ExprInfo = parseEquality();
				var lastPos:Int = peak().startPos;
				expect(RPAREN);

				expect(LBRACE);
				var body:Array<ExprInfo> = [];

				while (!peak().token.equals(RBRACE)) {
					body.push(parseStatements());
					if (peak().token.equals(SEMICOLON))
						advance();
				}

				expect(RBRACE);
				var bodyPos:Int = peak(-1).startPos;

				switch (peak().token) {
					case IDENTIFIER("else"):
						var line:Int = peak().line;
						var startPos:Int = peak().startPos;
						advance();
						expect(LBRACE);
						var elseBody:Array<ExprInfo> = [];

						while (!peak().token.equals(RBRACE)) {
							elseBody.push(parseStatements());
							if (peak().token.equals(SEMICOLON))
								advance();
						}

						var endPos:Int = peak().startPos;
						expect(RBRACE);
						elsE = makeExprInfo(startPos, endPos, line, Block(elseBody));
					case IDENTIFIER("elif"):
						tokens[0].token = IDENTIFIER("if");
						elsE = parseStatements();
					default:
				}

				return makeExprInfo(startPos, lastPos, line, If(cond, makeExprInfo(startPos, bodyPos, line, Block(body)), elsE));

			case IDENTIFIER("let"), IDENTIFIER("const"):
				var startTok:TokenInfo = advance();
				var isConstant:Bool = startTok.token.equals(IDENTIFIER("const"));

				var name:String = getIdent();
				var expr:ExprInfo = makeExprInfo(startTok.startPos, startTok.endPos, startTok.line, NullLiteral);

				var type:Type = TAny;

				if (peak().token.equals(COLON)) {
					advance();
					type = getType();
				}

				if (isConstant) {
					expect(OPERATOR("="));
					expr = parseAssigment();
				} else {
					if (peak().token.equals(OPERATOR("="))) {
						advance();
						expr = parseAssigment();
					}
				}

				return makeFromExprs(makeExprInfo(startTok.startPos, startTok.endPos, startTok.line, NullLiteral), expr,
					Assignment(name, expr, isConstant, type));

			case IDENTIFIER("while"):
				var whileStart:TokenInfo = advance();
				expect(LPAREN);
				var cond:ExprInfo = parseAssigment();
				expect(RPAREN);
				expect(LBRACE);

				var body:Array<ExprInfo> = [];

				while (!peak().token.equals(RBRACE)) {
					body.push(parseStatements());
					if (peak().token.equals(SEMICOLON))
						advance();
				}

				expect(RBRACE);

				return makeFromTokenRange(whileStart, current(), While(cond, body));

			case IDENTIFIER("func"):
				var funcStart:TokenInfo = advance();

				var name:String = null;
				var type:Type = TAny;
				var args:Array<Argument> = [];
				var body:Array<ExprInfo> = [];

				if (peak().token.match(IDENTIFIER(_)))
					name = advance().token.getParameters()[0];

				expect(LPAREN);

				while (!peak().token.equals(RPAREN)) {
					var argName:String = getIdent();
					var argType:Type = TAny;

					if (peak().token.equals(COLON)) {
						advance();
						argType = getType();
					}

					args.push({name: argName, type: argType});

					if (!peak().token.equals(RPAREN))
						expect(COMMA);
				}

				expect(RPAREN);

				if (peak().token.equals(COLON)) {
					advance();
					type = getType();
				}

				expect(LBRACE);

				while (!peak().token.equals(RBRACE)) {
					body.push(parseStatements());
					if (peak().token.equals(SEMICOLON))
						advance();
				}

				expect(RBRACE);

				return makeFromTokenRange(funcStart, current(), Function(body, args, type, name));

			case IDENTIFIER("import"):
				var impStart:TokenInfo = advance();
				var path:Array<String> = [];

				while (true) {
					if (peak().token.equals(SEMICOLON))
						break;

					path.push(getIdent());

					if (peak().token.equals(SEMICOLON))
						break;
					else
						expect(DOT);
				}

				return makeFromTokenRange(impStart, current(), Import(path));

			case IDENTIFIER("return"):
				var rStart:TokenInfo = advance();
				var rExpr:ExprInfo = parseAssigment();
				return makeFromExprs(makeExprInfo(rStart.startPos, rStart.endPos, rStart.line, NullLiteral), rExpr, Ender(Return(rExpr)));

			case IDENTIFIER("break"):
				var bStart:TokenInfo = advance();
				return makeExprInfo(bStart.startPos, bStart.endPos, bStart.line, Ender(Break));
			case IDENTIFIER("continue"):
				var cStart:TokenInfo = advance();
				return makeExprInfo(cStart.startPos, cStart.endPos, cStart.line, Ender(Continue));

			default:
				return parseAssigment();
		}
	}

	private function parseAssigment():ExprInfo {
		if (peak(1).token.equals(OPERATOR("="))
			|| peak(1).token.equals(OPERATOR("+="))
			|| peak(1).token.equals(OPERATOR("-="))
			|| peak(1).token.equals(OPERATOR("*="))
			|| peak(1).token.equals(OPERATOR("/="))) {
			var left:ExprInfo = parseEquality();
			var opTok:TokenInfo = advance();
			var op:String = opTok.token.getParameters()[0];
			var right:ExprInfo = parseAssigment();
			return makeFromExprs(left, right, BinaryOp(left, op, right));
		}

		return parseEquality();
	}

	private function parseEquality():ExprInfo {
		var left:ExprInfo = parseNegative();

		if (peak().token.equals(OPERATOR("==")) || peak().token.equals(OPERATOR("!=")) || peak().token.equals(OPERATOR("<="))
			|| peak().token.equals(OPERATOR(">=")) || peak().token.equals(OPERATOR("<")) || peak().token.equals(OPERATOR(">"))) {
			var opTok:TokenInfo = advance();
			var op:String = opTok.token.getParameters()[0];
			var right:ExprInfo = parseEquality();
			return makeFromExprs(left, right, BinaryOp(left, op, right));
		}

		return left;
	}

	private function parseNegative():ExprInfo {
		if (peak().token.equals(OPERATOR("-"))) {
			var startTok:TokenInfo = advance();
			var right:ExprInfo = parseAdditive();
			var negExprInfo:ExprInfo = makeExprInfo(startTok.startPos, startTok.endPos, startTok.line, NumberLiteral(-1));
			return makeFromExprs(negExprInfo, right, BinaryOp(negExprInfo, "*", right));
		}

		return parseAdditive();
	}

	private function parseAdditive():ExprInfo {
		var left:ExprInfo = parseMultiplicative();

		if (peak().token.equals(OPERATOR("+")) || peak().token.equals(OPERATOR("-"))) {
			var opTok:TokenInfo = advance();
			var op:String = opTok.token.getParameters()[0];
			var right:ExprInfo = parseAdditive();
			return makeFromExprs(left, right, BinaryOp(left, op, right));
		}

		return left;
	}

	private function parseMultiplicative():ExprInfo {
		var left:ExprInfo = parsePrimitives();

		if (peak().token.equals(OPERATOR("*")) || peak().token.equals(OPERATOR("/")) || peak().token.equals(OPERATOR("%"))) {
			var opTok:TokenInfo = advance();
			var op:String = opTok.token.getParameters()[0];
			var right:ExprInfo = parseMultiplicative();
			return makeFromExprs(left, right, BinaryOp(left, op, right));
		}

		return left;
	}

	private function parsePrimitives():ExprInfo {
		switch (peak().token) {
			case NUMBER(value):
				var t:TokenInfo = advance();
				return makeExprInfo(t.startPos, t.endPos, t.line, NumberLiteral(value));

			case LPAREN:
				advance();
				var inner:ExprInfo = parseAssigment();
				expect(RPAREN);
				return parsePostfix(inner);

			case STRING(value):
				var s:TokenInfo = advance();
				return parsePostfix(makeExprInfo(s.startPos, s.endPos, s.line, StringLiteral(value)));

			case IDENTIFIER("true"), IDENTIFIER("false"):
				var bTok:TokenInfo = advance();
				var boolValue = bTok.token.equals(IDENTIFIER("true"));
				return makeExprInfo(bTok.startPos, bTok.endPos, bTok.line, BooleanLiteral(boolValue));

			case IDENTIFIER("null"):
				var nTok:TokenInfo = advance();
				return makeExprInfo(nTok.startPos, nTok.endPos, nTok.line, NullLiteral);

			case IDENTIFIER("new"):
				var newTok:TokenInfo = advance();
				var name:String = getIdent();

				var args:Array<ExprInfo> = [];
				expect(LPAREN);
				while (!peak().token.equals(RPAREN)) {
					args.push(parseAssigment());
					if (!peak().token.equals(RPAREN))
						expect(COMMA);
				}
				expect(RPAREN);

				return parsePostfix(makeFromTokenRange(newTok, current(), New(name, args)));

			case IDENTIFIER(name):
				var idTok:TokenInfo = advance();
				return parsePostfix(makeExprInfo(idTok.startPos, idTok.endPos, idTok.line, Identifier(name)));

			default:
				syntaxError(peak(), "Unexpected token: " + Std.string(peak().token), "This expression is not valid here");
		}
		return null;
	}

	private function parsePostfix(e:ExprInfo):ExprInfo {
		switch (peak().token) {
			case OPERATOR("++"):
				var opTok:TokenInfo = advance();
				var one:ExprInfo = makeExprInfo(e.posStart, e.posEnd, e.line, NumberLiteral(1));
				return makeExprInfo(e.posStart, opTok.endPos, e.line, BinaryOp(e, "+=", one));

			case OPERATOR("--"):
				var opTok2:TokenInfo = advance();
				var one2:ExprInfo = makeExprInfo(e.posStart, e.posEnd, e.line, NumberLiteral(1));
				return makeExprInfo(e.posStart, opTok2.endPos, e.line, BinaryOp(e, "-=", one2));

			case DOT:
				advance();
				var field:String = getIdent();
				return parsePostfix(makeExprInfo(e.posStart, current().endPos, e.line, Field(e, field)));

			case LPAREN:
				advance();
				var args:Array<ExprInfo> = [];
				while (!peak().token.equals(RPAREN)) {
					args.push(parseAssigment());
					if (!peak().token.equals(RPAREN))
						expect(COMMA);
				}
				expect(RPAREN);
				return parsePostfix(makeExprInfo(e.posStart, current().endPos, e.line, Call(e, args)));

			default:
				return e;
		}
	}

	private function getIdent():String {
		var token:TokenInfo = advance();
		if (!token.token.match(IDENTIFIER(_)))
			syntaxError(token, "Expected Identifier", "Identifiers must start with a letter or '_'");
		return token.token.getParameters()[0];
	}

	private function isEof():Bool {
		return peak().token.equals(EOF);
	}

	private function peak(offset:Int = 0):TokenInfo {
		if (offset < 0)
			offset = 0;
		if (offset >= tokens.length)
			return tokens[tokens.length - 1];
		return tokens[offset];
	}

	private function expect(t:Token) {
		if (peak().token.equals(t)) {
			advance();
			return;
		}

		syntaxError(peak(), "Expected " + Std.string(t) + ", found " + Std.string(peak().token));
	}

	private function advance():TokenInfo {
		if (tokens.length == 0) {
			var fake:TokenInfo = {
				startPos: 1,
				endPos: 1,
				line: 1,
				token: EOF
			};
			syntaxError(fake, "Unexpected end of input", "File ended before expression was completed");
		}
		return tokens.shift();
	}

	private function getType():Type {
		var typeName:String = getIdent();
		return switch (typeName) {
			case "string": TString;
			case "int": TInt;
			case "float": TFloat;
			case "boolean": TBool;
			case "any": TAny;
			case "callable": TFunction;
			default:
				syntaxError(current(), "Unknown type '" + typeName + "'", "Did you forget to define it?");
		}
		return TAny;
	}

	public static inline function makeExprInfo(posStart:Int, posEnd:Int, line:Int, expr:Expr):ExprInfo {
		return {
			posStart: posStart,
			posEnd: posEnd,
			line: line,
			expr: expr
		};
	}

	private inline function makeFromExprs(left:ExprInfo, right:ExprInfo, expr:Expr):ExprInfo {
		return makeExprInfo(left.posStart, right.posEnd, left.line, expr);
	}

	private inline function makeFromTokenRange(start:TokenInfo, end:TokenInfo, expr:Expr):ExprInfo {
		return makeExprInfo(start.startPos, end.endPos, start.line, expr);
	}

	private inline function current():TokenInfo {
		return peak();
	}
}
