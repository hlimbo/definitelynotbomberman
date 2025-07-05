extends Node

signal on_enter_impact_area(explosion: BaseExplosion, actor: Node)
signal on_exit_impact_area(explosion: BaseExplosion, actor: Node)
signal on_start_explosion(explosion: BaseExplosion)
signal on_end_explosion(explosion: BaseExplosion)

# for sticky bomb
signal on_attach_to_entity()

signal on_start_attack(enemy: BaseEnemy, target: Node2D)
