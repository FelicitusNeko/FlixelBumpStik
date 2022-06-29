package components.classic;

import boardObject.Bumper;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class NewColorSubstate extends FlxSubState
{
	private var _bumper:Bumper;

	private var _center:FlxPoint;

	private var _delay = 2.0;

	public function new(color:Color, center:FlxPoint)
	{
		super();
		_bumper = new Bumper(0, 0, color, Up);
		_center = center;
	}

	override function create()
	{
		var backdrop = new FlxSprite(_center.x - 75, _center.y - 40);
		backdrop.makeGraphic(150, 80, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(backdrop, 0, 0, backdrop.width, backdrop.height, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});
		add(backdrop);

		var text = new FlxText(backdrop.x, backdrop.y, backdrop.width, "New Color", 30);
		text.height = backdrop.height;
		text.alignment = CENTER;
		add(text);

		_bumper.x = backdrop.x + backdrop.width - (_bumper.width / 3);
		_bumper.y = backdrop.y + ((backdrop.height - _bumper.height) / 2);
		add(_bumper);

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
