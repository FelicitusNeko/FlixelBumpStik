package utilities;

/** Keeps track of special bumpers. **/
typedef IDeploymentSchedule =
{
	/** This many are queued to be deployed. **/
	// var toDeploy:Int;
	var inStock:Int;

	/** This many can be deployed at the current level. **/
	// var deployable:Int;
	var maxAvailable:Int;

	/** This many are yet to be cleared. **/
	// var toClear:Int;
	var onBoard:Int;

	/** This many have been cleared. **/
	// var cleared:Int;
	var clear:Int;

	/** It has been this many turns since one has been deployed since becoming available. **/
	var sinceLast:Int;

	/** The minimum number of turns before another one will be deployed. **/
	var minDelay:Int;

	/** The maximum number of turns before another one will be deployed. **/
	var maxDelay:Int;
}

@:forward
abstract DeploymentSchedule(IDeploymentSchedule) from IDeploymentSchedule
{
	/** The number of turns this bumper type has been eligible to spawn. **/
	public var eligibleTurns(get, never):Int;

	/** The maximum number of turns until this bumper type must spawn, unless a higher priority one spawns first. **/
	public var maxEligible(get, never):Int;

	/** The total number of this bumper type that have been received, regardless of state. **/
	public var total(get, never):Int;

	/** The actual number of this bumper type available to be launched. **/
	public var available(get, never):Int;

	inline function get_eligibleTurns()
		return Math.round(Math.max(this.sinceLast - this.minDelay, 0));

	inline function get_maxEligible()
		return this.maxDelay - this.minDelay;

	inline function get_total()
		return this.inStock + this.onBoard + this.clear;

	inline function get_available()
		return Math.round(Math.min(total, this.maxAvailable)) - this.clear - this.onBoard;

	inline public function reset()
	{
		this.inStock += this.onBoard;
		this.onBoard = 0;
		this.sinceLast = 0;
	}
}
