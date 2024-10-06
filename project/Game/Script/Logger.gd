extends Node
class_name Logger;

# https://www.nightquestgames.com/logger-in-gdscript-for-better-debugging/

# Default log file name prefix
static var LogFileNamePrefix = "Log"
 
# Enumeration of message severity
enum EMessageSeverity { Debug, Info, Warning, Error }
 
# Message severity names
static var m_MessageSeverityName : Array[String] = ["Debug", "Info", "Warning", "Error"]
 
# Log file object to output messages
static var m_LogFile : FileAccess = null
 
# Minimal logging level
static var LoggingLevel : EMessageSeverity = EMessageSeverity.Debug
 
# Base folder of log files
static var LogsFolder : String = ""

# | Description: Returns the current time as a formatted string for the log
# | Return: Current time as a formatted string for the log
static func _GetTimeForLog() -> String:
	var currentTime = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [currentTime.hour, currentTime.minute, currentTime.second]
	 
# | Description: Returns the current time as a formatted string for the log file name
# | Return: Current time as a formatted string for the log file name
static func _GetTimeForLogFileName() -> String:
	var currentTime = Time.get_time_dict_from_system()
	return "%02d_%02d_%02d" % [currentTime.hour, currentTime.minute, currentTime.second]
	 
# | Description: Returns the current date as a formatted string for the log
# | Return: Current date as a formatted string for the log
static func _GetDateForLog() -> String:
	var currentDate = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [currentDate.day, currentDate.month, currentDate.year]
	 
# | Description: Returns the current date as a formatted string for the log file name
# | Return: Current date as a formatted string for the log file name
static func _GetDateForLogFileName() -> String:
	var currentDate = Time.get_date_dict_from_system()
	return "%02d_%02d_%04d" % [currentDate.day, currentDate.month, currentDate.year]

# | Description: Sets the base folder for all logs
# | Parameter folder: The base folder to put all logs in
# | Return: None
func SetLogsFolder(folder : String) -> void:
	LogsFolder = folder
	 
# | Description: Creates a log file in the assigned folder
# | Parameter filename: Name of log file (inculding extension)
# | Return: None
func CreateLogFile(filename : String = "") -> int:
	# Create the requested folder if it doesn't exist yet
	if (not DirAccess.dir_exists_absolute(LogsFolder)):
		DirAccess.make_dir_absolute(LogsFolder)
		 
	# Open the target log file
	var logFileFullPath = LogsFolder + "/" + (_GetLogFileName() if filename == "" else filename)
	m_LogFile = FileAccess.open(logFileFullPath, FileAccess.WRITE)
	 
	# Returns OK if the file was opened successfully, otherwise returns the error
	return FileAccess.get_open_error()
 
# | Description: Returns the default name of the log file
# | Return: The default name of the log file
func _GetLogFileName() -> String:
	return "%s_%s_%s.log" % [LogFileNamePrefix, _GetDateForLogFileName(), _GetTimeForLogFileName()]

# | Description: Logs a message with a severity of Debug
# | Parameter message: The message string to output
# | Return: None
static func LogDebug(message : String) -> void:
	_LogMessage(message, EMessageSeverity.Debug)
	 
# | Description: Logs a message with a severity of Info
# | Parameter message: The message string to output
# | Return: None
static func LogInfo(message : String)  -> void:
	_LogMessage(message, EMessageSeverity.Info)
	 
# | Description: Logs a message with a severity of Warning
# | Parameter message: The message string to output
# | Return: None
static func LogWarning(message : String)  -> void:
	_LogMessage(message, EMessageSeverity.Warning)
	 
# | Description: Logs a message with a severity of Error
# | Parameter message: The message string to output
# | Return: None
static func LogError(message : String)  -> void:
	_LogMessage(message, EMessageSeverity.Error)
	
static func LogAssert(condition, message: String) -> void:
	if condition:
		return;
	LogError(message);
	 
# | Description: Sets the current logging level
# | Parameter level: Required logging level
# | Return: None
func SetLoggingLevel(level : EMessageSeverity)  -> void:
	LoggingLevel = level
 
# | Description: Internal logging function for all message severities
# | Parameter message: The message string to output
# | Parameter severity: Severity of the message to output
# | Return: None
static func _LogMessage(message : String, severity : EMessageSeverity)  -> void:
	if (LoggingLevel <= severity):
		var formattedMessage : String = "%s %s [%s] %s" % \
			[_GetDateForLog(), _GetTimeForLog(), _GetSeverityName(severity), message]
			 
		# Write the message to the Godot output window
		_LogMessageOutput(formattedMessage)
		 
		if (m_LogFile):
			# Write the message to the log file
			_LogMessageFile(formattedMessage)
		 
# | Description: Internal logging function to standard output
# | Parameter message: The message string to output
# | Return: None
static func _LogMessageOutput(message : String)  -> void:
	print(message)
		 
# | Description: Internal logging function to a file
# | Parameter message: The message string to output
# | Return: None
static func _LogMessageFile(message : String)  -> void:
	m_LogFile.store_string(message + "\n")
	m_LogFile.flush()
 
# | Description: Returns the name of the message severity as a string
# | Parameter messageSeverity: Severity enum of the message
# | Return: None
static func _GetSeverityName(messageSeverity : EMessageSeverity) -> String:
	return m_MessageSeverityName[messageSeverity]
