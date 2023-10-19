package components.archipelago;

import flixel.util.FlxColor;

/** The color of a bumper in Archipelago mode, for matching purposes. **/
enum abstract APColor(FlxColor) from FlxColor to FlxColor
{
	var Red = 0xffc57683;
	var Green = 0xff77c578;
	var Rose = 0xffc991c2;
	var Beige = 0xffd4a681;
	var Purple = 0xff7c78bd;
	var Yellow = 0xffe7ee95;

	@:to
	public inline function toString()
		switch (this)
		{
			case Red:
				return "Red";
			case Green:
				return "Green";
			case Rose:
				return "Rose";
			case Beige:
				return "Beige";
			case Purple:
				return "Purple";
			case Yellow:
				return "Yellow";
			default:
				return this.toHexString();
		}
}

/** AP Location definitions. **/
enum abstract APLocation(Int) from Int to Int
{
	var L1Score250 = 595000;
	var L1Score500;
	var L1Score750;
	var L1Score1000;
	var L1LScore500;
	var L1LScore1000;
	var L1LScore1500;
	var L1LScore2000;
	var L1LBumpers25;
	var L1LBumpers50;
	var L1LBumpers75;
	var L1Combo5;
	var L2Score500;
	var L2Score1000;
	var L2Score1500;
	var L2Score2000;
	var L2LScore1000;
	var L2LScore2000;
	var L2LScore3000;
	var L2LScore4000;
	var L2LBumpers25;
	var L2LBumpers50;
	var L2LBumpers75;
	var L2LBumpers100;
	var L2Combo5;
	var L2Chain2;
	var L3Score800;
	var L3Score1600;
	var L3Score2400;
	var L3Score3200;
	var L3LScore2000;
	var L3LScore4000;
	var L3LScore6000;
	var L3LScore8000;
	var L3LBumpers25;
	var L3LBumpers50;
	var L3LBumpers75;
	var L3LBumpers100;
	var L3LBumpers125;
	var L3Combo5;
	var L3Combo7;
	var L3Chain2;
	var L3AllClear3Col;
	var L4Score1500;
	var L4Score3000;
	var L4Score4500;
	var L4Score6000;
	var L4LScore3000;
	var L4LScore6000;
	var L4LScore9000;
	var L4LScore12000;
	var L4LBumpers25;
	var L4LBumpers50;
	var L4LBumpers75;
	var L4LBumpers100;
	var L4LBumpers125;
	var L4LBumpers150;
	var L4Combo5;
	var L4Combo7;
	var L4Chain2;
	var L4Chain3;
	var L5TScore50k;
	var L5AllHazards;
	var Booster1;
	var Booster2;
	var Booster3;
	var Booster4;
	var Booster5;
	var Treasure1;
	var Treasure2;
	var Treasure3;
	var Treasure4;
	var Treasure5;
	var Treasure6;
	var Treasure7;
	var Treasure8;
	var Treasure9;
	var Treasure10;
	var Treasure11;
	var Treasure12;
	var Treasure13;
	var Treasure14;
	var Treasure15;
	var Treasure16;
	var Treasure17;
	var Treasure18;
	var Treasure19;
	var Treasure20;
	var Treasure21;
	var Treasure22;
	var Treasure23;
	var Treasure24;
	var Treasure25;
	var Treasure26;
	var Treasure27;
	var Treasure28;
	var Treasure29;
	var Treasure30;
	var Treasure31;
	var Treasure32;

	public inline function baseIndex()
		return this - L1Score250;

	@:op(A >= B)
	public inline function geqInt(val:Int)
		return this >= val;

	@:to
	public inline function toString()
	{
		// TODO: new string table for this
		// var baseIndex = baseIndex();
		// if (Points4000 >= this)
		// 	return ((baseIndex + 1) * 250) + " Points";
		// else if (Combo6 >= this)
		// 	return "Combo " + (this - Combo4 + 4);
		// else if (Chain3 >= this)
		// 	return "Chain x" + (this - Chain2 + 2);
		// else if (AllClear == this)
		// 	return "All Clear";
		// else if (Booster5 >= this)
		// 	return "Booster Bumper " + (this - Booster1 + 1);
		// else if (ClearedHazards == this)
		// 	return "Cleared All Hazards";
		// else if (Treasure8 >= this)
		// 	return "Treasure Bumper " + (this - Treasure1 + 1);
		// else
		// 	return "Unknown";
		return "NYI";
	}
}

/** AP Item definitions. **/
enum abstract APItem(Int) from Int to Int
{
	/** Does nothing. **/
	var Nothing = 595000;

	/** Awards a score bonus proportional to the current level. **/
	var ScoreBonus;

	/** Allows the player to advance a task by one step. **/
	var TaskSkip;

	/** A Turner allows the player to change the direction of a bumper on the field. This item increases the player's starting Turner count by one. **/
	var StartingTurner;

	/** Unused placeholder. **/
	var Blank004;

	/** A Paint Can allows the player to change the color of a bumper on the field. This item increases the player's starting Paint Can count by one. **/
	var StartPaintCan;

	/** Can be cleared to send a check and permanently increase the player's score multiplier by .2×. **/
	var BonusBooster;

	/** Starting in level 2, generates an immobile bumper that cannot be cleared for five turns. **/
	var HazardBumper;

	/** Can be cleared to send a check and award a score bonus equivalent to one additional chain on that bumper. **/
	var TreasureBumper;

	/** Changes the color of every bumper on the field. **/
	var RainbowTrap;

	/** Changes the direction of every bumper on the field. **/
	var SpinnerTrap;

	/** Terminates the player's current board. **/
	var KillerTrap;

	@:to
	public inline function toString()
		return "game/ap/" + switch (this)
		{
			case ScoreBonus:
				"item/scoreBonus";
			case TaskSkip:
				"item/taskSkip";
			case StartingTurner:
				"item/startTurner";
			case Blank004:
				"item/default";
			case StartPaintCan:
				"item/paintCan";
			case BonusBooster:
				"item/booster";
			case HazardBumper:
				"item/hazard";
			case TreasureBumper:
				"item/treasure";
			case RainbowTrap:
				"trap/rainbow";
			case SpinnerTrap:
				"trap/spinner";
			case KillerTrap:
				"trap/killer";
			default:
				"item/default";
		}
}
