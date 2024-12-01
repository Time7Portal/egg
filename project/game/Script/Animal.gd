extends Node
class_name Animal;

#region GlobalVariable
@export var gMaxIdleTime:float = 5.0;
@export var gMinIdleTime:float = 0.3;
@export var gJumpSpeed:float = 20.0;
#endregion

#region Animation and Movement
enum STATE {IDLE, MOVE}

var gState:STATE = STATE.IDLE;
var gIdleTime:float = 0;
var gCurrentIdleTime:float = 0;
var gTargetPosition:Vector3 = Vector3(0, 0, 0);
# 지구인 : sin 함수를 이용한 주기적 점프 구현을 위한 계수
var gJumpOmega = 0.0;
# 지구인 : 즉시 회전을 반영하지 않고 목표한 회전값을 저장해 천천히 회전
var gTargetRotationY:float = 0.0;
#endregion

#region Status
class Status:
	var _lifeTime:float = 0;
	var _speed:float = 0; # UnitLength per second
	var _jumpHeight:float = 0.3; # MaxHeight, 현재는 고정으로 사용
	var _productivity:float = 0;
	
var _farmIndex:int = 0;
var _status:Status;
var _currentLifeTime:float = 0;
#endregion

func changeStateIDLE() -> void:	
	var rng:RandomNumberGenerator = RandomNumberGenerator.new();
	gIdleTime = rng.randf_range(gMinIdleTime, gMaxIdleTime);
	gCurrentIdleTime = 0;
	gState = STATE.IDLE;
	#Logger.LogDebug("Idle: %s time: %f" % [self.name, gIdleTime]);

func _ready() -> void:
	changeStateIDLE();
	
func initializeStatus(lifeTime:float, speed:float, productivity:float) -> void:
	_status = Status.new();
	_status._lifeTime = lifeTime;
	_status._speed = speed;
	_status._productivity = productivity;
	Manager.onAddAnimal(self);
	
func _exit_tree() -> void:
	Manager.onRemoveAnimal(self);
	
func processLifeTime() -> void:
	if _currentLifeTime >= _status._lifeTime:
		self.queue_free();

func _process(delta: float) -> void:
	_currentLifeTime += delta;
	
	processLifeTime();
	
	match gState:
		STATE.IDLE:
			gCurrentIdleTime += delta;
			if gCurrentIdleTime >= gIdleTime:
				gTargetPosition = GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex];
				#Logger.LogDebug("Move: %s to %v" % [self.name, gTargetPosition]);
				
				var dir:Vector3 = gTargetPosition - self.position;
				dir = dir.normalized();
				var angle:float = Vector3(-1, 0, 0).angle_to(dir);
				if Vector3(-1, 0, 0).cross(dir).y < 0:
					gTargetRotationY = -angle;
				else:
					gTargetRotationY = angle;
				
				gState = STATE.MOVE;
		STATE.MOVE:
			# dist 계산을 위해 y 점프 값 초기화
			self.position.y = 0.0;
			
			var dir:Vector3 = gTargetPosition - self.position;
			dir = dir.normalized();
			var moveDelta:Vector3 = dir * _status._speed * delta;
			var dist:Vector3 = gTargetPosition - (self.position + moveDelta);
			if dist.length() <= 0.05:
				moveDelta = gTargetPosition - self.position;
				changeStateIDLE();
				
			self.position += moveDelta;
			
			# 지구인 : Gently shake the character up and down to create natural feeling
			# 위아래로 살짝씩 흔들어서 자연스럽게 이동하는 느낌으로 구현
			gJumpOmega += delta * gJumpSpeed;
			self.position.y = (sin(gJumpOmega) + 1) * _status._jumpHeight;
			
			# 지구인 : 부드러운 회전 구현
			self.rotation.y -= (self.rotation.y - gTargetRotationY) * delta * 2.0;
		_:
			Logger.LogError("Error!");
