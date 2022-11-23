package;

import flixel.FlxG;
import flixel.FlxGame;

/** The Bumper Stickers base game instance. **/
class BumpStikGame extends FlxGame
{
	/** Read-only. The internationalization/strings manager for the game. **/
	public var i18n(default, null):I18nManager;

	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<flixel.FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60,
			DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);

		i18n = new I18nManager();
	}

	/** Casts the current FlxGame to a BumpStikGame. **/
	public static inline function g()
		return cast(FlxG.game, BumpStikGame);

	/** Converts degrees to radians. **/
	public static inline function DegRad(deg:Float):Float
		return deg * Math.PI / 180;
}
