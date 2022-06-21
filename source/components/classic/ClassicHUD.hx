package components.classic;

import boardObject.Bumper;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import lime.app.Event;

class ClassicHUD extends StandardHUD
{
	/** The button **/
	private var _pcButton:FlxButton;

	/** The current number of Paint Cans displayed on the HUD. **/
	public var paintCans(default, set):Int;

	/** Event that fires when the Paint Can button is clicked. **/
	public var onPaintCanClick(default, null) = new Event<Void->Void>();

	/** Event that fires when the Next Bumper is clicked. **/
	public var onNextBumperClick(default, null) = new Event<Bumper->Void>();

	private var _nextButton:FlxSpriteButton = null;

	public function new()
	{
		super();

		if (_rightSide)
		{
			_pcButton = new FlxButton(5, 5, "P:0", onPaintCanClick.dispatch);
			_pcButton.allowSwiping = false;
			_pcButton.y = height - _pcButton.height - 5;
			add(_pcButton);
			_pcButton.scrollFactor.set(0, 0);
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

	override function set_nextBumper(nextBumper:Bumper):Bumper
	{
		if (nextBumper != null && _nextButton == null)
		{
			_nextButton = new FlxSpriteButton(width - 5 - nextBumper.width, height - 5 - nextBumper.height, null, () ->
			{
				if (nextBumper != null)
					onNextBumperClick.dispatch(nextBumper);
			});
			_nextButton.makeGraphic(Math.round(nextBumper.width), Math.round(nextBumper.height), FlxColor.fromRGBFloat(0, 0, 0, .2));
			add(_nextButton);
			_nextButton.scrollFactor.set(0, 0);
		}
		return super.set_nextBumper(nextBumper);
	}
}
