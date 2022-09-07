package components.archipelago;

import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;

/** The type of task to be completed. **/
enum APTaskType
{
	/** The pseudotask at the top of the list to indicate the current level. **/
	LevelHeader;

	/** A certain number of points must be obtained this game. **/
	Score;

	/** A certain number of points must be obtained across all games this session. **/
	TotalScore;

	/** A certain number of bumpers must be cleared this game. **/
	Cleared;

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
abstract APTask(IAPTask) from IAPTask
{
	/** The type of task. **/
	public var type(get, never):APTaskType;

	/** The current goal number for this task. **/
	public var goals(get, never):Array<Int>;

	/** The index of the current goal. **/
	public var goalIndex(get, set):Int;

	/** The current number achieved for this task. **/
	public var current(get, set):Int;

	/** The UI text for the task list. **/
	public var uiText(get, never):FlxUIText;

	/** The current goal for this task. **/
	public var curGoal(get, never):Int;

	/** The number of goals to achieve for this task.**/
	public var goalCount(get, never):Int;

	/** Whether this task has been completed. **/
	public var complete(get, never):Bool;

	// inline public function new(type:APTaskType, goals:Array<Int>, uiText:FlxUIText)
	// {
	// 	this.type = type;
	// 	this.goals = goals;
	// 	this.goalIndex = 0;
	// 	this.current = 0;
	// 	this.uiText = uiText;
	// }

	inline function get_type()
		return this.type;

	inline function get_goals()
		return this.goals;

	inline function get_goalIndex()
		return this.goalIndex;

	inline function set_goalIndex(value)
	{
		if (value < 0)
			value = 0;
		if (value + 1 >= goalCount)
			value = goalCount - 1;
		return this.goalIndex = value;
	}

	inline function get_current()
		return this.current;

	function set_current(value)
	{
		var wasComplete = complete;
		this.current = value;
		if (wasComplete != complete)
			this.uiText.color = complete ? FlxColor.LIME : FlxColor.WHITE;
		return this.current;
	}

	inline function get_uiText()
		return this.uiText;

	inline function get_curGoal()
		return this.goals[this.goalIndex];

	inline function get_goalCount()
		return this.goals.length;

	inline function get_complete()
		return this.current >= this.goals[goalCount - 1];
}
