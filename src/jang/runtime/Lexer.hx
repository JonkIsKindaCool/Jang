package jang.runtime;

import jang.structures.Token;

class Lexer {
	static final operators:Array<String> = [
		"==", "!=", "<=", ">=", "&&", "||", "+=", "-=", "*=", "/=", "++", "--", "+", "-", "*", "/", "%", "=", "<", ">", "!"
	];

	public static function tokenize(input:String):Array<TokenInfo> {
		var tokens:Array<TokenInfo> = [];
		var i:Int = 0;
		var line:Int = 1;
		var pos:Int = 1;

		inline function pushToken(token:Token, startPos:Int, endPos:Int) {
			tokens.push({
				startPos: startPos,
				endPos: endPos,
				line: line,
				token: token
			});
		}

		while (i < input.length) {
			var ch:String = input.charAt(i);

			switch (ch) {
				case ' ', '\t', '\r':
					i++;
					pos++;
					continue;

				case '\n':
					i++;
					pos++;
					pos = 1;
					line++;
					continue;

				case '"':
					var start:Int = pos;
					i++;
					pos++;
					var str:String = "";

					while (i < input.length && input.charAt(i) != '"') {
						var c:String = input.charAt(i);

						if (c == "\\") {
							if (i + 1 >= input.length)
								throw "Unterminated escape sequence";
							var next = input.charAt(i + 1);
							c = switch (next) {
								case "n": "\n";
								case "r": "\r";
								case "t": "\t";
								case "\"": "\"";
								case "\\": "\\";
								default: throw "Illegal escape character: \\" + next;
							};
							i += 2;
							pos += 2;
						} else {
							str += c;
							i++;
							pos++;
						}
					}

					if (i >= input.length)
						throw "Unterminated string literal";

					i++;
					pos++;
					pushToken(STRING(str), start, pos - 1);
					continue;

				case '/' : {
					var next = input.charAt(i + 1);
					switch (next){
						case '/':
							while (true){
								if (input.charAt(i) == "\n") break;
								i++;
							}
							continue;
					}
				}

				case '(':
					i++;
					pushToken(LPAREN, pos, pos);
					pos++;
					continue;

				case ')':
					i++;
					pushToken(RPAREN, pos, pos);
					pos++;
					continue;
				case '{':
					i++;
					pushToken(LBRACE, pos, pos);
					pos++;
					continue;
				case '}':
					i++;
					pushToken(RBRACE, pos, pos);
					pos++;
					continue;
				case '[':
					i++;
					pushToken(LBRACKET, pos, pos);
					pos++;
					continue;
				case ']':
					i++;
					pushToken(RBRACKET, pos, pos);
					pos++;
					continue;
				case ';':
					i++;
					pushToken(SEMICOLON, pos, pos);
					pos++;
					continue;
				case ',':
					i++;
					pushToken(COMMA, pos, pos);
					pos++;
					continue;
				case ':':
					i++;
					pushToken(COLON, pos, pos);
					pos++;
					continue;
				case '.':
					i++;
					pushToken(DOT, pos, pos);
					pos++;
					continue;
			}

			if (ch >= '0' && ch <= '9') {
				var startNum:Int = pos;
				var numStr:String = "";
				var isFloat:Bool = false;

				while (i < input.length) {
					var c:String = input.charAt(i);
					if (c >= '0' && c <= '9') {
						numStr += c;
						i++;
						pos++;
					} else if (c == "." && !isFloat) {
						isFloat = true;
						numStr += c;
						i++;
						pos++;
					} else
						break;
				}

				pushToken(NUMBER(Std.parseFloat(numStr)), startNum, pos - 1);
				continue;
			}

			if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_') {
				var startId:Int = pos;
				var id:String = "";

				while (i < input.length) {
					var c = input.charAt(i);
					if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_') {
						id += c;
						i++;
						pos++;
					} else
						break;
				}

				pushToken(IDENTIFIER(id), startId, pos - 1);
				continue;
			}

			var matched:Bool = false;
			var startOp:Int = pos;
			for (op in operators) {
				if (i + op.length <= input.length && input.substr(i, op.length) == op) {
					pushToken(OPERATOR(op), startOp, startOp + op.length - 1);
					i += op.length;
					pos += op.length;
					matched = true;
					break;
				}
			}
			if (!matched)
				throw 'Unexpected character: "' + ch + '" at ' + line + ':' + pos;
		}

		pushToken(EOF, pos, pos);
		return tokens;
	}
}
