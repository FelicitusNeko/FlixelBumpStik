package components.archipelago;

import haxe.DynamicAccess;
import haxe.Serializer;
import haxe.Unserializer;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;

/** The definition for an Archipelago check task. **/
typedef IAPTaskV2 =
{
	/** The type of task. **/
	var type:APTaskType;

	/** The current goal number for this task. **/
	var goals:Array<Int>;

	/** The index of the current goal. **/
	var goalIndex:Int;

	/** The current number achieved for this task. **/
	var current:Int;
}

/** The implementation for an Archipelago check task. **/
@:forward(type, goals)
abstract APTaskV2(IAPTaskV2) from IAPTaskV2 to IAPTaskV2
{
	/** The index of the current goal. **/
	public var goalIndex(get, set):Int;

	/** The current number achieved for this task. **/
	public var current(get, set):Int;

	/** _Read-only._ The current goal for this task. **/
	public var curGoal(get, never):Int;

	/** _Read-only._ The number of goals to achieve for this task.**/
	public var goalCount(get, never):Int;

	/** _Read-only._ Whether this task has been completed. **/
	public var complete(get, never):Bool;

	/** _Read-only._ The number of goals left to clear to complete the task. **/
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
			this.current = value;

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

	/**
		Forces completion of the task.
		@param finish Complete the entire task. Defaults to `false`, where it will complete only one step.
		@return Whether the goal index has advanced. `false` if it was already complete.
	**/
	public inline function force(finish = false)
		return switch (complete)
		{
			case true: false;
			case false:
				finish ? (goalIndex = goalCount) : goalIndex++;
				true;
		}

	@:to
	public function toString()
	{
		var t = BumpStikGame.g().i18n.tr;
		return t('game/ap/task/${this.type}', ["current" => current, "goal" => curGoal]) + switch (goalsLeft)
		{
			case 0: t('game/ap/task/goalok');
			case x: t('game/ap/task/left', ["_" => x - 1]);
		};
	}

	@:keep
	private function hxSerialize(s:Serializer)
	{
		s.serialize(this.type);
		s.serialize(this.goals);
		s.serialize(this.goalIndex);
		s.serialize(this.current);
	}

	@:keep
	private function hxUnserialize(u:Unserializer)
	{
		this.type = u.unserialize();
		this.goals = u.unserialize();
		this.goalIndex = u.unserialize();
		this.current = u.unserialize();
	}
}
