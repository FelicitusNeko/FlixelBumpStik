package;

import flixel.FlxGame;
import openfl.display.Sprite;
#if debug
import state.APEntryState;
#else
import components.classic.ClassicGameState;
#end

typedef I18nFunction = (String, ?Map<String, Dynamic>) -> String;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if debug
		addChild(new BumpStikGame(0, 0, APEntryState));
		#else
		addChild(new BumpStikGame(0, 0, ClassicGameState));
		#end
	}
}
