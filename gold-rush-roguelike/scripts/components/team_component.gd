extends Node
class_name TeamComponent

enum Team {
	PLAYER,
	ENEMY,
	NEUTRAL,
}

@export var team: Team = Team.NEUTRAL


func is_hostile_to(other: TeamComponent) -> bool:
	if other == null:
		return false
	if team == Team.NEUTRAL or other.team == Team.NEUTRAL:
		return false
	return team != other.team


func is_hostile_team(other_team: Team) -> bool:
	if team == Team.NEUTRAL or other_team == Team.NEUTRAL:
		return false
	return team != other_team
