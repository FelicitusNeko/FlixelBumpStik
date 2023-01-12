package components.archipelago;

import haxe.DynamicAccess;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;

/** The type of task to be completed. **/
enum APTaskType
{
	/** The pseudotask at the top of the list to indicate the current level. **/
	LevelHeader;

	/** A certain number of points must be obtained this game. **/
	Score;

	/** A certain number of points must be obtained across all games this level. **/
	LevelScore;

	/** A certain number of points must be obtained across all games this session. **/
	TotalScore;

	/** A certain number of bumpers must be cleared this game. **/
	Cleared;

	/** A certain number of bumpers must be cleared across all games this level. **/
	LevelCleared;

	/** A certain number of bumpers must be cleared across all games this session. **/
	TotalCleared;

	/** A combo of a certain number of bumpers must be formed. **/
	Combo;

	/** A chain of a certain length must be formed. **/
	Chain;

	/** A certain number of Treasure Bumpers must be cleared across all games this session. **/
	Treasures;

	/** A certain number of Bonus Boosters must be cleared across all games this session. **/
	Boosters;

	/** A certain number of Hazard Bumpers must be cleared across all games this session. **/
	Hazards;

	/** An All Clear must be obtained with at least a certain number of colors. **/
	AllClear;
}

/** The definition for an Archipelago check task. **/
typedef IAPTask =
{
	/** The type of task. **/
	var type:APTaskType;

	/** The current goal number for this task. **/
	var goals:Array<Int>;

	/** The index of the current goal. **/
	var goalIndex:Int;

	/** The current number achieved for this task. **/
	var current:Int;

	/** The UI text for the task list. **/
	var uiText:FlxUIText;
}

/** The implementation for an Archipelago check task. **/
@:forward(type, goals, uiText)
abstract APTask(IAPTask) from IAPTask
{
	/** The index of the current goal. **/
	public var goalIndex(get, set):Int;

	/** The current number achieved for this task. **/
	public var current(get, set):Int;

	/** The current goal for this task. **/
	public var curGoal(get, never):Int;

	/** The number of goals to achieve for this task.**/
	public var goalCount(get, never):Int;

	/** Whether this task has been completed. **/
	public var complete(get, never):Bool;

	/** The number of goals left to clear to complete the task. **/
	public var goalsLeft(get, never):Int;

	inline function get_goalIndex()
		return this.goalIndex;

	inline function set_goalIndex(value)
	{
		if (value < 0)
			value = 0;
		if (value > goalCount)
			value = goalCount;
		return this.goalIndex = value;
	}

	inline function get_current()
		return this.current;

	function set_current(value)
	{
		if (value > this.current)
		{
			this.current = value;
			if (this.uiText != null)
				this.uiText.color = complete ? FlxColor.LIME : FlxColor.WHITE;
		}
		return this.current;
	}

	@:arrayAccess
	inline function getGoalByIndex(index)
		return this.goals[index];

	inline function get_curGoal()
		return this.goals[complete ? goalCount - 1 : this.goalIndex];

	inline function get_goalCount()
		return this.goals.length;

	inline function get_complete()
		return this.goalIndex == this.goals.length;

	inline function get_goalsLeft()
		return complete ? 0 : goalCount - goalIndex;

	/** Serializes the data. **/
	public inline function serialize()
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["type"] = this.type;
		retval["goals"] = this.goals;
		retval["goalIndex"] = this.goalIndex;
		retval["current"] = this.current;

		return retval;
	}

	/**
		Forces completion of the current task step.
		@return Whether the goal index has advanced. `false` if it was already complete.
	**/
	public inline function force()
		return switch (complete)
		{
			case true: false;
			case false:
				goalIndex++;
				true;
		}

	/**
		Forces completion of the entire task.
		@return Whether the goal index has advanced to the end of the task. `false` if it was already complete.
	**/
	public inline function forceComplete()
		return switch (complete)
		{
			case true: false;
			case false:
				goalIndex = goalCount;
				true;
		}

	/** Converts the task to its base data structure, stripping `uiText` in the process. **/
	@:to
	public function toBaseData():IAPTask
		return {
			type: this.type,
			goals: this.goals,
			goalIndex: this.goalIndex,
			current: this.current,
			uiText: null
		};

	@:to
	public function toString()
		return BumpStikGame.g().i18n.tr('game/ap/task/${this.type}', ["current" => current, "goal" => curGoal]) + switch (goalsLeft)
		{
			case 0: BumpStikGame.g().i18n.tr('game/ap/task/goalok');
			case x: BumpStikGame.g().i18n.tr('game/ap/task/left', ["_" => x - 1]);
		};

	/** Creates a new `APTask` from serialized data. **/
	public static function fromSaved(data:DynamicAccess<Dynamic>, uiText:FlxUIText):APTask
		return {
			type: data["type"],
			goals: data["goals"],
			goalIndex: data["goalIndex"],
			current: data["current"],
			uiText: uiText
		};
}
