package components.archipelago;

import haxe.Serializer;
import lime.app.Event;
import components.classic.ClassicPlayerState;

class APPlayerState extends ClassicPlayerState
{
	public var onTaskSkipChanged(default, null):Event<(String, Int) -> Void>;
	public var onTurnerChanged(default, null):Event<(String, Int) -> Void>;

	/** The player's current count of Task Advances. **/
	public var taskSkip(default, set) = 0;

	/** The player's current count of Turners. **/
	public var turner(default, set) = 0;

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

	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
	}
}
