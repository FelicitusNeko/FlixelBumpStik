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

	/** The current number of available Paint Cans. **/
	public var paintCans(default, set):Int = 0; // NOTE: do we need this? could make PlayerState events report the old value

	/** Event that fires when the Paint Can button is clicked. **/
	public var onPaintCanClick(default, null) = new Event<Void->Void>();

	// !------------------------- INSTANTIATION

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

	// !------------------------- PROPERTY HANDLERS

	function set_paintCans(paintCans:Int):Int
	{
		// var displayPaintCans = Math.round(Math.min(paintCans, 10));
		_pcButton.text = _t("game/classic/paint/count", ["_" => paintCans]);
		_pcButton.alive = paintCans > 0;

		var diff = paintCans - this.paintCans;
		if (diff > 0)
			add(CommonHUD.generateFlyout('+$diff', _pcButton));

		return this.paintCans = paintCans;
	}

	// !------------------------- OVERRIDES

	/**
		Connects this HUD to a player state's events.
		@param state The state to connect to the HUD.
		@return Whether the operation succeeded. If `false`, the state was most likely already connected.
	**/
	override public function attachState(state:CommonPlayerState):Bool
	{
		var retval = super.attachState(state);
		if (retval)
		{
			var clPS = cast(state, ClassicPlayerState);
			clPS.onPaintChanged.add(onPaintChanged);
		}
		return retval;
	}

	/**
		Disconnects this HUD from a player state's events.
		@param state The state to disconnect from the HUD.
		@return Whether the operation succeeded. If `false`, the state was most likely not connected.
	**/
	override public function detachState(state:CommonPlayerState):Bool
	{
		var retval = super.detachState(state);
		if (retval)
		{
			var clPS = cast(state, ClassicPlayerState);
			clPS.onPaintChanged.remove(onPaintChanged);
		}
		return retval;
	}

	// !------------------------- EVENT HANDLERS

	function onPaintChanged(id:String, paints:Int)
		if (_connected.contains(id))
			paintCans = paints;
}
