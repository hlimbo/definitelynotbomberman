extends Node

signal on_enter_impact_area(explosion: BaseExplosion, actor: Node)
signal on_exit_impact_area(explosion: BaseExplosion, actor: Node)
signal on_start_explosion(explosion: BaseExplosion)
signal on_end_explosion(explosion: BaseExplosion)

# for sticky bomb
signal on_attach_to_entity()

signal on_start_attack(enemy: BaseEnemy, target: Node2D)
signal on_projectile_hit(projectile: Projectile, target: Node2D)

#region UI Signals

# utilizes RID's int id to determine which godot object this event is for
signal on_initialize_hp(resource_id: int, current_hp: float, max_hp: float)
signal on_hp_updated(resource_id: int, damage: float)
signal on_player_bomb_switched(explosion_index: int)
signal on_bomb_picked_up(bomb_type: Constants.BombType, count: int)
signal on_bomb_thrown(bomb_type: Constants.BombType)
#endregion

signal on_game_end(game_state: String)
