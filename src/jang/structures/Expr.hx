package jang.structures;

enum Expr {
    NumberLiteral(value:Float);
    BooleanLiteral(value:Bool); 
    NullLiteral;
    Identifier(name:String);
    Block(statements:Array<Expr>);
    BinaryOp(left:Expr, op:String, right:Expr);
    Assignment(name:String, right:Expr, isConstant:Bool, type: Type);
    StringLiteral(value:String);
    Field(p:Expr, f:String);
    Call(f:Expr, args:Array<Expr>);
    Top(e:Expr);
    While(c:Expr, b:Array<Expr>);
    New(e:String, args:Array<Expr>);
    Import(p:Array<String>);
    Ender(e:Ender);
    Function(expr:Array<Expr>, args:Array<Argument>, type: Type, ?name:String);
}

enum Ender {
    Return(e:Expr);
    Break;
    Continue;
}

typedef Argument = {
    name:String,
    type: Type
}

enum Type {
    TInt;
    TFloat;
    TFunction;
    TBool;
    TAny;
    TString;
    TCustom(c:String);
}