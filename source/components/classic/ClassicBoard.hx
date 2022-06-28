package components.classic;

import boardObject.BoardObject;
import boardObject.Bumper;
import flixel.FlxG;
import lime.app.Event;
#if mobile
import flixel.math.FlxPoint;
#end

class ClassicBoard extends Board
{
	public var onBumperSelect(default, null) = new Event<Bumper->Void>();

	private var _selectedBumper:Bumper = null;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		_csm.addState("painting", null);

		_csm.set("initial", "paint", "painting");
		_csm.set("painting", "cancel", "initial");
		_csm.set("painting", "painted", "checking");
	}

	public function startPaint()
	{
		for (launcher in _launchers)
			launcher.enabled = false;
		// _csm.activeState = smPaintSelect;
		_csm.chain("paint");
	}

	inline public function endPaint(cancel = false)
	{
		// _csm.activeState = smChecking;
		_csm.chain(cancel ? "cancel" : "painted");
	}

	override function onClickBumper(obj:BoardObject)
	{
		if (_csm.is("painting") && Std.isOfType(obj, Bumper))
			onBumperSelect.dispatch(cast(obj, Bumper));
	}
}
