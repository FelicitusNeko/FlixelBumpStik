package;

import openfl.display.Sprite;
#if final
import state.MenuState as GoState;
#elseif debug
import state.APEntryState as GoState;
#else
import components.classic.ClassicGameState as GoState;
#end

typedef I18nFunction = (String, ?Map<String, Dynamic>) -> String;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new BumpStikGame(0, 0, GoState));
	}
}
