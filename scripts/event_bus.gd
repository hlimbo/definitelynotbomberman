extends Node

signal on_enter_impact_area(explosion: BaseExplosion, actor: Node)
signal on_exit_impact_area(explosion: BaseExplosion, actor: Node)
signal on_start_explosion(explosion: BaseExplosion)
signal on_end_explosion(explosion: BaseExplosion)

# for sticky bomb
signal on_attach_to_entity()

signal on_start_attack(enemy: BaseEnemy, target: Node2D)
signal on_projectile_hit(projectile: Projectile, target: Node2D)

signal on_initialize_player_hp(current_hp: float, max_hp: float)
signal on_player_hp_updated(damage: float)
signal on_bomb_switched(explosion_index: int)
