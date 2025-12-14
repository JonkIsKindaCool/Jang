package jang;

import jang.structures.Token;

class Lexer {
	static var operators = [
		"+", "-", "*", "/", "%", "=", "+=", "-=", "*=", "/=", "==", "!=", "<", ">", "<=", ">=", "&&", "||", "!", "++", "--"
	];

	public static function tokenize(input:String):Array<Token> {
		var tokens = new Array<Token>();
		var i = 0;
		while (i < input.length) {
			var char = input.charAt(i);
			switch (char) {
				case ' ', '\t', '\n', '\r':
					i++;
				case '"':
					i++;
					var str = "";
					while (i < input.length && input.charAt(i) != '"') {
						var char = input.charAt(i);

						if (char == "\\"){
							var next = input.charAt(i + 1);
							switch (next){
								case "n": char = "\n";
								case "r": char = "\r";
								case "t": char = "\t";
								case "\\": char = "\\";
								default: throw 'Ilegal Character';
							}
							i++;
						}

						str += char;
						i++;
					}

					if (i >= input.length)
						throw "Unterminated string literal";

					i++;
					tokens.push(STRING(str));
				case '(':
					tokens.push(LPAREN);
					i++;
				case ')':
					tokens.push(RPAREN);
					i++;
				case '{':
					tokens.push(LBRACE);
					i++;
				case '}':
					tokens.push(RBRACE);
					i++;
				case '[':
					tokens.push(LBRACKET);
					i++;
				case ']':
					tokens.push(RBRACKET);
					i++;
				case ';':
					tokens.push(SEMICOLON);
					i++;
				case ',':
					tokens.push(COMMA);
					i++;
				case ':':
					tokens.push(COLON);
					i++;
				case '.':
					tokens.push(DOT);
					i++;
				default:
					if (char >= '0' && char <= '9') {
						var numStr = "";
						var isFloat = false;
						while (i < input.length && input.charAt(i) >= '0' && input.charAt(i) <= '9') {
							numStr += input.charAt(i);
							i++;

							if (i < input.length && input.charAt(i) == '.' && !isFloat) {
								isFloat = true;
								numStr += input.charAt(i);
								i++;
							}
						}
						tokens.push(NUMBER(Std.parseFloat(numStr)));
					} else if ((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_') {
						var idStr = "";
						while (i < input.length
							&& ((input.charAt(i) >= 'a' && input.charAt(i) <= 'z')
								|| (input.charAt(i) >= 'A' && input.charAt(i) <= 'Z')
								|| (input.charAt(i) >= '0' && input.charAt(i) <= '9')
								|| input.charAt(i) == '_')) {
							idStr += input.charAt(i);
							i++;
						}
						tokens.push(IDENTIFIER(idStr));
					} else {
						if (operators.contains(char) && operators.contains(char + input.charAt(i + 1))) {
							tokens.push(OPERATOR(char + input.charAt(i + 1)));
							i += 2;
						} else if (operators.contains(char)) {
							tokens.push(OPERATOR(char));
							i++;
						} else {
							throw "Unexpected character: " + char;
						}
					}
			}
		}
		tokens.push(EOF);
		return tokens;
	}
}
