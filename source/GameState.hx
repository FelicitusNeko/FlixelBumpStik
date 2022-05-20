import Bumper.Color;
import Bumper.Direction;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;

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
	private var _bumpers:FlxTypedGroup<Bumper> = new FlxTypedGroup<Bumper>();
	private var _delay:Float = 0;

	override function create()
	{
		_nextBumper = new Bumper(550, 400, Color.Blue);
		add(_nextBumper);
		add(_nextBumper.arrow);

		// var testBumper = new Bumper(72, 72, Color.Red, Direction.Right);
		// add(testBumper);
		// add(testBumper.arrow);

		// testBumper.snapToPos();

		add(_bumpers);
		_bumpers.add(new Bumper(64, 64, Color.Red, Direction.Right));
		_bumpers.add(new Bumper(320, 64, Color.Green, Direction.Up));
		_bumpers.forEachAlive(bumper ->
		{
			add(bumper.arrow);
			bumper.snapToPos();
		});
		_bumpers.getFirstAlive().startMoving(Direction.Right);
		gameSM = GameSM.Moving;

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
				{
					if (isSomethingMoving = bumper.velocity.x != 0 || bumper.velocity.y != 0)
						break;
				}
				if (!isSomethingMoving)
				{
					trace("Done moving");
					gameSM = GameSM.Clearing;
				}
			default:
		}

		super.update(elapsed);
	}

	private function bumperBump(lh:Bumper, rh:Bumper)
	{
		lh.snapToPos();
	}
}
