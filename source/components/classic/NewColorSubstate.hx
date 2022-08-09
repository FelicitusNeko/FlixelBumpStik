package components.classic;

import boardObject.Bumper;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class NewColorSubstate extends FlxSubState
{
	private var _bumper:Bumper;

	private var _center:FlxPoint;

	private var _delay = 2.0;

	public function new(color:FlxColor, center:FlxPoint)
	{
		super();
		_bumper = new Bumper(0, 0, color, Up);
		_center = center;
	}

	override function create()
	{
		var text = new FlxText(0, 0, 0, BumpStikGame.g().i18n.tr("game/classic/newCol"), 30);
		text.autoSize = false;
		text.alignment = CENTER;
		text.setPosition(_center.x - text.width / 2, _center.y - text.height / 2);

		var backdrop = new FlxSprite();
		backdrop.makeGraphic(Math.round(text.width + (_bumper.width / 3)) + 16, Math.round(text.height) + 16, FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});
		backdrop.setPosition(text.x - 8, text.y - 8);

		_bumper.setPosition(backdrop.x + backdrop.width - (_bumper.width / 3), backdrop.y + ((backdrop.height - _bumper.height) / 2));

		for (item in [backdrop, text, _bumper])
		{
			item.setPosition(Math.round(item.x), Math.round(item.y));
			add(item);
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_delay -= elapsed;
		if (_delay <= 0)
			close();
	}
}
