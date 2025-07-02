variable "env" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "resource-scheduler"
}

variable "schedule_tag_key" {
  description = "Tag key to identify resources for scheduling"
  type        = string
  default     = "Schedule"
}

variable "schedule_tag_value" {
  description = "Tag value to identify resources for scheduling"
  type        = string
  default     = "true"
}

variable "stop_schedule" {
  description = "Cron expression for stopping resources (JST: 20:00 MON-FRI)"
  type        = string
  default     = "cron(0 11 * * 2-6 *)"  # UTC時間 (JST-9時間), 2=Mon-6=Fri
}

variable "start_schedule" {
  description = "Cron expression for starting resources (JST: 08:00 MON-FRI)"
  type        = string
  default     = "cron(0 23 * * 1-5 *)"  # UTC時間 (JST-9時間), 1=Sun-5=Thu
}

variable "weekend_stop_schedule" {
  description = "Cron expression for stopping resources on weekends (JST: 00:00 SAT,SUN)"
  type        = string
  default     = "cron(0 15 * * 6 *)"  # UTC時間 (JST-9時間), 6=Fri for Sat 00:00 JST
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
  default     = 256
}

variable "enable_nodegroup_config_table" {
  description = "Whether to create DynamoDB table for storing nodegroup configurations"
  type        = bool
  default     = false
}

variable "nodegroup_config_table_name" {
  description = "Name of DynamoDB table for storing nodegroup configurations"
  type        = string
  default     = "eks-nodegroup-configs"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}