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

		_csm.addState("painting", smPaintSelect);

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

	private function smPaintSelect(elapsed:Float) {}

	private function smPaintSelectV1(elapsed:Float)
	{
		#if mobile
		var touch = FlxG.touches.getFirst();
		var justPressed = false,
			justReleased = false,
			position:FlxPoint = new FlxPoint(0, 0);

		if (touch != null)
		{
			justPressed = touch.justPressed;
			justReleased = touch.justReleased;
			position = touch.getWorldPosition();
		}
		#else
		var justPressed = FlxG.mouse.justPressed;
		var justReleased = FlxG.mouse.justReleased;
		var position = FlxG.mouse.getWorldPosition();
		#end

		if (justPressed)
			_selectedBumper = atPoint(_bumpers, position);
		if (justReleased && _selectedBumper != null && atPoint(_bumpers, position) == _selectedBumper)
		{
			onBumperSelect.dispatch(_selectedBumper);
			_selectedBumper = null;
		}
	}

	override function onClickBumper(obj:BoardObject)
	{
		if (_csm.is("painting") && Std.isOfType(obj, Bumper))
			onBumperSelect.dispatch(cast(obj, Bumper));
	}
}
