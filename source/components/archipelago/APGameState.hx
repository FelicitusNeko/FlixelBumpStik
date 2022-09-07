package components.archipelago;

import ap.Client;
import ap.PacketTypes.NetworkItem;
import boardObject.Bumper;
import boardObject.archipelago.APHazardPlaceholder;
import components.archipelago.APTask.APTaskType;
import components.classic.ClassicGameState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;

/** The color of a bumper in Archipelago mode, for matching purposes. **/
enum abstract APColor(FlxColor) from FlxColor to FlxColor
{
	var Red = 0xffc57683;
	var Green = 0xff77c578;
	var Rose = 0xffc991c2;
	var Beige = 0xffd4a681;
	var Purple = 0xff7c78bd;
	var Yellow = 0xffe7ee95;

	@:to
	public inline function toString()
		switch (this)
		{
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

/** AP Location definitions. **/
enum abstract APLocation(Int) from Int to Int
{
	var Points250 = 595000;
	var Points500;
	var Points750;
	var Points1000;
	var Points1250;
	var Points1500;
	var Points1750;
	var Points2000;
	var Points2250;
	var Points2500;
	var Points2750;
	var Points3000;
	var Points3250;
	var Points3500;
	var Points3750;
	var Points4000;
	var Combo4;
	var Combo5;
	var Combo6;
	var Chain2;
	var Chain3;
	var AllClear;
	var Booster1;
	var Booster2;
	var Booster3;
	var Booster4;
	var Booster5;
	var ClearedHazards;
	var Treasure1;
	var Treasure2;
	var Treasure3;
	var Treasure4;
	var Treasure5;
	var Treasure6;
	var Treasure7;
	var Treasure8;

	public inline function baseIndex()
		return this - Points250;

	@:op(A >= B)
	public inline function geqInt(val:Int)
		return this >= val;

	@:to
	public inline function toString()
	{
		var baseIndex = baseIndex();
		if (Points4000 >= this)
			return ((baseIndex + 1) * 250) + " Points";
		else if (Combo6 >= this)
			return "Combo " + (this - Combo4 + 4);
		else if (Chain3 >= this)
			return "Chain x" + (this - Chain2 + 2);
		else if (AllClear == this)
			return "All Clear";
		else if (Booster5 >= this)
			return "Booster Bumper " + (this - Booster1 + 1);
		else if (ClearedHazards == this)
			return "Cleared All Hazards";
		else if (Treasure8 >= this)
			return "Treasure Bumper " + (this - Treasure1 + 1);
		else
			return "Unknown";
	}
}

/** AP Item definitions. **/
enum abstract APItem(Int) from Int to Int
{
	var BoardWidth = 595000;
	var BoardHeight;
	var MinColor;
	var MaxColor;
	var StartPaintCan;
	var BonusBooster;
	var HazardBumper;
	var TreasureBumper;

	@:to
	public inline function toString()
		switch (this)
		{
			case BoardWidth:
				return "game/ap/item/width";
			case BoardHeight:
				return "game/ap/item/height";
			case MinColor:
				return "game/ap/item/minColor";
			case MaxColor:
				return "game/ap/item/maxColor";
			case StartPaintCan:
				return "game/ap/item/paintCan";
			case BonusBooster:
				return "game/ap/item/booster";
			case HazardBumper:
				return "game/ap/item/hazard";
			case TreasureBumper:
				return "game/ap/item/treasure";
			default:
				return "game/ap/item/default";
		}
}

/** Keeps track of special bumpers. **/
typedef DeploymentSchedule =
{
	/** This many are queued to be deployed. **/
	var toDeploy:Int;

	/** This many are yet to be cleared. **/
	var toClear:Int;

	/** This many have been cleared. **/
	var cleared:Int;

	/**
		It has been this many turns since one has been deployed since becoming available.
		A special bumper will usually be deployed within ten turns of receipt.
	**/
	var sinceLast:Int;
}

/** A queued toast popup message. **/
typedef QueuedToast =
{
	/** The content of the message. **/
	var message:String;

	/** The background color of the message. **/
	var color:FlxColor;

	/** The amount of time, in milliseconds, to fully display the message. **/
	var delay:Int;
}

class APGameState extends ClassicGameState
{
	/** The Archipelago client. **/
	private var _ap:Client;

	/** The width at which the next game will start. **/
	private var _curWidth = 3;

	/** The height at which the next game will start. **/
	private var _curHeight = 3;

	/** The number of colors with which the next game will start. **/
	private var _startColors = 2;

	/** The maximum number of colors the next came can reach. **/
	private var _endColors = 3;

	/** The number of Paint Cans with which the next game will start. **/
	private var _startPaintCans = 0;

	/** Scheduling data for special bumpers. **/
	private var _schedule:Map<String, DeploymentSchedule> = [];

	/** The top score achieved this multiworld. Used for determining checks to send. **/
	private var _topScore = 0;

	/** The most clears achieved this multiworld. Used for determining checks to send. **/
	private var _topBlock = 0;

	/** The top chain achieved this multiworld. Used for determining checks to send. **/
	private var _topChain = 0;

	/** The top combo achieved this multiworld. Used for determining checks to send. **/
	private var _topCombo = 0;

	/** The number of All Clears achieved this multiworld. Used for determining checks to send. **/
	private var _allClears = 0;

	/** The schedule randomiser for this multiworld. **/
	private var _rng = new FlxRandom();

	private var _generalCamera:FlxCamera;

	private var _curToast:APToast = null;

	private var _toastQueue:Array<QueuedToast> = [];

	private var _itemBuffer:Array<NetworkItem> = [];

	private var _boardAP(get, never):APBoard;

	private var _hudAP(get, never):APHud;

	public function new(ap:Client, slotData:Dynamic)
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

		_ap = ap;
		_ap._hOnItemsReceived = onItemsReceived;

		for (type in ["booster", "hazard", "treasure"])
			_schedule.set(type, {
				toDeploy: 0,
				toClear: 0,
				cleared: 0,
				sinceLast: 0
			});

		super();

		_bg.colors = _startColors;
		_bg.colorLimit = _endColors;

		_nextColor = 50;
		_nextColorEvery = 50;
	}

	inline function get__hudAP()
		return cast(_hud, APHud);

	inline function get__boardAP()
		return cast(_player.board, APBoard);

	override function create()
	{
		// TODO: load the game, if a save file exists

		if (_players.length == 0)
			_players.push({
				board: new APBoard(0, 0, _curWidth, _curHeight),
				multStack: [.8, 1]
			});

		_hud = new APHud();
		_hudAP.addTask(LevelHeader, [1]);
		_hudAP.addTask(Score, [250, 500, 750, 1000]);
		_hudAP.addTask(TotalScore, [2000]);
		_hudAP.addTask(Combo, [4]);

		super.create();

		_generalCamera = FlxG.cameras.add(new FlxCamera(0, 0, FlxG.width, FlxG.height), false);
		_generalCamera.bgColor = FlxColor.TRANSPARENT;

		// _hud.onScoreChanged.add(onScoreChanged);
		_hudClassic.paintCans = _startPaintCans;
		_hudClassic.paintCansIncrementStep = 0;
		_hudAP.onTaskCleared.add(onTaskComplete);

		if (_itemBuffer.length > 0)
		{
			onItemsReceived(_itemBuffer);
			_itemBuffer = [];
			restartGame();
		}

		FlxG.autoPause = false;
	}

	override function destroy()
	{
		// TODO: save the game
		FlxG.autoPause = true;
		super.destroy();
	}

	function pushToast(message:String, color = FlxColor.WHITE, delay = 2000)
	{
		var queueEmpty = _toastQueue.length == 0;
		_toastQueue.push({
			message: message,
			color: color,
			delay: delay
		});
		if (queueEmpty && _curToast == null)
			popToast();
	}

	function popToast()
	{
		if (_curToast != null)
		{
			remove(_curToast);
			_curToast.destroy();
		}
		if (_toastQueue.length > 0)
		{
			var queuedMsg = _toastQueue.shift();
			_curToast = new APToast(0, FlxG.height, queuedMsg.message, queuedMsg.color, queuedMsg.delay);
			_curToast.onFinish.add(popToast);
			_curToast.camera = _generalCamera;
			_curToast.screenCenter(X);
			_curToast.slideIn();
			add(_curToast);
		}
		else
			_curToast = null;
	}

	/** Resets the game state and starts a new board without affecting multiworld stats. **/
	function restartGame()
	{
		remove(_player.board);
		_jackpot = 0;

		_bg.reset();
		_bg.shuffleColors();
		_bg.colors = _startColors;
		_bg.colorLimit = _endColors;

		_hudClassic.paintCanStartThreshold = 1000 + (_startPaintCans * 500);
		_hud.resetHUD();
		_hudClassic.paintCans = _startPaintCans;
		_hudClassic.paintCansIncrementStep = (_curWidth + _curHeight - 6) * 500;

		_player.board = new APBoard(0, 0, _curWidth, _curHeight);
		_player.multStack[0] = _startColors == 2 ? .8 : 1;

		for (schedule in _schedule)
		{
			schedule.toDeploy = schedule.toClear;
			schedule.sinceLast = 0;
		}

		if (_paintCanBumper != null)
		{
			_paintCanBumper.destroy();
			_paintCanBumper = null;
			_paintCanCancelButton.destroy();
			_paintCanCancelButton = null;
		}

		prepareBoard();
	}

	/** Called by HUD when score changes. **/
	// private function onScoreChanged(score:Int)
	// {
	// 	if (score > _topScore)
	// 	{
	// 		var checks:Array<Int> = [];
	// 		for (scan in (Math.floor(_topScore / 250) + 1)...17)
	// 		{
	// 			if (score > scan * 250)
	// 				checks.push(APLocation.Points250 + scan - 1);
	// 		}
	// 		if (checks.length > 0)
	// 			_ap.LocationChecks(checks);
	// 		_topScore = score;
	// 	}
	// }

	/** Called by AP client when an item is received. **/
	private function onItemsReceived(items:Array<NetworkItem>)
	{
		if (_players.length == 0)
			_itemBuffer = _itemBuffer.concat(items);
		else
			for (itemObj in items)
			{
				var item:APItem = itemObj.item;
				// trace("Item received: " + item);
				pushToast(_t("game/ap/received", ["item" => _t(item)]), FlxColor.CYAN);
				switch (item)
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
						_schedule["booster"].toDeploy++;
						_schedule["booster"].toClear++;
					case HazardBumper:
						_schedule["hazard"].toDeploy++;
						_schedule["hazard"].toClear++;
					case TreasureBumper:
						_schedule["treasure"].toDeploy++;
						_schedule["treasure"].toClear++;
					default:
						trace("Item ID:" + itemObj.item);
				}
			}
	}

	private function onTaskComplete(task:APTaskType, goal:Int, current:Int)
	{
		// TODO: here's where we actually send checks
		trace("Task complete", task, '$current/$goal');
	}

	/** Called when the board requests a bumper to be generated. Usually when it goes into Idle state. **/
	override function onRequestGenerate()
	{
		if (_boardClassic.bCount <= 0 && _jackpot > 0)
			_hudAP.updateTask(AllClear, _bg.colors);
		// if (++_allClears == 1)
		// 	_ap.LocationChecks([APLocation.AllClear]);

		var prevBumper = _hud.nextBumper;
		super.onRequestGenerate();
		var newBumper = _hud.nextBumper;
		if (newBumper != null && newBumper != prevBumper)
		{
			for (key => schedule in _schedule)
			{
				if (schedule.toDeploy <= 0)
					continue;
				if (_rng.bool((++schedule.sinceLast) * 10))
				{
					schedule.sinceLast = 0;
					schedule.toDeploy--;
					switch (key)
					{
						case "booster":
							newBumper.addFlair("booster", new FlxSprite(0, 0).loadGraphic(AssetPaths.BoosterFlair__png));
						case "treasure":
							newBumper.addFlair("treasure", new FlxSprite(0, 0).loadGraphic(AssetPaths.TreasureFlair__png));
						case "hazard":
							var emptyPos = _boardClassic.getRandomSpace(true);
							if (emptyPos != null)
								_boardClassic.putObstacleAt(emptyPos[0], emptyPos[1], new APHazardPlaceholder(0, 0, _bg.generateColor(true), _boardClassic));
					}
					if (newBumper.flairCount > 0)
						break;
				}
			}
		}
	}

	/** Called when a match is formed. **/
	override function onMatch(chain:Int, combo:Int, bumpers:Array<Bumper>)
	{
		for (bumper in bumpers)
			if (bumper.hasFlair("booster"))
				_player.multStack[1] += .2;

		super.onMatch(chain, combo, bumpers);

		_hudAP.updateTask(Chain, chain);
		_hudAP.updateTask(Combo, combo);

		// var checks:Array<Int> = [];
		// if (_topChain <= 3)
		// 	while (_topChain < chain)
		// 		if (++_topChain > 1 && _topChain < 4)
		// 			checks.push(APLocation.Chain2 + _topChain - 2);
		// if (_topCombo <= 6)
		// 	while (_topCombo < combo)
		// 		if (++_topCombo > 3 && _topCombo < 7)
		// 			checks.push(APLocation.Combo4 + _topCombo - 4);
		// if (checks.length > 0)
		// 	_ap.LocationChecks(checks);
	}

	/** Called when a bumper is cleared. **/
	override function onClear(chain:Int, bumper:Bumper)
	{
		for (key => schedule in _schedule)
		{
			if (bumper.hasFlair(key))
			{
				schedule.toClear--;
				switch (key)
				{
					case "treasure":
						_hudAP.updateTask(Treasures, ++schedule.cleared);
					// if (schedule.cleared++ < 8)
					// 	_ap.LocationChecks([APLocation.Treasure1 + schedule.cleared - 1]);
					case "booster":
						_hudAP.updateTask(Boosters, ++schedule.cleared);
					// if (schedule.cleared++ < 5)
					// 	_ap.LocationChecks([APLocation.Booster1 + schedule.cleared - 1]);
					case "hazard":
						_hudAP.updateTask(Hazards, ++schedule.cleared);
						// if (++schedule.cleared == 3)
						// 	_ap.LocationChecks([APLocation.ClearedHazards]);
				}
			}
		}

		super.onClear(chain, bumper);
	}

	/** Called by the board when the board is jammed and the game is over. **/
	override function onGameOver(animDone:Bool)
	{
		if (animDone)
			restartGame();
		else
			super.onGameOver(animDone);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}
