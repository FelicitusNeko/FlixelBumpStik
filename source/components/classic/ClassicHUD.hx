package components.classic;

import haxe.DynamicAccess;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.app.Event;
import components.common.CommonHUD;
import components.common.CommonPlayerState;

class ClassicHUD extends CommonHUD
{
	/** The button to use a Paint Can. **/
	private var _pcButton:FlxButton;

	/**
		The score target for the next Paint Can.
		@deprecated handled by `ClassicPlayerState` (this var is still used by APHUD)
	**/
	private var _paintCansNext:Int = 1000;

	/**
		How much the score target for the next Paint Can will be incremented when it is hit.
		@deprecated handled by `ClassicPlayerState` (this var is still used by APHUD)
	**/
	private var _paintCansIncrement:Int = 1500;

	/** The current number of available Paint Cans. **/
	public var paintCans(default, set):Int = 0; // NOTE: do we need this? could make PlayerState events report the old value

	/** Event that fires when the Paint Can button is clicked. **/
	public var onPaintCanClick(default, null) = new Event<Void->Void>();

	public function new()
	{
		super();

		if (_rightSide)
		{
			_pcButton = new FlxButton(5, 5, _t("game/classic/paint/count", ["_" => 0]), onPaintCanClick.dispatch);
			_pcButton.allowSwiping = false;
			_pcButton.y = height - _pcButton.height - 5;
			add(_pcButton);
		}

		paintCans = 0;
	}

	function set_paintCans(paintCans:Int):Int
	{
		// var displayPaintCans = Math.round(Math.min(paintCans, 10));
		_pcButton.text = _t("game/classic/paint/count", ["_" => paintCans]);
		_pcButton.alive = paintCans > 0;

		var diff = paintCans - this.paintCans;
		if (diff > 0)
			makeFlyout('+$diff', _pcButton);

		return this.paintCans = paintCans;
	}

	override function attachState(state:CommonPlayerState):Bool
	{
		var retval = super.attachState(state);
		if (retval)
		{
			var clPS = cast(state, ClassicPlayerState);
			clPS.onPaintChanged.add(onPaintChanged);
		}
		return retval;
	}

	override function detachState(state:CommonPlayerState):Bool
	{
		var retval = super.detachState(state);
		if (retval)
		{
			var clPS = cast(state, ClassicPlayerState);
			clPS.onPaintChanged.remove(onPaintChanged);
		}
		return retval;
	}

	function onPaintChanged(id:String, paints:Int)
		if (_connected.contains(id))
			paintCans = paints;

	/**
		Creates an `FlxText` that is animated as to emanate from a given sprite.
		@param text The text to create as a flyout.
		@param from The sprite to emanate from.
		@param foColor *Optional.* The color of the text. Defaults to `FlxColor.YELLOW`.
	**/
	function makeFlyout(text:String, from:FlxSprite, foColor = FlxColor.YELLOW)
	{
		// TODO: this can probably be static (call add(makeFlyout([...])) from parent)
		var flyout = new FlxText(0, 0, 0, text, 12);
		flyout.color = foColor;
		add(flyout);
		flyout.setPosition(from.x + (from.width * Math.random()) - (flyout.width / 2), from.y);
		FlxTween.tween(flyout, {alpha: 0, y: flyout.y - (flyout.height * 1.5)}, 1, {ease: FlxEase.circOut, onComplete: (_) -> flyout.kill()});
	}
}
