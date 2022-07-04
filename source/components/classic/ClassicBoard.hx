package components.classic;

import boardObject.BoardObject;
import boardObject.Bumper;
import lime.app.Event;

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
		_csm.chain("paint");
	}

	inline public function endPaint(cancel = false)
	{
		if (cancel)
			for (launcher in _launchers)
				launcher.enabled = true;
		_csm.chain(cancel ? "cancel" : "painted");
	}

	override function onClickBumper(obj:BoardObject)
	{
		if (_csm.is("painting") && Std.isOfType(obj, Bumper))
			onBumperSelect.dispatch(cast(obj, Bumper));
	}
}
