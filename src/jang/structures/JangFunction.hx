package jang.structures;

import jang.runtime.Scope;
import jang.structures.Expr;

typedef JangFunction = {
    body: Array<ExprInfo>,
    args: Array<Argument>,
    type: Type,
    closure: Scope
}