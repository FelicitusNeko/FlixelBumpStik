package components.archipelago;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Timer;
import boardObject.BoardObject;
import boardObject.Bumper;
import boardObject.archipelago.APHazardPlaceholder;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import components.classic.ClassicBoard;

enum TrapTrigger
{
	None;
	Rainbow(from:Array<FlxColor>);
	Spinner;
	Killer;
}

class APBoard extends ClassicBoard
{
	var _randomClearList:Null<Array<Bumper>> = null;

	public var trapTrigger:TrapTrigger = None;

	public function new(x:Float, y:Float, bWidth:Int, bHeight:Int)
	{
		super(x, y, bWidth, bHeight);
		_csm.addState("levelclear", smLevelClear);

		_csm.set("initial", "levelclear", "levelclear");
		_csm.set("initial", "rainbowtrap", "checking");
		_csm.set("initial", "spinertrap", "moving");
		_csm.set("initial", "killertrap", "gameoverwait");
	}

	public function levelClear()
	{
		for (launcher in _launchers)
			launcher.enabled = false;
		for (bumper in _bumpers)
			bumper.markForClear();
		_randomClearList = [];
		for (bumper in _bumpers)
			_randomClearList.push(bumper);
		(new FlxRandom()).shuffle(_randomClearList);
		_delay = .075;
		trapTrigger = None;
		_csm.chain("levelclear");
	}

	override function smIdle(elapsed:Float)
	{
		super.smIdle(elapsed);

		if (trapTrigger != None)
		{
			switch (trapTrigger)
			{
				case Rainbow(from):
					var cg = new FlxRandom();
					_launchers.forEachAlive(l -> l.enabled = false);
					_bumpers.forEachAlive(b ->
					{
						if (b.bColor != null)
							b.bColor = cg.getObject(from);
					});
					_csm.chain("rainbowtrap");

				case Spinner:
					var cg = new FlxRandom();
					var from = [Up, Right, Down, Left];
					_launchers.forEachAlive(l -> l.enabled = false);
					_bumpers.forEachAlive(b ->
					{
						if (b.direction != None)
							b.direction = cg.getObject(from);
					});
					_csm.chain("spinnertrap");

				case Killer:
					Timer.delay(() -> if (_csm.is("gameoverwait")) _forceGameOver = true, 5000);
					onGameOver.dispatch(false);
					_launchers.forEachAlive(l -> l.enabled = false);
					_bumpers.forEach(bumper -> bumper.gameOver());
					_csm.chain("killertrap");

				default:
			}
			trapTrigger = None;
		}
	}

	function smLevelClear(elapsed:Float)
	{
		_delay -= elapsed;
		if (_randomClearList != null && _randomClearList.length > 0)
		{
			if (_delay <= 0)
			{
				_randomClearList.shift().kill();
				_delay += _randomClearList.length == 0 ? 2 : .075;
			}
		}
		else if (_bumpers.countLiving() <= 0 && _delay <= 0)
			onGameOver.dispatch(true);
	}

	public override function serialize():DynamicAccess<Dynamic>
	{
		var retval = super.serialize();

		if (_obstacles.getFirstAlive() != null)
		{
			retval["obstacles"] = [];
			_obstacles.forEachAlive(o ->
			{
				retval["obstacles"].push(o.serialize());
			});
		}

		return retval;
	}

	public override function deserialize(data:DynamicAccess<Dynamic>)
	{
		super.deserialize(data);

		var obstaclesData:Array<DynamicAccess<Dynamic>> = data["obstacles"];
		for (obstacleData in obstaclesData)
		{
			var obstacle:BoardObject = switch (obstacleData["type"])
			{
				case "hazardPlaceholder": APHazardPlaceholder.fromSaved(obstacleData);
				case x: throw new Exception('Unknown board object type $x');
			}
			putObstacleAt(obstacleData["boardX"], obstacleData["boardY"], obstacle);
		}
	}
}
