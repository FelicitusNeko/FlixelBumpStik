import Bumper.Color;
import Bumper.Direction;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;

enum GameSM
{
	Starting;
	Idle;
	Moving;
	Clearing;
	Special(x:Int);
	GameOver;
}

abstract class GameState extends FlxState
{
	public var score(default, null):Int = 0;
	public var block(default, null):Int = 0;
	public var gameSM(default, null):GameSM = Starting;

	private var _nextBumper:Bumper = null;
	private var _bumpers = new FlxTypedGroup<Bumper>();
	private var _delay:Float = 0;

	override function create()
	{
		_nextBumper = new Bumper(550, 400, Color.Blue);
		add(_nextBumper);

		add(_bumpers);
		_bumpers.add(new Bumper(64, 64, Color.Red, Direction.Right));
		_bumpers.add(new Bumper(320, 64, Color.Green, Direction.None));
		_bumpers.forEachAlive(bumper -> bumper.snapToPos());
		_bumpers.getFirstAlive().startMoving(Direction.Right);
		gameSM = GameSM.Moving;

		// TODO: this should be [tile width/height] / 2 * [board width/height]
		FlxG.camera.focusOn(new FlxPoint(180, 180));

		super.create();
	}

	override function update(elapsed:Float)
	{
		_delay -= elapsed;
		if (_delay < 0)
		{
			// TODO: do movement things based on the negative of _delay
			_delay = 0;
		}

		switch (gameSM)
		{
			case Moving:
				FlxG.overlap(_bumpers, _bumpers, bumperBump);
				var isSomethingMoving = false;
				for (bumper in _bumpers)
					if (isSomethingMoving = bumper.isMoving)
						break;
				if (!isSomethingMoving)
				{
					trace("Done moving");
					gameSM = GameSM.Clearing;
				}
			default:
		}

		super.update(elapsed);
	}

	private function bumperBump(lh:FlxSprite, rh:FlxSprite)
	{
		if (!lh.alive || !rh.alive)
			return;
		// trace("Collision between " + lh.ID + " and " + rh.ID);
		for (bumper in _bumpers)
			if (bumper.base == lh)
				bumper.snapToPos();
	}
}
