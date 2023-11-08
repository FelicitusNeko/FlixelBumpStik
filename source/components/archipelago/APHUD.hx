package components.archipelago;

import haxe.DynamicAccess;
import haxe.Exception;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.app.Event;
import components.archipelago.APTask;
import components.classic.ClassicHUD;
import components.common.CommonGameState;
import components.common.CommonHUD;
import components.common.CommonPlayerState;

/** Adds Archipelago-specific elements to the Classic mode HUD. **/
class APHUD extends ClassicHUD
{
	/** The task list display component. **/
	private var _taskListbox:FlxUIList;

	/** The list of tasks to clear. **/
	private var _tasks:Array<FlxUIText> = [];

	/** The button to use a Turner. **/
	private var _turnerButton:FlxButton;

	/** The button to use a Task Skip. **/
	private var _skipButton:FlxButton;

	/** The current number of available Turners. **/
	public var turners(default, set):Int = 0;

	/** The current number of available Task Skips. **/
	public var taskSkip(default, set):Int = 0;

	/** Event that fires when the Turner button is clicked. **/
	public var onTurnerClick(default, null) = new Event<Void->Void>();

	/** Event that fires when the Task Skip button is clicked. **/
	public var onTaskSkipClick(default, null) = new Event<Void->Void>();

	// !------------------------- INSTANTIATION

	public function new()
	{
		super();

		if (rightSide)
		{
			var more = "+<X>";
			var listy = _blockCounter.y + _blockCounter.height;
			_taskListbox = new FlxUIList(10, listy, [], width - 20, height - listy - 69, more);

			_turnerButton = new FlxButton(5, 5, _t("game/ap/turner/count", ["_" => 0]), () ->
			{
				if (turners > 0)
					onTurnerClick.dispatch();
			});
			_turnerButton.allowSwiping = false;
			_turnerButton.y = _pcButton.y - _turnerButton.height;

			_skipButton = new FlxButton(5, 5, _t("game/ap/skip/count", ["_" => 0]), () ->
			{
				if (taskSkip > 0)
					onTaskSkipClick.dispatch();
			});
			_skipButton.allowSwiping = false;
			_skipButton.y = _turnerButton.y - _skipButton.height;

			for (i in [_taskListbox, _turnerButton, _skipButton])
				add(i);
		}

		turners = 0;
	}

	// !------------------------- PROPERTY HANDLERS

	function set_turners(turners:Int)
	{
		// var displayTurners = Math.round(Math.min(turners, 10));
		_turnerButton.text = _t("game/ap/turner/count", ["_" => turners]);
		_turnerButton.alive = turners > 0;

		var diff = turners - this.turners;
		if (diff > 0)
			add(CommonHUD.generateFlyout('+$diff', _turnerButton));

		return this.turners = turners;
	}

	function set_taskSkip(taskSkip:Int)
	{
		// var displaySkips = Math.round(Math.min(taskSkip, 10));
		_skipButton.text = _t("game/ap/skip/count", ["_" => taskSkip]);
		_skipButton.alive = taskSkip > 0;

		var diff = taskSkip - this.taskSkip;
		if (diff > 0)
			add(CommonHUD.generateFlyout('+$diff', _skipButton));

		return this.taskSkip = taskSkip;
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
			trace("APHUD.attachState");

			var apPS = cast(state, APPlayerState);
			apPS.onLevelChanged.add(onLevelChanged);
			apPS.onTurnerChanged.add(onTurnerChanged);
			apPS.onTaskSkipChanged.add(onTaskSkipChanged);
			apPS.onTaskUpdated.add(onTaskUpdated);
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
			var apPS = cast(state, APPlayerState);
			apPS.onLevelChanged.remove(onLevelChanged);
			apPS.onTurnerChanged.remove(onTurnerChanged);
			apPS.onTaskSkipChanged.remove(onTaskSkipChanged);
			apPS.onTaskUpdated.remove(onTaskUpdated);
		}
		return retval;
	}

	// !------------------------- EVENT HANDLERS

	function onLevelChanged(id:String, level:Int, tasks:Array<APTaskV2>)
	{
		trace("APHUD.onLevelChanged");

		if (!_connected.contains(id))
			return;

		trace("connect!");

		_taskListbox.clear();
		for (task in _tasks)
			task.destroy();

		_tasks = tasks.map(i -> new FlxUIText(0, 0, 0, i));
		for (x => task in _tasks)
		{
			if (tasks[x].type == LevelHeader)
			{
				task.size += 4;
				task.alignment = CENTER;
			}
			_taskListbox.add(task);
		}
	}

	inline function onTurnerChanged(id:String, count:Int)
		if (_connected.contains(id))
			turners = count;

	inline function onTaskSkipChanged(id:String, count:Int)
		if (_connected.contains(id))
			taskSkip = count;

	inline function onTaskUpdated(id:String, index:Int, task:APTaskV2)
	{
		if (!_connected.contains(id))
			return;
		_tasks[index].text = task;
		_tasks[index].color = task.complete ? FlxColor.LIME : FlxColor.WHITE;
	}
}
