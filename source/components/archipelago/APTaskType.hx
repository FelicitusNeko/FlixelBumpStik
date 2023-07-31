package components.archipelago;

/** The type of task to be completed. **/
enum APTaskType
{
	/** The pseudotask at the top of the list to indicate the current level. **/
	LevelHeader;

	/** A certain number of points must be obtained this game. **/
	Score;

	/** A certain number of points must be obtained across all games this level. **/
	LevelScore;

	/** A certain number of points must be obtained across all games this session. **/
	TotalScore;

	/** A certain number of bumpers must be cleared this game. **/
	Cleared;

	/** A certain number of bumpers must be cleared across all games this level. **/
	LevelCleared;

	/** A certain number of bumpers must be cleared across all games this session. **/
	TotalCleared;

	/** A combo of a certain number of bumpers must be formed. **/
	Combo;

	/** A chain of a certain length must be formed. **/
	Chain;

	/** A certain number of Treasure Bumpers must be cleared across all games this session. **/
	Treasures;

	/** A certain number of Bonus Boosters must be cleared across all games this session. **/
	Boosters;

	/** A certain number of Hazard Bumpers must be cleared across all games this session. **/
	Hazards;

	/** An All Clear must be obtained with at least a certain number of colors. **/
	AllClear;
}
