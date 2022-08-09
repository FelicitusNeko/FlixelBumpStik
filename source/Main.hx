package;

import flixel.FlxGame;
import openfl.display.Sprite;
#if debug
import state.APEntryState;
#else
import components.classic.ClassicGameState;
#end

class Main extends Sprite
{
	public function new()
	{
		super();
		#if debug
		addChild(new FlxGame(0, 0, APEntryState));
		#else
		addChild(new FlxGame(0, 0, ClassicGameState));
		#end
	}
}
