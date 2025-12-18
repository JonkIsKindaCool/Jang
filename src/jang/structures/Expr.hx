package jang.structures;

enum Expr {
    NumberLiteral(value:Float);
    BooleanLiteral(value:Bool); 
    NullLiteral;
    Identifier(name:String);
    Block(statements:Array<ExprInfo>);
    BinaryOp(left:ExprInfo, op:String, right:ExprInfo);
    Assignment(name:String, right:ExprInfo, isConstant:Bool, type: Type);
    StringLiteral(value:String);
    Field(p:ExprInfo, f:String);
    Call(f:ExprInfo, args:Array<ExprInfo>);
    Top(e:ExprInfo);
    While(c:ExprInfo, b:Array<ExprInfo>);
    New(e:String, args:Array<ExprInfo>);
    Import(p:Array<String>);
    Ender(e:Ender);
    Function(expr:Array<ExprInfo>, args:Array<Argument>, type: Type, ?name:String);
    If(cond:ExprInfo, body:ExprInfo, ?elsE:ExprInfo);
}

typedef ExprInfo = {
    posStart:Int, 
    posEnd:Int,
    line: Int,
    expr:Expr
}

enum Ender {
    Return(e:ExprInfo);
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