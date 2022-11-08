package components;

import Main.I18nFunction;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import lime.app.Event;

using StringTools;

class StandardHUD extends FlxSpriteGroup
{
	/** The counter for the current score. **/
	var _scoreCounter:HUDCounter;

	/** The counter for the current clear count. **/
	var _blockCounter:HUDCounter;

	/** Whether the HUD is displayed on the right side (`true`) or bottom (`false`). **/
	var _rightSide = true;

	/** The current score displayed on the HUD. **/
	public var score(get, set):Int;

	/** The current count of cleared bumpers displayed on the HUD. **/
	public var block(get, set):Int;

	/** Write-only. Assign to both add score and display as a bonus value. **/
	public var bonus(never, set):Int;

	/** The current next bumper displayed on the HUD. **/
	public var nextBumper(default, set):Bumper = null;

	/** Event that fires when the score value changes.**/
	public var onScoreChanged(default, null) = new Event<Int->Void>();

	/** Event that fires when the cleared bumper value changes.**/
	public var onBlockChanged(default, null) = new Event<Int->Void>();

	/** Event that fires when the Next Bumper is clicked. **/
	public var onNextBumperClick(default, null) = new Event<Bumper->Void>();

	/** Retrieve a string based on an i18n key. **/
	private var _t:I18nFunction;

	public function new()
	{
		super(0, 0);
		_t = BumpStikGame.g().i18n.tr;

		_rightSide = FlxG.width > FlxG.height;

		if (_rightSide)
		{
			// TODO: work on getting the size right for different aspect ratios
			var quarterWidth = Math.round(FlxG.width / 4),
				widthRatio = 180 / quarterWidth;

			add(new FlxSprite().makeGraphic(180, Math.ceil(FlxG.height * widthRatio), FlxColor.fromRGBFloat(.1, .1, .8, .5)));

			_scoreCounter = new HUDCounter(25, 40, _t("base/score"));
			_scoreCounter.counterColor = FlxColor.GREEN;
			add(_scoreCounter);

			_blockCounter = new HUDCounter(25, 40 + _scoreCounter.height, _t("base/block"));
			_blockCounter.counterColor = FlxColor.RED;
			add(_blockCounter);
		}
		else
		{
			// TODO: vertical HUD
			// super(0, FlxG.height * .8);
		}
	}

	inline function get_score()
		return _scoreCounter.value;

	function set_score(score:Int):Int
	{
		if (_scoreCounter.value != score)
			onScoreChanged.dispatch(score);
		return _scoreCounter.value = score;
	}

	inline function get_block()
		return _blockCounter.value;

	function set_block(block:Int):Int
	{
		if (_blockCounter.value != block)
			onBlockChanged.dispatch(block);
		return _blockCounter.value = block;
	}

	function set_bonus(bonus:Int):Int
	{
		// TODO: display bonus on HUD
		return score += bonus;
	}

	function set_nextBumper(nextBumper:Bumper):Bumper
	{
		function onNextClick(b)
			onNextBumperClick.dispatch(cast(b, Bumper));

		if (this.nextBumper != null)
		{
			this.nextBumper.onClick.remove(onNextClick);
			remove(this.nextBumper);
			this.nextBumper.isUIElement = false;
		}
		if (nextBumper != null)
		{
			nextBumper.onClick.add(onNextClick);
			nextBumper.isUIElement = true;
			nextBumper.setPosition(width - nextBumper.width - 5, height - nextBumper.height - 5);
			add(nextBumper);
			nextBumper.revive();
		}
		return this.nextBumper = nextBumper;
	}

	/** Resets the HUD to its starting values. **/
	public function resetHUD()
	{
		if (nextBumper != null)
		{
			remove(nextBumper);
			nextBumper = null;
		}
		score = 0;
		block = 0;
	}

	public function serialize()
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["score"] = score;
		retval["block"] = block;
		retval["nextBumper"] = nextBumper == null ? null : nextBumper.serialize();

		return retval;
	}

	public function deseralize(data:DynamicAccess<Dynamic>)
	{
		score = data["score"];
		block = data["block"];
		// nextBumper = Bumper.fromSaved(data["nextBumper"]);
	}
}
