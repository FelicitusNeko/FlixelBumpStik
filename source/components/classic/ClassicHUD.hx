package components.classic;

import boardObject.Bumper;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import lime.app.Event;

class ClassicHUD extends StandardHUD
{
	/** The button to use a Paint Can. **/
	private var _pcButton:FlxButton;

	/** The score target for the next Paint Can. **/
	private var _paintCansNext:Int = 1000;

	/** How much the score target for the next Paint Can will be incremented when it is hit. **/
	private var _paintCansIncrement:Int = 1500;

	/** The current number of available Paint Cans. **/
	public var paintCans(default, set):Int = 0;

	/** The starting score threshold for Paint Cans. **/
	public var paintCanStartThreshold = 1000;

	/** How much higher the next score target for the next Paint Can will be incremented by when it is hit. **/
	public var paintCansIncrementStep:Int = 500;

	/** Event that fires when one or more Paint Cans are earned. **/
	public var onPaintCanGet(default, null) = new Event<Int->Void>();

	/** Event that fires when the Paint Can button is clicked. **/
	public var onPaintCanClick(default, null) = new Event<Void->Void>();

	public function new()
	{
		super();

		if (_rightSide)
		{
			_pcButton = new FlxButton(5, 5, "P:0", () ->
			{
				if (paintCans > 0)
					onPaintCanClick.dispatch();
			});
			_pcButton.allowSwiping = false;
			_pcButton.y = height - _pcButton.height - 5;
			add(_pcButton);
		}

		paintCans = 0;
	}

	override function set_score(score:Int):Int
	{
		var retval = super.set_score(score);

		var plusPaint = 0;
		while (score >= _paintCansNext)
		{
			plusPaint++;
			_paintCansNext += _paintCansIncrement;
			_paintCansIncrement += paintCansIncrementStep;
			trace('Awarding paint can; next at $_paintCansNext');
		}
		if (plusPaint > 0)
		{
			paintCans += plusPaint;
			onPaintCanGet.dispatch(plusPaint);
		}

		return retval;
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

	/** Resets the HUD to its starting values. **/
	public override function resetHUD()
	{
		super.resetHUD();
		paintCans = 0;
		_paintCansNext = paintCanStartThreshold;
		_paintCansIncrement = paintCanStartThreshold + paintCansIncrementStep;
	}

	public override function serialize():DynamicAccess<Dynamic>
	{
		var retval = super.serialize();

		var paintCansDA:DynamicAccess<Int> = {};
		paintCansDA["count"] = paintCans;
		paintCansDA["start"] = paintCanStartThreshold;
		paintCansDA["next"] = _paintCansNext;
		paintCansDA["inc"] = _paintCansIncrement;
		paintCansDA["incStep"] = paintCansIncrementStep;
		retval["paintCans"] = paintCansDA;

		return retval;
	}
}
