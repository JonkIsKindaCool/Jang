package jang.errors;

import jang.utils.Printer;

enum abstract JangErrorType(String) {
	var SYNTAX_ERROR = "Syntax Error";
	var RUNTIME_ERROR = "Runtime Error";
}

class JangError {
	public function new(source:String, start:Int, end:Int, line:Int, message:String, type:JangErrorType, ?file:String = "main.jn", ?hint:String) {
		var lines = source.split("\n");
		var lineText = (line > 0 && line <= lines.length) ? lines[line - 1] : "";

		Printer.println('[$type] $file:$line:$start');
		Printer.println(message);
		Printer.println("");
		Printer.println("    " + lineText);

		var underline = "    ";
		for (i in 1...start)
			underline += " ";
		for (i in start...end)
			underline += "^";

		Printer.println(underline);

		if (hint != null)
			Printer.println("Hint: " + hint);

        #if sys
        Sys.exit(1);
        #else
        throw "javascript sucks buddy";
        #end
	}
}
