resource "aws_cloudwatch_log_group" "this" {
  name = var.log_group_name

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DummyMetric"
  namespace           = "KKLab/Dummy"
  period              = 300
  statistic           = "Maximum"
  threshold           = 100
  alarm_description   = "Dummy metric alarm for KodeKloud lab"
  treat_missing_data  = "notBreaching"

  tags = {
    Lab = "kodekloud"
  }
}
