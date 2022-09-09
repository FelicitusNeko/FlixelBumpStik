package utilities;

/** Keeps track of special bumpers. **/
typedef IDeploymentSchedule =
{
	/** This many are queued to be deployed. **/
	var toDeploy:Int;

	/** This many can be deployed at the current level. **/
	var deployable:Int;

	/** This many are yet to be cleared. **/
	var toClear:Int;

	/** This many have been cleared. **/
	var cleared:Int;

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

	inline function get_eligibleTurns()
		return Math.round(Math.max(this.sinceLast - this.minDelay, 0));

	inline function get_maxEligible()
		return this.maxDelay - this.minDelay;
}
