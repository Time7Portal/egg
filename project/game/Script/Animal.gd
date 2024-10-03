extends Node
class_name Animal;

@export var gMaxIdleTime:float = 10.0;
@export var gMinIdleTime:float = 0.3;
@export var gMaxSpeed:float = 0.6;
@export var gMinSpeed:float = 0.3;

enum STATE {IDLE, MOVE}

var gState:STATE = STATE.IDLE;
var gIdleTime:float = 0;
var gCurrentIdleTime:float = 0;
var gTargetPosition:Vector3 = Vector3(0, 0, 0);
var gSpeed = 0; #UnitLength per second

func changeStateIDLE() -> void:	
	var rng:RandomNumberGenerator = RandomNumberGenerator.new();
	rng.randomize();
	gIdleTime = rng.randf_range(gMinIdleTime, gMaxIdleTime);
	gSpeed = rng.randf_range(0.1, 0.3);

func _ready() -> void:
	changeStateIDLE();

func _process(delta: float) -> void:
	match gState:
		STATE.IDLE:
			gCurrentIdleTime += delta;
			if gCurrentIdleTime >= gIdleTime:
				var rng:RandomNumberGenerator = RandomNumberGenerator.new();
				rng.randomize();
				gTargetPosition = Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-5, 5));
				
				var angle:float = self.position.angle_to(gTargetPosition);
				self.rotation.y = angle;
				
				gState = STATE.MOVE;
		STATE.MOVE:
			var dir:Vector3 = self.position - gTargetPosition;
			dir = dir.normalized();
			var moveDelta:Vector3 = dir * gSpeed * delta;
			var dist:Vector3 = gTargetPosition - (self.position + moveDelta);
			if dist.length() <= 0.05:
				moveDelta = gTargetPosition - self.position;
				changeStateIDLE();
				
			self.position += moveDelta;
		_:
			print("Error!");
