class Obj {
    public var x(default, set):Float;
    public static var value(default, set):String;
    public function new(x:Float, y:Float) {
        trace(x, y);
        this.x = x;
    }

    public function aeae(msg:String) {
        trace(msg + ' $x');
    }

    function set_x(v:Float):Float {
        trace(v);
        return x = v;
    }

    static  function set_value(v:String):String {
        trace(v);
        return value = v;
    }
}