package hud;

import flixel.ui.FlxButton;
import lime.app.Event;

class ClassicHUD extends StandardHUD
{
	/** The button **/
	private var _pcButton:FlxButton;

	/** The current number of Paint Cans displayed on the HUD. **/
	public var paintCans(default, set):Int;

	/** The function to call when the Paint Can button is clicked. **/
	// public var onPaintCanClick:Void->Void = null;
	public var onPaintCanClick(default, null) = new Event<Void->Void>();

	public function new()
	{
		super();

		if (_rightSide)
		{
			_pcButton = new FlxButton(5, 5, "P:0", onPaintCanClick.dispatch);
			// _pcButton.loadGraphic(AssetPaths.button__png, true, 20, 20);
			_pcButton.width = 40;
			_pcButton.allowSwiping = false;
			_pcButton.y = height - _pcButton.height - 5;
			add(_pcButton);
			_pcButton.scrollFactor.set(0, 0);

			trace(_pcButton);
		}

		paintCans = 0;
	}

	function set_paintCans(paintCans:Int):Int
	{
		var displayPaintCans = Math.round(Math.min(paintCans, 9));
		_pcButton.text = "P:" + displayPaintCans;
		_pcButton.alive = paintCans > 0;

		return this.paintCans = paintCans;
	}
}
