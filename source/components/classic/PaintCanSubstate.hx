package components.classic;

import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class PaintCanSubstate extends FlxSubState
{
	private var _bumpers = new FlxTypedGroup<Bumper>();

	public var colors(default, null):Int;

	public var center(default, null):FlxPoint;

	public function new(center:FlxPoint, colors = 3)
	{
		this.center = center;
		this.colors = colors;
		super();
	}

	override function create()
	{
		super.create();

		var distanceFactor = 1.3;

		var vertices:Array<FlxPoint> = [];

		var hex = new FlxSprite(center.x - 40, center.y - 40);
		hex.makeGraphic(144, 144, FlxColor.TRANSPARENT);

		for (i => color in BumperGenerator.colorOpts)
		{
			var bumper = new Bumper(center.x, center.y, color, i < colors ? Up : None);
			bumper.x += Math.cos(DegRad(-90 + ((i - 1) * 60))) * (bumper.height * distanceFactor);
			bumper.y += Math.sin(DegRad(-90 + ((i - 1) * 60))) * (bumper.height * distanceFactor);
			bumper.grayedOut = i >= colors;
			bumper.angle = (i - 1) * 60;
			_bumpers.add(bumper);

			// TODO: don't hardcode things
			vertices.push(new FlxPoint(Math.cos(DegRad(((i - 1) * 60))) * (bumper.height * (distanceFactor - .1)),
				Math.sin(DegRad(((i - 1) * 60))) * (bumper.height * (distanceFactor - .1))).add(72, 72));
		}

		trace(vertices);

		FlxSpriteUtil.drawPolygon(hex, vertices, FlxColor.WHITE, {thickness: 3}, {smoothing: true});
		add(hex);

		add(_bumpers);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			var pos = FlxG.mouse.getWorldPosition();
			for (bumper in _bumpers)
				if (bumper.overlapsPoint(pos))
					trace(bumper);
		}
	}

	inline function DegRad(deg:Float):Float
	{
		return deg * Math.PI / 180;
	}
}
