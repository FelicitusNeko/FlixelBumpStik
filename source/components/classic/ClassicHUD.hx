package components.classic;

import boardObject.Bumper;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
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

	public function new()
	{
		super();

		if (_rightSide)
		{
			_pcButton = new FlxButton(5, 5, "P:0", onPaintCanClick.dispatch);
			_pcButton.allowSwiping = false;
			_pcButton.y = height - _pcButton.height - 5;
			add(_pcButton);
		}

		paintCans = 0;
	}

	function set_paintCans(paintCans:Int):Int
	{
		var displayPaintCans = Math.round(Math.min(paintCans, 9));
		_pcButton.text = "P:" + displayPaintCans;
		_pcButton.alive = paintCans > 0;

		var diff = paintCans - this.paintCans;
		if (diff > 0)
		{
			// trace("Displaying diff of " + diff);
			var plustext = new FlxText(0, 0, 0, "+" + diff, 12);
			plustext.color = FlxColor.YELLOW;
			add(plustext);
			plustext.setPosition(_pcButton.x + (_pcButton.width * Math.random()) - (plustext.width / 2), _pcButton.y);
			FlxTween.tween(plustext, {alpha: 0, y: plustext.y - (plustext.height * 1.5)}, 1, {ease: FlxEase.circOut, onComplete: (_) -> plustext.kill()});
			// trace(plustext);
		}

		return this.paintCans = paintCans;
	}

	override function set_nextBumper(nextBumper:Bumper):Bumper
	{
		function onNextClick(b)
		{
			onNextBumperClick.dispatch(cast(b, Bumper));
		}

		if (this.nextBumper != null)
			this.nextBumper.onClick.remove(onNextClick);
		if (nextBumper != null)
			nextBumper.onClick.add(onNextClick);
		return super.set_nextBumper(nextBumper);
	}
}
