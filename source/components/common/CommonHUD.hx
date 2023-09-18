package components.common;

import haxe.DynamicAccess;
import Main.I18nFunction;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import lime.app.Event;

using StringTools;

abstract class CommonHUD extends FlxSpriteGroup
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

	/** Event that fires when the Next Bumper is clicked. **/
	public var onNextBumperClick(default, null) = new Event<Bumper->Void>();

	/** List of player states that are connected. **/
	private var _connected:Array<String> = [];

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
		return _scoreCounter.value = score;

	inline function get_block()
		return _blockCounter.value;

	function set_block(block:Int):Int
		return _blockCounter.value = block;

	// TODO: display bonus on HUD
	inline function set_bonus(bonus:Int):Int
		return score + bonus;

	function set_nextBumper(nextBumper:Bumper):Bumper
	{
		function onNextClick(b)
			onNextBumperClick.dispatch(cast(b, Bumper));

		if (this.nextBumper != null)
		{
			this.nextBumper.onClick.remove(onNextClick);
			remove(this.nextBumper);
		}
		if (nextBumper != null)
		{
			var nextClone = nextBumper.cloneBumper();
			nextClone.onClick.add(onNextClick);
			nextClone.isUIElement = true;
			nextClone.setPosition(width - nextClone.width - 5, height - nextClone.height - 5);
			add(nextClone);
			return this.nextBumper = nextClone;
		}
		else return this.nextBumper = null;
	}

	/**
		Resets the HUD to its starting values.
		@deprecated Stats are to be stored and handled by the player state
	**/
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

	private function scoreChanged(id:String, score:Int)
		if (_connected.contains(id))
			this.score = score;

	private function blockChanged(id:String, block:Int)
		if (_connected.contains(id))
			this.block = block;

	private function bonusSet(id:String, bonus:Int)
		if (_connected.contains(id))
			this.bonus = bonus;

	private function nextChanged(id:String, next:Bumper)
		if (_connected.contains(id))
			this.nextBumper = next;

	/**
		Connects this HUD to a player state's events.
		@param state The state to connect to the HUD.
		@return Whether the operation succeeded. If `false`, the state was most likely already connected.
	**/
	public function connectState(state:CommonPlayerState)
	{
		if (_connected.contains(state.id))
			return false;

		_connected.push(state.id);
		state.onScoreChanged.add(scoreChanged);
		state.onBlockChanged.add(blockChanged);
		state.onBonus.add(bonusSet);
		state.onNextChanged.add(nextChanged);

		return true;
	}

	/**
		Disconnects this HUD from a player state's events.
		@param state The state to disconnect from the HUD.
		@return Whether the operation succeeded. If `false`, the state was most likely not connected.
	**/
	public function disconnectState(state:CommonPlayerState)
	{
		if (!_connected.contains(state.id))
			return false;

		state.onScoreChanged.remove(scoreChanged);
		state.onBlockChanged.remove(blockChanged);
		state.onBonus.remove(bonusSet);
		state.onNextChanged.remove(nextChanged);
		_connected = _connected.filter(i -> i != state.id);

		return true;
	}

	/** @deprecated Stats are to be stored and handled by the player state **/
	public function serialize()
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["score"] = score;
		retval["block"] = block;
		retval["nextBumper"] = nextBumper == null ? null : nextBumper.serialize();

		return retval;
	}

	/** @deprecated Stats are to be stored and handled by the player state **/
	public function deserialize(data:DynamicAccess<Dynamic>)
	{
		score = data["score"];
		block = data["block"];
		nextBumper = Bumper.fromSaved(data["nextBumper"]);
	}
}
