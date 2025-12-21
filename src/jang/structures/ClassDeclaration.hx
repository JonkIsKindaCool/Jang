package jang.structures;

import jang.structures.Expr;

typedef ClassDeclaration = {
    name:String,
    ?extend:String,
    variables:Array<ClassVariable>,
    functions: Array<ClassFunction>
}

typedef ClassVariable = {
    name:String,
    ?value: ExprInfo,
    type: Type,
    behaviour:Array<VariableBehaviour>,
    constant: Bool
}

typedef ClassFunction = {
    name:String,
    type:Type,
    args:Array<Argument>,
    body:Array<ExprInfo>,
    behaviour:Array<VariableBehaviour>
}

enum VariableBehaviour {
    STATIC;
    PRIVATE;
    PUBLIC;
}