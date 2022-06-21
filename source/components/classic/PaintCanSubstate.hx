package components.classic;

import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import lime.app.Event;

class PaintCanSubstate extends FlxSubState
{
	private var _bumpers = new FlxTypedGroup<Bumper>();

	public var colors(default, null):Int;

	public var center(default, null):FlxPoint;

	public var onDialogResult(default, null) = new Event<Color->Void>();

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
		var bumperHeight:Float = -1;

		var hexbutton = new FlxSpriteButton(center.x + 70, center.y + 40, null, () -> onDialogResult.dispatch(None));
		hexbutton.makeGraphic(144, 144, FlxColor.TRANSPARENT);

		for (i => color in BumperGenerator.colorOpts)
		{
			var bumper = new Bumper(center.x, center.y, color, i < colors ? Up : None);
			if (bumperHeight < 0)
				bumperHeight = bumper.height;
			bumper.x += Math.cos(DegRad(-90 + ((i - 1) * 60))) * (bumperHeight * distanceFactor);
			bumper.y += Math.sin(DegRad(-90 + ((i - 1) * 60))) * (bumperHeight * distanceFactor);
			bumper.grayedOut = i >= colors;
			bumper.angle = (i - 1) * 60;
			_bumpers.add(bumper);

			vertices.push(new FlxPoint(Math.cos(DegRad((i - 1) * 60)), Math.sin(DegRad((i - 1) * 60))));
		}

		for (vertex in vertices)
			vertex.scale(bumperHeight).add(hexbutton.width / 2, hexbutton.height / 2);

		FlxSpriteUtil.drawPolygon(hexbutton, vertices, FlxColor.BLACK, {thickness: 3, color: FlxColor.RED}, {smoothing: true});
		add(hexbutton);

		var cancelText = new FlxText(center.x + (bumperHeight / 2) - 36, center.y + (bumperHeight / 2), 72, "Cancel", 16);
		cancelText.alignment = CENTER;
		cancelText.y -= cancelText.height / 2;
		add(cancelText);

		add(_bumpers);

		onDialogResult.add(onDialogResultF);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			var pos = FlxG.mouse.getWorldPosition();
			for (bumper in _bumpers)
				if (bumper.overlapsPoint(pos) && !bumper.grayedOut)
				{
					onDialogResult.dispatch(bumper.bColor);
					return;
				}
		}
	}

	function onDialogResultF(_:Color)
	{
		close();
	}

	inline function DegRad(deg:Float):Float
	{
		return deg * Math.PI / 180;
	}
}
