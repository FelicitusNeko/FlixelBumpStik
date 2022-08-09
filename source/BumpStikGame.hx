package;

import flixel.FlxG;
import flixel.FlxGame;

class BumpStikGame extends FlxGame
{
	public var i18n:I18nManager;

	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<flixel.FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60,
			DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);

		i18n = new I18nManager();
	}

	public static inline function g()
	{
		return cast(FlxG.game, BumpStikGame);
	}
}
