# TASK 1 - VPC Flow Logs -> CloudWatch  (book: "Monitoring")
#
# Chain to build (each piece depends on the previous one):
#   1. data aws_iam_policy_document  : trust policy, principal = vpc-flow-logs.amazonaws.com
#   2. aws_iam_role                  : uses (1) as assume_role_policy
#   3. data aws_iam_policy_document  : logs:CreateLogGroup/CreateLogStream/PutLogEvents/
#                                      DescribeLogGroups/DescribeLogStreams
#   4. aws_iam_role_policy           : attaches (3) to (2)
#   5. aws_cloudwatch_log_group      : name "${local.prefix}-network", retention 7 days
#   6. aws_flow_log                  : traffic_type ALL, vpc_id = aws_vpc.main.id,
#                                      iam_role_arn + log_destination wired from (2),(5)
#
# TODO: write all six resources below.
# WATCH OUT: the book's role snippet references data...assume_role but the data
# source is declared as "vpc_assume_role" - make your names consistent


data "aws_iam_policy_document" "vpc_assume_role" {
	statement {
effect = "Allow"
principals {
type = "Service"
identifiers = ["vpc-flow-logs.amazonaws.com"]
}
actions = ["sts:AssumeRole"]
}
}

resource "aws_iam_role" "vpc" {
  name               = "${local.prefix}-network"
  assume_role_policy = data.aws_iam_policy_document.vpc_assume_role.json
}


data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "${local.prefix}-network-cloudwatch"
  role   = aws_iam_role.vpc.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_cloudwatch_log_group" "vpc" {
  name              = "${local.prefix}-network"
  retention_in_days = 7
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
