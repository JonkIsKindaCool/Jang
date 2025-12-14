package jang.structures;

enum Token {
    EOF;
    IDENTIFIER(name:String);
    NUMBER(value:Float);
    OPERATOR(op:String);    
    LPAREN; // Left Parenthesis
    RPAREN; // Right Parenthesis
    LBRACE; // Left Brace {
    RBRACE; // Right Brace }
    SEMICOLON;
    LBRACKET; // Left Bracket [
    RBRACKET; // Right Bracket ]
    COMMA; // ,
    DOT; // .
    STRING(value:String);
    COLON; // :
}