package components.archipelago;

import haxe.DynamicAccess;
import haxe.Serializer;
import haxe.Unserializer;
import ap.Client;
import ap.PacketTypes.ClientStatus;
import ap.PacketTypes.NetworkItem;
import boardObject.Bumper;
import boardObject.archipelago.APHazardPlaceholder;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxRandom;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import state.MenuState;
import utilities.DeploymentSchedule;
import components.archipelago.APTaskType;
import components.classic.ClassicGameState;
import components.dialogs.DialogBox;

/** The color of a bumper in Archipelago mode, for matching purposes. **/
private enum abstract APColor(FlxColor) from FlxColor to FlxColor
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
private enum abstract APLocation(Int) from Int to Int
{
	var L1Score250 = 595000;
	var L1Score500;
	var L1Score750;
	var L1Score1000;
	var L1LScore500;
	var L1LScore1000;
	var L1LScore1500;
	var L1LScore2000;
	var L1LBumpers25;
	var L1LBumpers50;
	var L1LBumpers75;
	var L1Combo5;
	var L2Score500;
	var L2Score1000;
	var L2Score1500;
	var L2Score2000;
	var L2LScore1000;
	var L2LScore2000;
	var L2LScore3000;
	var L2LScore4000;
	var L2LBumpers25;
	var L2LBumpers50;
	var L2LBumpers75;
	var L2LBumpers100;
	var L2Combo5;
	var L2Chain2;
	var L3Score800;
	var L3Score1600;
	var L3Score2400;
	var L3Score3200;
	var L3LScore2000;
	var L3LScore4000;
	var L3LScore6000;
	var L3LScore8000;
	var L3LBumpers25;
	var L3LBumpers50;
	var L3LBumpers75;
	var L3LBumpers100;
	var L3LBumpers125;
	var L3Combo5;
	var L3Combo7;
	var L3Chain2;
	var L3AllClear3Col;
	var L4Score1500;
	var L4Score3000;
	var L4Score4500;
	var L4Score6000;
	var L4LScore3000;
	var L4LScore6000;
	var L4LScore9000;
	var L4LScore12000;
	var L4LBumpers25;
	var L4LBumpers50;
	var L4LBumpers75;
	var L4LBumpers100;
	var L4LBumpers125;
	var L4LBumpers150;
	var L4Combo5;
	var L4Combo7;
	var L4Chain2;
	var L4Chain3;
	var L5TScore50k;
	var L5AllHazards;
	var Booster1;
	var Booster2;
	var Booster3;
	var Booster4;
	var Booster5;
	var Treasure1;
	var Treasure2;
	var Treasure3;
	var Treasure4;
	var Treasure5;
	var Treasure6;
	var Treasure7;
	var Treasure8;
	var Treasure9;
	var Treasure10;
	var Treasure11;
	var Treasure12;
	var Treasure13;
	var Treasure14;
	var Treasure15;
	var Treasure16;
	var Treasure17;
	var Treasure18;
	var Treasure19;
	var Treasure20;
	var Treasure21;
	var Treasure22;
	var Treasure23;
	var Treasure24;
	var Treasure25;
	var Treasure26;
	var Treasure27;
	var Treasure28;
	var Treasure29;
	var Treasure30;
	var Treasure31;
	var Treasure32;

	public inline function baseIndex()
		return this - L1Score250;

	@:op(A >= B)
	public inline function geqInt(val:Int)
		return this >= val;

	@:to
	public inline function toString()
	{
		// TODO: new string table for this
		// var baseIndex = baseIndex();
		// if (Points4000 >= this)
		// 	return ((baseIndex + 1) * 250) + " Points";
		// else if (Combo6 >= this)
		// 	return "Combo " + (this - Combo4 + 4);
		// else if (Chain3 >= this)
		// 	return "Chain x" + (this - Chain2 + 2);
		// else if (AllClear == this)
		// 	return "All Clear";
		// else if (Booster5 >= this)
		// 	return "Booster Bumper " + (this - Booster1 + 1);
		// else if (ClearedHazards == this)
		// 	return "Cleared All Hazards";
		// else if (Treasure8 >= this)
		// 	return "Treasure Bumper " + (this - Treasure1 + 1);
		// else
		// 	return "Unknown";
		return "NYI";
	}
}

/** AP Item definitions. **/
private enum abstract APItem(Int) from Int to Int
{
	var Nothing = 595000;
	var ScoreBonus;
	var TaskSkip;
	var StartingTurner;
	var Blank004;
	var StartPaintCan;
	var BonusBooster;
	var HazardBumper;
	var TreasureBumper;
	var RainbowTrap;
	var SpinnerTrap;
	var KillerTrap;

	@:to
	public inline function toString()
		return "game/ap/" + switch (this)
		{
			case ScoreBonus:
				"item/scoreBonus";
			case TaskSkip:
				"item/taskSkip";
			case StartingTurner:
				"item/startTurner";
			case Blank004:
				"item/default";
			case StartPaintCan:
				"item/paintCan";
			case BonusBooster:
				"item/booster";
			case HazardBumper:
				"item/hazard";
			case TreasureBumper:
				"item/treasure";
			case RainbowTrap:
				"trap/rainbow";
			case SpinnerTrap:
				"trap/spinner";
			case KillerTrap:
				"trap/killer";
			default:
				"item/default";
		}
}

/** A queued toast popup message. **/
private typedef QueuedToast = // NOTE: Do we want to move this functionality to core? It could be useful in other places/modes
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

	/** The index of the last item that has been processed. **/
	private var _lastProcessed = -1;

	/** The primary camera where the game board lives. **/
	private var _generalCamera:FlxCamera;

	/** The current popup toast being displayed. **/
	private var _curToast:APToast = null;

	/** The queue of popup toasts to display. **/
	private var _toastQueue:Array<QueuedToast> = [];

	/** The items have been received from the server which have yet to be processed. **/
	private var _itemBuffer:Array<NetworkItem> = [];

	/** Any checks that have been marked to be sent in the next Update call. **/
	private var _checkBuffer:Array<APLocation> = [];

	/** Stores whether a level has been cleared. The level clear sequence will then be fired when a new bumper is requested. **/
	private var _levelClear = false;

	/** Whether the user is attempting to use a Turner. **/
	private var _turnerMode = false; // TODO: probably a better way to do this

	/** The APBoard instance for the current game. **/
	private var _boardAP(get, never):APBoard;

	/** The APHUD instance for the current game. **/
	private var _hudAP(get, never):APHUD;

	/** The APPlayerState instance for the current game. **/
	private var _pAP(get, never):APPlayerState;

	// !------------------------- INSTANTIATION

	public function new(ap:Client, slotData:Dynamic)
	{
		_ap = ap;
		_ap.clientStatus = ClientStatus.READY;
		_ap._hOnItemsReceived = onItemsReceived;

		super();
	}

	override function create()
	{
		super.create();

		{
			var apGames = new FlxSave();
			apGames.bind("apGames");
			var list:Map<String, Float> = apGames.data.list;
			if (list == null)
				list = apGames.data.list = new Map<String, Float>();
			list[gameName] = Date.now().getTime();
			apGames.close();
		}

		if (_pAP.level == 0)
			_pAP.level = 1;

		_generalCamera = FlxG.cameras.add(new FlxCamera(0, 0, FlxG.width, FlxG.height), false);
		_generalCamera.bgColor = FlxColor.TRANSPARENT;

		FlxG.autoPause = false;

		// TODO: Restart Board button
		#if debug
		var test = new FlxButton(0, 0, "Test", () ->
		{
			// goes nowhere does nothing
			_hudAP.taskSkip++;
		});
		_hud.add(test);
		#end
	}

	override function destroy()
	{
		_ap.disconnect_socket();
		FlxG.cameras.remove(_generalCamera);
		_generalCamera.destroy();
		FlxG.autoPause = true;
		super.destroy();
	}

	// !------------------------- PROPERTY HANDLERS

	override function get_gameName()
		return 'ap-${_ap.seed}-${_ap.slotnr}';

	override function get_gameType()
		return "archipelago";

	inline function get__hudAP()
		return cast(_hud, APHUD);

	inline function get__boardAP()
		return cast(_p.board, APBoard);

	inline function get__pAP()
		return cast(_p, APPlayerState);

	// !------------------------- METHODS

	/**
		Pushes a notification toast onto the stack.
		@param message The message to display.
		@param color Optional. The background color for this message. Default is `FlxColor.WHITE`.
		@param delay Optional. The number of milliseconds to display the message. This is the amount of time for which it will be stationary on the screen.
		Default is 2000msec.
	**/
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

	/** Displays the oldest message on the toast stack. **/
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
		remove(_p.board);

		_p.reset();

		if (_paintCanBumper != null)
		{
			_paintCanBumper.destroy();
			_paintCanBumper = null;
			_paintCanCancelButton.destroy();
			_paintCanCancelButton = null;
		}

		prepareBoard();
	}

	// !------------------------- EVENT HANDLERS

	/** Called by AP client when an item is received. **/
	private function onItemsReceived(items:Array<NetworkItem>)
	{
		if (_ap.clientStatus != ClientStatus.PLAYING)
			_itemBuffer = _itemBuffer.concat(items);
		else
			for (itemObj in items)
				if (itemObj.index > _lastProcessed)
				{
					var item:APItem = itemObj.item;
					if (item == Nothing)
						continue;

					// trace("Item received: " + item);
					var substitutes:Map<String, Dynamic> = [];
					switch (item)
					{
						case ScoreBonus:
							var bonus = 200 * Math.round(Math.pow(2, _pAP.level - 1));
							_hudAP.score += bonus;
							substitutes.set("bonus", bonus);
						case TaskSkip:
							_hudAP.taskSkip++;
						case StartingTurner:
							// _startTurners++;
							_hudAP.turners++;
						// case Blank004:
						// this shouldn't happen currently
						case StartPaintCan:
							// _startPaintCans++;
							_hudClassic.paintCans++;
						case BonusBooster:
						// _schedule["booster"].inStock++;
						case HazardBumper:
						// _schedule["hazard"].inStock++;
						case TreasureBumper:
						// _schedule["treasure"].inStock++;
						case RainbowTrap:
							_boardAP.trapTrigger = Rainbow(_bg.colorsInPlay);
						case SpinnerTrap:
							_boardAP.trapTrigger = Spinner;
						case KillerTrap:
							_boardAP.trapTrigger = Killer;
						case x:
							substitutes.set("id", x);
							trace('Unknown item ID received: ${itemObj.item}');
					}
					pushToast(_t("game/ap/received", ["item" => Std.string(_t(item, substitutes))]),
						[RainbowTrap, SpinnerTrap, KillerTrap].contains(item) ? FlxColor.ORANGE : FlxColor.CYAN);

					_lastProcessed = itemObj.index;
				}
	}

	/**
		Called when a task is completed.
		@param id The seconding player's identity string.
		@param level The level number related to the cleared task.
		@param type The type of task.
		@param goal The goal achieved.
		@param current The current value for the goal.
	**/
	private function onTaskComplete(id:String, level:Null<Int>, task:APTaskType, goal:Int, current:Int)
	{
		// TODO: here's where we actually send checks
		trace("Task complete", task, '$current/$goal');

		if (task == LevelHeader)
			_levelClear = true;
		else
		{
			var check:Null<Int> = switch ([task, _pAP.level, goal])
			{
				case [Score, 1, x]:
					L1Score250 + Math.round(x / 250 - 1);
				case [LevelScore, 1, x]:
					L1LScore500 + Math.round(x / 500 - 1);
				case [LevelCleared, 1, x]:
					L1LBumpers25 + Math.round(x / 25 - 1);
				case [Combo, 1, _]:
					L1Combo5;

				case [Score, 2, x]:
					L2Score500 + Math.round(x / 500 - 1);
				case [LevelScore, 2, x]:
					L2LScore1000 + Math.round(x / 1000 - 1);
				case [LevelCleared, 2, x]:
					L2LBumpers25 + Math.round(x / 25 - 1);
				case [Combo, 2, _]:
					L2Combo5;
				case [Chain, 2, _]:
					L2Chain2;

				case [Score, 3, x]:
					L3Score800 + Math.round(x / 800 - 1);
				case [LevelScore, 3, x]:
					L3LScore2000 + Math.round(x / 2000 - 1);
				case [LevelCleared, 3, x]:
					L3LBumpers25 + Math.round(x / 25 - 1);
				case [Combo, 3, 5]:
					L3Combo5;
				case [Combo, 3, 7]:
					L3Combo7;
				case [Chain, 3, 2]:
					L3Chain2;
				case [AllClear, 3, _]:
					L3AllClear3Col;

				case [Score, 4, x]:
					L4Score1500 + Math.round(x / 1500 - 1);
				case [LevelScore, 4, x]:
					L4LScore3000 + Math.round(x / 3000 - 1);
				case [LevelCleared, 4, x]:
					L4LBumpers25 + Math.round(x / 25 - 1);
				case [Combo, 4, 5]: L4Combo5;
				case [Combo, 4, 7]: L4Combo7;
				case [Chain, 4, 2]: L4Chain2;
				case [Chain, 4, 3]: L4Chain3;

				case [TotalScore, 5, _]:
					L5TScore50k;
				case [Hazards, 5, _]:
					L5AllHazards;

				default:
					null;
			}
			if (check != null)
				_checkBuffer.push(check);
		}
	}

	/**
		Called when the state of a connected player's board has changed.
		@param id The seconding player's identity string.
		@param state The current board state's identifier.
	**/
	override function onBoardStateChanged(id:String, state:String)
	{
		super.onBoardStateChanged(id, state);

		var index = _playersv2.map(i -> i.id).indexOf(id);
		if (index >= 0)
			switch (state)
			{
				case "gameover":
					restartGame();
			}
	}

	/** Called when the Paint Can button is clicked. **/
	override function onPaintCanClick()
	{
		if (_turnerMode)
			return;
		super.onPaintCanClick();
	}

	/** Called when the Turner button is clicked. **/
	function onTurnerClick()
	{
		if (_boardAP.state != "initial" || _selectedColor != null || _pAP.turner == 0)
			return;

		if (_paintCanCancelButton == null)
		{
			_paintCanCancelButton = new FlxButton(_boardClassic.center.x
				+ (_boardClassic.bWidth * _boardClassic.sWidth / 2)
				+ 20,
				_boardClassic.center.y
				+ (_boardClassic.bHeight * _boardClassic.sHeight / 2)
				+ 20, "X", onFieldCancel);
			_paintCanCancelButton.loadGraphic(AssetPaths.button__png, true, 20, 20);
			_paintCanCancelButton.scale.set(2, 2);
			_paintCanCancelButton.scrollFactor.set(1, 1);
			add(_paintCanCancelButton);
		}
		else
			_paintCanCancelButton.revive();

		_turnerMode = true;
		_boardAP.selectMode();
	}

	/** Called when the Cancel button is clicked during a Paint Can or Turner event. **/
	override function onFieldCancel()
	{
		if (_turnerMode)
		{
			_paintCanCancelButton.kill();
			_turnerMode = false;
			_boardAP.endTurner(true);
		}
		else
			super.onFieldCancel();
	}

	/** Called when the Task Advance button is clicked. **/
	function onTaskSkipClick()
	{
		if (_boardAP.state == "initial" && !_turnerMode && _selectedColor == null && _pAP.taskSkip > 0)
		{
			var dlg = new TaskSkipSubstate(_boardAP.center);
			dlg.onTaskSkip.add(task ->
			{
				_pAP.taskSkip--;
				_pAP.updateTask(task.type, task.current);
				if (![Treasures, Boosters].contains(task.type))
					onTaskComplete(_p.id, _pAP.level, task.type, task.goals[task.goalIndex - 1], task.current);
				if (_levelClear)
					onRequestGenerate();
			});
			_pAP.loadTaskSkip(dlg);
			openSubState(dlg);
		}
	}

	/**
		Called when a bumper is selected, or the bumper selection is cancelled.
		@param id The sending player's identity string.
		@param bumper The selected bumper.
	**/
	override function onBumperSelect(id:String, bumper:Bumper)
	{
		if (_p.id != id)
			return;

		if (_selectedColor != null)
		{
			_paintCanCancelButton.kill();
			super.onBumperSelect(id, bumper);
		}
		else if (_turnerMode && bumper != _hud.nextBumper)
		{
			_paintCanCancelButton.kill();
			// TODO: allow picking next bumper (probably would require a rework, which is more or less planned)
			var turnerPicker = new TurnerSubstate(bumper.getPosition(), bumper.direction, bumper.bColor);
			turnerPicker.onDialogResult.add(dir ->
			{
				if (dir == null)
					_boardAP.endTurner(true);
				else
				{
					// ???: this code is executing on cancel (could not replicate)
					_hudAP.turners--;
					bumper.direction = dir;
					_boardAP.endTurner();
				}
				_turnerMode = false;
			});
			openSubState(turnerPicker);
		}
	}

	// !------------------------- OVERRIDES (Classic)

	/**
		Called when a `Signal` is received from the player state.
		@param signal The signal string.
	**/
	override function onSignal(signal:String)
		switch (signal)
		{
			case "ap-complete":
				_ap.clientStatus = ClientStatus.GOAL;
				var dlg = new DialogBox(_t("game/ap/goal"), {
					buttons: [
						{
							text: _t("base/dlg/back2menu"),
							result: Custom(() ->
							{
								_queueTo = new MenuState();
								return No;
							})
						},
						{
							text: _t("menu/main/classic"),
							result: Custom(() ->
							{
								_queueTo = new ClassicGameState();
								return Yes;
							})
						}
					],
					camera: _generalCamera
				});
				dlg.closeCallback = () ->
				{
					_ap.Say("!release");
					_ap.Say("!collect");
				}
				openSubState(dlg);
			default:
		}

	// !------------------------- OVERRIDES (Common)

	/** Starts a new game. **/
	override function createGame()
	{
		if (_playersv2.length == 0)
			_playersv2.push(new APPlayerState("ap"));

		_hud = new APHUD();
	}

	/** Connects this game state to the HUD's events. **/
	override function attachHUD()
	{
		super.attachHUD();
		_hudAP.onTurnerClick.add(onTurnerClick);
		_hudAP.onTaskSkipClick.add(onTaskSkipClick);
	}

	/**
		Connects this game state to a player state's events.
		@param state The state to connect to the game state.
	**/
	override function attachPlayer(player)
	{
		super.attachPlayer(player);
		_pAP.onTaskCleared.add(onTaskComplete);
	}

	/**
		Disconnects this game state from a player state's events.
		@param state The state to disconnect from the game state.
	**/
	override function detachPlayer(player)
	{
		super.detachPlayer(player);
	}

	override function update(elapsed:Float)
	{
		if (_queueTo != null)
			_ap.disconnect_socket();
		else
		{
			if (_checkBuffer.length > 0 && _ap.state == SLOT_CONNECTED)
			{
				_ap.LocationChecks(_checkBuffer);
				_checkBuffer = [];
			}
			_ap.poll();
		}

		super.update(elapsed);
	}

	// !------------------------- DEPRECATED

	/**
		Creates the tasks for a level. Also removes any tasks that currently exist.
		@param level The level number to set up.
		@deprecated moving to `APPlayerState`
	**/
	function createLevel(level:Int, dontCreateTasks = false)
	{
		_levelClear = false;
		switch (level)
		{
			case x if (x > 0 && x < 6):
			// temporary measure to avoid breaking before removing entire function

			case 6 | -1: // the game is complete in this case; send a goal condition to the server

			default: // If we don't recognise the level, just default to 99999 score and make it obvious something's wrong
				openSubState(new DialogBox(_t("game/ap/error/levelgen", ["level" => level]), {
					title: _t("base/error"),
					titleColor: FlxColor.fromRGB(255, 127, 127),
					defAccept: Custom(() ->
					{
						_queueTo = new MenuState();
						return Close;
					}),
					defCancel: Custom(() ->
					{
						_queueTo = new MenuState();
						return Close;
					})
				}));
				// _hudAP.addTask(Score, [99999]);
		}
	}

	/**
		Called when the board requests a bumper to be generated. Usually when it goes into Idle state.
		@deprecated move to `APPlayerState` and `onBoardStateChanged`
	**/
	function onRequestGenerate()
	{
		if (_ap.clientStatus == ClientStatus.READY)
		{
			_ap.clientStatus = ClientStatus.PLAYING;
			if (_itemBuffer.length > 0)
			{
				onItemsReceived(_itemBuffer);
				_itemBuffer = [];
			}
		}

		// if (++_allClears == 1)
		// 	_ap.LocationChecks([APLocation.AllClear]);
		if (_levelClear)
		{
			FlxG.sound.play(AssetPaths.levelup__wav);
			pushToast(_t("game/ap/levelcomplete"), FlxColor.LIME, 3000);
			_boardAP.levelClear();
			return;
		}

		// var prevBumper = _hud.nextBumper;
		// super.onRequestGenerate();
		// var newBumper = _hud.nextBumper;
		/*
			if (newBumper != null && newBumper != prevBumper)
			{
				for (key => schedule in _schedule)
				{
					if (schedule.inStock <= 0 || schedule.available <= 0)
						continue;
					if (++schedule.sinceLast < schedule.minDelay)
						continue;
					if (schedule.sinceLast >= schedule.maxDelay || _rng.bool(schedule.eligibleTurns / schedule.maxEligible * 100))
					{
						schedule.sinceLast = 0;
						schedule.inStock--;
						schedule.onBoard++;
						switch (key)
						{
							case "booster":
								newBumper.addFlair("booster");
							case "treasure":
								newBumper.addFlair("treasure");
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
		 */
	}
}
