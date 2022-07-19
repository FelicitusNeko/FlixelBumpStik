package components.archipelago;

import ap.Client;
import ap.PacketTypes.NetworkItem;
import components.classic.ClassicGameState;
import flixel.FlxG;
import flixel.util.FlxColor;
import helder.Set;

/** The color of a bumper in Archipelago mode, for matching purposes. **/
@:enum
abstract APColor(FlxColor) from FlxColor to FlxColor
{
	public static inline var None = FlxColor.GRAY;
	public static inline var Red = 0xffc57683;
	public static inline var Green = 0xff77c578;
	public static inline var Rose = 0xffc991c2;
	public static inline var Beige = 0xffd4a681;
	public static inline var Purple = 0xff7c78bd;
	public static inline var Yellow = 0xffe7ee95;

	@:to
	public inline function toString()
	{
		switch (this)
		{
			case None:
				return "None";
			case Red:
				return "Red";
			case Green:
				return "Green";
			case Rose:
				return "Rose";
			case Beige:
				return "Beige";
			case Purple:
				return "Purple";
			case Yellow:
				return "Yellow";
			default:
				return this.toHexString();
		}
	}
}

abstract APLocation(Int) from Int to Int
{
	static inline var LocationOffset = 595000;

	public static inline var Points250 = 0;
	public static inline var Points500 = 1;
	public static inline var Points750 = 2;
	public static inline var Points1000 = 3;
	public static inline var Points1250 = 4;
	public static inline var Points1500 = 5;
	public static inline var Points1750 = 6;
	public static inline var Points2000 = 7;
	public static inline var Points2250 = 8;
	public static inline var Points2500 = 9;
	public static inline var Points2750 = 10;
	public static inline var Points3000 = 11;
	public static inline var Points3250 = 12;
	public static inline var Points3500 = 13;
	public static inline var Points3750 = 14;
	public static inline var Points4000 = 15;
	public static inline var Combo4 = 16;
	public static inline var Combo5 = 17;
	public static inline var Combo6 = 18;
	public static inline var Chain2 = 19;
	public static inline var Chain3 = 20;
	public static inline var AllClear = 21;
	public static inline var Booster1 = 22;
	public static inline var Booster2 = 23;
	public static inline var Booster3 = 24;
	public static inline var Booster4 = 25;
	public static inline var Booster5 = 26;
	public static inline var ClearedHazards = 27;

	inline function new(value:Int)
		this = value;

	@:from
	public static inline function fromInt(value:Int):APLocation
	{
		return new APLocation(value - LocationOffset);
	}

	@:to
	public inline function toLocation():Int
	{
		return this + LocationOffset;
	}
}

abstract APItem(Int) from Int to Int
{
	static inline var ItemOffset = 595000;

	public static inline var BoardWidth = 0;
	public static inline var BoardHeight = 1;
	public static inline var MinColor = 2;
	public static inline var MaxColor = 3;
	public static inline var StartPaintCan = 4;
	public static inline var BonusBooster = 5;
	public static inline var HazardBumper = 6;
	public static inline var TreasureBumper = 7;

	inline function new(value:Int)
		this = value;

	@:from
	public static inline function fromInt(value:Int):APItem
	{
		return new APItem(value - ItemOffset);
	}

	@:to
	public inline function toItem():Int
	{
		return this + ItemOffset;
	}
}

class APGameState extends ClassicGameState
{
	private var _curWidth = 3;
	private var _curHeight = 3;
	private var _startColors = 2;
	private var _endColors = 3;
	private var _startPaintCans = 0;
	private var _hazardBumpers = 0;

	private var _completedChecks:Set<APLocation>;
	private var _ap:Client;

	public function new(host:String, port:Int, slotName:String, ?password:String)
	{
		_ap = new Client("asdf", "Bumper Stickers", "ws://" + host + ":" + port);

		_ap._hOnSlotRefused = onSlotRefused;
		_ap._hOnItemsReceived = onItemsReceived;

		_ap.ConnectSlot(slotName, password, 0x7);

		super();
	}

	override function create()
	{
		_bg = new BumperGenerator(2, [
			APColor.Red,
			APColor.Green,
			APColor.Rose,
			APColor.Beige,
			APColor.Purple,
			APColor.Yellow
		]);
		_bg.shuffleColors();

		if (_players.length == 0)
			_players.push({
				board: new APBoard(0, 0, _curWidth, _curHeight),
				multStack: [1, 1]
			});

		super.create();
	}

	function restartGame()
	{
		_hud.resetHUD();
		_bg.reset();
		remove(_player.board);

		_bg.shuffleColors();
		_bg.colors = _startColors;
		_hudClassic.paintCans = _startPaintCans;

		_player.board = new APBoard(0, 0, _curWidth, _curHeight);
		_player.multStack[0] = 1;

		// TODO: maybe make a function to prepare the board for use so we don't have to reuse this code
		var mainCamera = FlxG.camera;
		var hudCamera = FlxG.cameras.list[1];

		if (FlxG.width > FlxG.height)
		{
			mainCamera.zoom = Math.min((FlxG.width - hudCamera.width) / _player.board.tWidth, FlxG.height / _player.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_player.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}
		else
		{
			mainCamera.zoom = Math.min(FlxG.width / _player.board.tWidth, (FlxG.height - hudCamera.height) / _player.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_player.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}

		_boardClassic.onRequestGenerate.add(onRequestGenerate);
		_boardClassic.onMatch.add(onMatch);
		_boardClassic.onClear.add(onClear);
		_boardClassic.onLaunchBumper.add(onLaunch);
		_boardClassic.onBumperSelect.add(onBumperSelect);
		_boardClassic.onGameOver.add(() -> FlxG.sound.play(AssetPaths.gameover__wav));

		add(_player.board);
	}

	private function onItemsReceived(items:Array<NetworkItem>)
	{
		for (item in items)
		{
			trace("Item received: " + item);
			switch (cast(item.item, APItem))
			{
				case BoardWidth:
					_curWidth++;
				case BoardHeight:
					_curHeight++;
				case MinColor:
					_startColors++;
				case MaxColor:
					_endColors++;
				case StartPaintCan:
					_startPaintCans++;
					_hudClassic.paintCans++;
				case BonusBooster:
					_player.multStack[1] += .2;
				case HazardBumper:
					// TODO: implement
					_hazardBumpers++;
				case TreasureBumper:
				// TODO: implement
				default:
			}
		}
	}

	private function onSlotRefused(errors:Array<String>)
	{
		// TODO: handle failure to connect
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}
