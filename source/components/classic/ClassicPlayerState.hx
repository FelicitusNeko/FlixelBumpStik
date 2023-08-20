package components.classic;

import haxe.Serializer;
import haxe.Unserializer;
import lime.app.Event;
import components.common.CommonPlayerState;

class ClassicPlayerState extends CommonPlayerState
{
	/** Event that fires when count of Paint Cans changes. **/
	public var onPaintChanged(default, null):Event<(String, Int) -> Void>;

	/** The player's current count of Paint Cans. **/
	public var paint(default, set) = 0;

	public function new(id:String)
	{
		super(id);
		initReg();
	}

	/** Initializes things like event handlers. **/
	override function init()
	{
		super.init();
		onPaintChanged = new Event<(String, Int) -> Void>();
	}

	/** Initializes the value registry. **/
	private function initReg()
	{
		_reg["color.next"] = 100;
		_reg["color.inc"] = 150;
		_reg["color.start"] = 3;
		_reg["color.max"] = 6;
		_reg["paint.next"] = 1000;
		_reg["paint.inc"] = 1500;
	}

	private function set_paint(paint)
	{
		onPaintChanged.dispatch(id, this.paint = paint);
		return this.paint;
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

	/** Restores the player state from text via Haxe's `Unserializer`. **/
	@:keep
	override function hxUnserialize(u:Unserializer)
	{
		super.hxUnserialize(u);
		this.paint = u.unserialize();
	}
}
