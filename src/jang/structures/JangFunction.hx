package jang.structures;

import jang.runtime.Scope;
import jang.structures.Expr;

typedef JangFunction = {
    body: Array<Expr>,
    args: Array<Argument>,
    type: Type,
    closure: Scope
}