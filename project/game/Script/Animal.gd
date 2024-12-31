extends Node
class_name Animal;

#region GlobalVariable
@export var gMaxIdleTime:float = 5.0;
@export var gMinIdleTime:float = 0.3;
@export var gJumpSpeed:float = 20.0;
#endregion

#region Animation and Movement
enum STATE {IDLE, MOVE}

var _state:STATE = STATE.IDLE;
var _idleTime:float = 0;
var _currentIdleTime:float = 0;
var _targetPosition:Vector3 = Vector3(0, 0, 0);
# 지구인 : sin 함수를 이용한 주기적 점프 구현을 위한 계수
var _jumpOmega = 0.0;
# 지구인 : 즉시 회전을 반영하지 않고 목표한 회전값을 저장해 천천히 회전
var _targetRotationY:float = 0.0;
#endregion

#region Status
class Status:
	var _lifeTime:float = 0;
	var _speed:float = 0; # UnitLength per second
	var _jumpHeight:float = 0.3; # MaxHeight, 현재는 고정으로 사용
	var _productivity:float = 0;
	
var _status:Status;

class UpdateStatus:
	var _hunger:float = 0;
	var _happiness:float = 0;

var _updateStatus:UpdateStatus = UpdateStatus.new();

var _currentLifeTime:float = 0;
#endregion

#region Information
var _farmIndex:int = 0;
#endregion

func changeStateIDLE() -> void:	
	var rng:RandomNumberGenerator = RandomNumberGenerator.new();
	_idleTime = rng.randf_range(gMinIdleTime, gMaxIdleTime);
	_currentIdleTime = 0;
	_state = STATE.IDLE;
	#Logger.LogDebug("Idle: %s time: %f" % [self.name, _idleTime]);

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
	
	match _state:
		STATE.IDLE:
			_currentIdleTime += delta;
			if _currentIdleTime >= _idleTime:
				_targetPosition = GlobalVariable.getRandomGroundPosition() + Manager.gManagerNode.gScenePosition[_farmIndex];
				#Logger.LogDebug("Move: %s to %v" % [self.name, _targetPosition]);
				
				var dir:Vector3 = _targetPosition - self.position;
				dir = dir.normalized();
				var angle:float = Vector3(-1, 0, 0).angle_to(dir);
				if Vector3(-1, 0, 0).cross(dir).y < 0:
					_targetRotationY = -angle;
				else:
					_targetRotationY = angle;
				
				_state = STATE.MOVE;
		STATE.MOVE:
			# dist 계산을 위해 y 점프 값 초기화
			self.position.y = 0.0;
			
			var dir:Vector3 = _targetPosition - self.position;
			dir = dir.normalized();
			var moveDelta:Vector3 = dir * _status._speed * delta;
			var dist:Vector3 = _targetPosition - (self.position + moveDelta);
			if dist.length() <= 0.05:
				moveDelta = _targetPosition - self.position;
				changeStateIDLE();
				
			self.position += moveDelta;
			
			# 지구인 : Gently shake the character up and down to create natural feeling
			# 위아래로 살짝씩 흔들어서 자연스럽게 이동하는 느낌으로 구현
			_jumpOmega += delta * gJumpSpeed;
			self.position.y = (sin(_jumpOmega) + 1) * _status._jumpHeight;
			
			# 지구인 : 부드러운 회전 구현
			self.rotation.y -= (self.rotation.y - _targetRotationY) * delta * 2.0;
		_:
			Logger.LogError("Error!");

	# process updatestatus
	# TODO(Lee) 배고픔 어떻게 설정되어야하는가? 먹이먹으면 줄이고, 시간이 지남에 따라 내린다? 일단 행복도 1되면 다시 0부터 시작하도록
	_updateStatus._hunger += 0.01;
	if(_updateStatus._hunger > 1.0):
		_updateStatus._hunger = 0.0;

	# TODO(Lee) 행복도는.. 음악 틀면 점차 올라가고.. 떨어트리는 건 어떻게 할지?
	_updateStatus._happiness -= 0.1;
	if(_updateStatus._happiness < 0.0):
		_updateStatus._happiness = 1.0;

	#TODO(Lee): 어떤 Status에 따라 스폰될지 결정되어야함, 일단 1%확률로 나오도록
	var tempSpawnPoopRatio = Utility.randomRangeFloat(0, 1);
	if(_updateStatus._hunger > 0.99 and tempSpawnPoopRatio < 0.01):
		Manager.onAddPoop(self)

	processLifeTime();
