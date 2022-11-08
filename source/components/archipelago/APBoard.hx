package components.archipelago;

import haxe.Exception;
import boardObject.BoardObject;
import boardObject.archipelago.APHazardPlaceholder;
import boardObject.Bumper;
import components.classic.ClassicBoard;
import flixel.math.FlxRandom;
import haxe.DynamicAccess;

class APBoard extends ClassicBoard
{
	var _randomClearList:Null<Array<Bumper>> = null;

	public function new(x:Float, y:Float, bWidth:Int, bHeight:Int)
	{
		super(x, y, bWidth, bHeight);
		_csm.addState("levelclear", smLevelClear);

		_csm.set("initial", "levelclear", "levelclear");
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
		_csm.chain("levelclear");
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

	public override function deserialize(data:DynamicAccess<Dynamic>) {
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
