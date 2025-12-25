package jang.structures;

import jang.structures.ClassDeclaration;
import jang.runtime.Interpreter.JangValue;

enum Expr {
	NumberLiteral(value:Float);
	BooleanLiteral(value:Bool);
	NullLiteral;
	Identifier(name:String);
	Block(statements:Array<ExprInfo>);
	BinaryOp(left:ExprInfo, op:String, right:ExprInfo);
	Assignment(name:String, right:ExprInfo, isConstant:Bool, type:Type);
	StringLiteral(value:String);
	Field(p:ExprInfo, f:String);
	Call(f:ExprInfo, args:Array<ExprInfo>);
	Top(e:ExprInfo);
	While(c:ExprInfo, b:Array<ExprInfo>);
	New(e:String, args:Array<ExprInfo>);
	Ender(e:Ender);
	Function(expr:Array<ExprInfo>, args:Array<Argument>, type:Type, ?name:String);
	If(cond:ExprInfo, body:ExprInfo, ?elsE:ExprInfo);
	Object(fields:Array<ObjectField>);
	Array(inner:Array<ExprInfo>);
	Index(p:ExprInfo, i:ExprInfo);
	Class(c:ClassDeclaration);
	Import(path:String, targets:Array<String>);
	For(variables:Array<String>, iterator:ExprInfo, body:Array<ExprInfo>);
	Try(body:Array<ExprInfo>, ?catchContent:CatchContent);
}

typedef CatchContent = {
	name:String,
	type:Type,
	body:Array<ExprInfo>
}

typedef ExprInfo = {
	posStart:Int,
	posEnd:Int,
	line:Int,
	expr:Expr
}

enum Ender {
	Return(e:ExprInfo);
	Break;
	Continue;
	Throw(e:ExprInfo);
}

typedef Argument = {
	name:String,
	type:Type
}

enum Type {
	TInt;
	TFloat;
	TFunction;
	TArray;
	TObject;
	TBool;
	TAny;
	TString;
	TCustom(c:String);
}

typedef ObjectField = {
	name:String,
	value:ExprInfo
}
