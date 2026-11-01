class_name SimContext
extends RefCounted
## Reúne os serviços do núcleo que os módulos recebem em `setup` (arquitetura 4.5):
## relógio, barramento de eventos, aleatoriedade e gerador de IDs.
## Regra de uso: módulos só LEEM o relógio; quem chama `clock.advance_step()` é o SimulationHost.
## O sorteio passa sempre por `rng` (fluxos nomeados) e o ID de entidade sempre por `ids`.

var clock: SimClock
var events: EventBus
var rng: WorldRng
var ids: IdGenerator


func _init(sim_clock: SimClock, event_bus: EventBus, world_rng: WorldRng, id_generator: IdGenerator) -> void:
	clock = sim_clock
	events = event_bus
	rng = world_rng
	ids = id_generator
