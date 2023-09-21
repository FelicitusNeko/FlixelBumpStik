package components.classic;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Serializer;
import haxe.Unserializer;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.math.FlxPoint;
import lime.app.Event;
import components.common.CommonBoard;
import components.common.CommonPlayerState;

class ClassicPlayerState extends CommonPlayerState
{
	/** Event that fires when count of Paint Cans changes. **/
	public var onPaintChanged(default, null):Event<(String, Int) -> Void>;

	/** Event that fires when a bumper is selected. **/
	public var onBumperSelected(default, null):Event<(String, Bumper) -> Void>;

	/** The player's current count of Paint Cans. **/
	public var paint(default, set) = 0;

	/** The player's current board, as a `ClassicBoard`. **/
	public var cBoard(get, never):ClassicBoard;

	// public function new(id:String)
	// {
	// 	super(id);
	// 	initReg();
	// }

	/** Initializes things like event handlers. **/
	override function init()
	{
		super.init();
		onPaintChanged = new Event<(String, Int) -> Void>();
		onBumperSelected = new Event<(String, Bumper) -> Void>();
	}

	/** Initializes the value registry. **/
	private function initReg()
	{
		_reg["jackpot"] = 0;
		_reg["color.next"] = 100;
		_reg["color.inc"] = 150;
		_reg["color.start"] = 3;
		_reg["color.max"] = 6;
		_reg["paint.next"] = 1000;
		_reg["paint.inc"] = 1500;
		_reg["paint.delay"] = 500;
	}

	override function set_score(score:Int):Int
	{
		var s = super.set_score(score);
		if (s >= _reg["paint.next"])
		{
			FlxG.sound.play(AssetPaths.paintcan__wav);
			paint++;
			_reg["paint.next"] += _reg["paint.inc"];
			_reg["paint.inc"] += _reg["paint.delay"];
		}
		return s;
	}

	private function set_paint(paint)
	{
		onPaintChanged.dispatch(id, this.paint = paint);
		return this.paint;
	}

	inline private function get_cBoard()
		return cast(board, ClassicBoard);

	/**
		Adds to the score based on the multiplier stack.
		@param add The amount of points to be multiplied and added.
		@param isBonus _Optional._ Whether the score being added is a bonus. Default `false`.
		@return The final amount of points being added.
	**/
	override function addScore(add, isBonus = false)
	{
		_reg["jackpot"] += add;
		return super.addScore(add, isBonus);
	}

	/**
		Creates a new board.
		@param force Create a board even if one is present and in progress. Default `false`.
	**/
	public function createBoard(force = false)
	{
		if (force || board == null || board.state == "gameover")
		{
			if (board != null)
				detachBoard();
			board = new ClassicBoard(0, 0);
			attachBoard();
		}
	}

	/** Attaches the player state to its board's events. **/
	override function attachBoard()
	{
		super.attachBoard();
		cBoard.onBumperSelect.add(onInnerBumperSelect);
	}

	/** Detaches the player state from its board's events. **/
	override function detachBoard()
	{
		cBoard.onBumperSelect.remove(onInnerBumperSelect);
		super.detachBoard();
	}

	/** Forwards onBumperSelect events from the board with the player ID. **/
	function onInnerBumperSelect(bumper)
		onBumperSelected.dispatch(id, bumper);

	/** Creates a Paint Can substate. **/
	public function makePaintCanSubstate()
		return new PaintCanSubstate(board.center.subtractPoint(new FlxPoint(next.width, next.height).scale(.5)), _bg.colors, _bg);

	/**
		Evaluate the next turn loop.
		@return The result of evaluating the loop.
	**/
	override public function nextTurn()
	{
		// TODO: make this modular so we can add/remove rules at different priorities
		if (board == null)
			throw new Exception("Turn advanced without board present");
		if (_bg == null)
			throw new Exception("Turn advanced without generator present");
		if (board.state == "gameover" || board.state == "gameoverwait")
			return Kill;
		if (board.bCount <= 0 && _reg["jackpot"] > 0)
		{
			FlxG.sound.play(AssetPaths.allclear__wav);
			var mJackpot = addScore(_reg["jackpot"], true);
			_reg["jackpot"] = 0;

			return Notice(new AllClearSubstate(mJackpot, board.center));
		}
		if (_reg["color.max"] > _bg.colors && _reg["color.next"] <= block)
		{
			FlxG.sound.play(AssetPaths.levelup__wav);
			_reg["color.next"] += _reg["color.inc"];
			return Notice(new NewColorSubstate(_bg.colorOpts[_bg.colors++], board.center));
		}
		return super.nextTurn();
	}

	/** Resets the player state. **/
	override function reset()
	{
		super.reset();
		paint = 0;
	}

	/** Saves the player state to text via Haxe's `Serializer`. **/
	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
		s.serialize(paint);
	}

	// TODO: make boards hxSerializable

	/** Loads the board data. **/
	function deserializeBoard(data:DynamicAccess<Dynamic>):CommonBoard
	{
		var board = new ClassicBoard(0, 0);
		board.deserialize(data);
		return board;
	}

	/** Restores the player state from text via Haxe's `Unserializer`. **/
	@:keep
	override function hxUnserialize(u:Unserializer)
	{
		super.hxUnserialize(u);
		this.paint = u.unserialize();
	}
}
