package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;

/** The Bumper Stickers base game instance. **/
class BumpStikGame extends FlxGame
{
	/** _Read-only._ The current save version. Earlier saves than this may be converted or deleted. **/
	#if debug
	public static final curSaveVer = -1;
	#else
	public static final curSaveVer = 2;
	#end

	/** _Read-only._ The internationalization/strings manager for the game. **/
	public var i18n(default, null):I18nManager;

	public function new(GameWidth:Int = 0, GameHeight:Int = 0, ?InitialState:Class<FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60,
			DrawFramerate:Int = 60, SkipSplash:Bool = false, StartFullscreen:Bool = false)
	{
		// super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullscreen);
		super(GameWidth, GameHeight, InitialState);

		i18n = new I18nManager();
	}

	/** Casts the current FlxGame to a BumpStikGame. **/
	public static inline function g()
		return cast(FlxG.game, BumpStikGame);

	/** Converts degrees to radians. **/
	public static inline function DegRad(deg:Float):Float
		return deg * Math.PI / 180;
}
