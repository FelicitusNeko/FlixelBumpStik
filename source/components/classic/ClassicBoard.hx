package components.classic;

import boardObject.BoardObject;
import boardObject.Bumper;
import lime.app.Event;
import components.common.Board;

class ClassicBoard extends Board
{
	public var onBumperSelect(default, null) = new Event<Bumper->Void>();

	private var _selectedBumper:Bumper = null;

	public function new(x:Float, y:Float, bWidth = 5, bHeight = 5)
	{
		super(x, y, bWidth, bHeight);

		_csm.addState("selecting", null);

		_csm.set("initial", "selectmode", "selecting");
		_csm.set("selecting", "cancel", "initial");
		_csm.set("selecting", "painted", "checking");
	}

	public function selectMode()
	{
		for (launcher in _launchers)
			launcher.enabled = false;
		_csm.chain("selectmode");
	}

	public function endPaint(cancel = false)
	{
		if (cancel)
			for (launcher in _launchers)
				launcher.enabled = true;
		else
			_dontAdvanceTurn = true;
		_csm.chain(cancel ? "cancel" : "painted");
	}

	override function onClickBumper(obj:BoardObject)
	{
		if (_csm.is("selecting") && Std.isOfType(obj, Bumper))
			onBumperSelect.dispatch(cast(obj, Bumper));
	}
}
