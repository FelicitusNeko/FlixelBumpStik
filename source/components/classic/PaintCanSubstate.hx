package components.classic;

import boardObject.BoardObject;
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

	public var onDialogResult(default, null) = new Event<Null<FlxColor>->Void>();

	private var _colorSet:Array<FlxColor>;

	public function new(center:FlxPoint, colors = 3, ?bg:BumperGenerator)
	{
		this.center = center;
		this.colors = colors;
		_colorSet = bg != null ? bg.colorOpts : BumperGenerator.defaultColorOpts;

		super(FlxColor.fromRGBFloat(0, 0, 0, .3));
	}

	override function create()
	{
		super.create();

		var distanceFactor = 1.3;
		var vertices:Array<FlxPoint> = [];
		var bumperHeight:Float = -1;

		var hexbutton = new FlxSpriteButton(center.x - 40, center.y - 40, null, () -> onDialogResult.dispatch(null));
		hexbutton.scrollFactor.set(1, 1);
		hexbutton.makeGraphic(144, 144, FlxColor.TRANSPARENT);

		for (i => color in BumperGenerator.defaultColorOpts)
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

		for (bumper in _bumpers)
			bumper.onClick.add(onClickBumper);
		add(_bumpers);

		onDialogResult.add(onDialogResultF);
	}

	function onClickBumper(obj:BoardObject)
	{
		if (!Std.isOfType(obj, Bumper))
			return;
		var bumper = cast(obj, Bumper);
		if (!bumper.grayedOut)
			onDialogResult.dispatch(bumper.bColor);
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
