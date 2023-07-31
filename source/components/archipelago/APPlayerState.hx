package components.archipelago;

import haxe.Serializer;
import haxe.Unserializer;
import lime.app.Event;
import components.classic.ClassicPlayerState;

class APPlayerState extends ClassicPlayerState
{
	public var onTaskSkipChanged(default, null):Event<(String, Int) -> Void>;
	public var onTurnerChanged(default, null):Event<(String, Int) -> Void>;
	public var onLevelChanged(default, null):Event<(String, Int) -> Void>;

	/** The player's current count of Task Advances. **/
	public var taskSkip(default, set) = 0;

	/** The player's current count of Turners. **/
	public var turner(default, set) = 0;

	public var levelScore(get, never):Int;
	public var levelBlock(get, never):Int;
	public var totalScore(get, never):Int;
	public var totalBlock(get, never):Int;
	public var level(default, set):Int;

	public function new(id:String)
	{
		super(id);
		_bgColorShuffle = true;
	}

	override function init()
	{
		super.init();
		onTaskSkipChanged = new Event<(String, Int) -> Void>();
		onTurnerChanged = new Event<(String, Int) -> Void>();
		onLevelChanged = new Event<(String, Int) -> Void>();
	}

	override function initReg()
	{
		_reg["paint.next"] = 1000;
		_reg["paint.inc"] = 1500;
		_reg["paint.starting"] = 0;
		_reg["turner.starting"] = 0;
		_reg["score.accrued.level"] = 0;
		_reg["score.accured.game"] = 0;
		_reg["block.accrued.level"] = 0;
		_reg["block.accrued.game"] = 0;
	}

	private function set_taskSkip(taskSkip)
	{
		onTaskSkipChanged.dispatch(id, this.taskSkip = taskSkip);
		return this.taskSkip;
	}

	private function set_turner(turner)
	{
		onTurnerChanged.dispatch(id, this.turner = turner);
		return this.turner;
	}

	inline private function get_levelScore()
		return score + _reg["score.accrued.level"];

	inline private function get_levelBlock()
		return block + _reg["block.accrued.level"];

	inline private function get_totalScore()
		return score + _reg["score.accrued.level"] + _reg["score.accrued.game"];

	inline private function get_totalBlock()
		return block + _reg["block.accrued.level"] + _reg["block.accrued.game"];

	private function set_level(level)
	{
		// TODO: set tasks
		switch (this.level = level)
		{
			case x:
				throw 'Invalid level generated (#$x)';
		}
		onLevelChanged.dispatch(id, level);
		return level;
	}

	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
		s.serialize(taskSkip);
		s.serialize(turner);
	}

	@:keep
	override function hxUnserialize(u:Unserializer)
	{
		super.hxUnserialize(u);
		this.taskSkip = u.unserialize();
		this.turner = u.unserialize();
	}
}
