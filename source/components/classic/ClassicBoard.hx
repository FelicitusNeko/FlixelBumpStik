package components.classic;

import boardObject.Bumper;
import lime.app.Event;

class ClassicBoard extends Board
{
	public var onBumperSelect(default, null) = new Event<Bumper->Void>();

	private var _selectedBumper:Bumper = null;

	public function startPaint()
	{
		for (launcher in _launchers)
			launcher.enabled = false;
		_fsm.activeState = fsmPaintSelect;
	}

	inline public function endPaint()
	{
		_fsm.activeState = fsmChecking;
	}

	private function fsmPaintSelect(elapsed:Float)
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
			_selectedBumper = bumperAtPoint(position);
		if (justReleased && _selectedBumper != null && bumperAtPoint(position) == _selectedBumper)
		{
			onBumperSelect.dispatch(_selectedBumper);
			_selectedBumper = null;
			_fsm.activeState = fsmChecking;
		}
	}
}
