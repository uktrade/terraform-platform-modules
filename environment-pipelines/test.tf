# data "aws_iam_policy_document" "lambda_policy_access" {
#   statement {
#     actions = [
#       "lambda:GetPolicy"
#     ]
#     resources = [
#       "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.application}-${var.pipeline_name}-origin-secret-rotate"
#     ]
#   }
# }

# resource "aws_iam_role_policy" "lambda_policy_access_for_environment_codebuild" {
#   name   = "${var.application}-${var.pipeline_name}-lambda-policy-access-for-environment-codebuild"
#   role   = aws_iam_role.environment_pipeline_codebuild.name
#   policy = data.aws_iam_policy_document.lambda_policy_access.json
# }

# #-------------------------------

# data "aws_iam_policy_document" "wafv2_read_access" {
#   statement {
#     actions = [
#       "wafv2:GetWebACL",
#       "wafv2:GetWebACLForResource"
#     ]
#     resources = [
#       "arn:aws:wafv2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:regional/webacl/*/*"
#     ]
#   }
# }

# resource "aws_iam_role_policy" "wafv2_read_access_for_environment_codebuild" {
#   name   = "${var.application}-${var.pipeline_name}-waf2-read-access-for-environment-codebuild"
#   role   = aws_iam_role.environment_pipeline_codebuild.name
#   policy = data.aws_iam_policy_document.wafv2_read_access.json
# }

# #-------------------------------

# data "aws_iam_policy_document" "secret_manager_read_access" {
#   statement {
#     actions = [
#       "secretsmanager:DescribeSecret",
#       "secretsmanager:GetSecretValue"
#     ]
#     resources = [
#       "arn:aws:wafv2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:regional/webacl/*",

#       "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.application}-${var.pipeline_name}-origin-verify-header-secret-*"
#     ]
#   }
# }

# resource "aws_iam_role_policy" "secret_manager_read_access_for_environment_codebuild" {
#   name   = "${var.application}-${var.pipeline_name}-secret-manager-read-access-for-environment-codebuild"
#   role   = aws_iam_role.environment_pipeline_codebuild.name
#   policy = data.aws_iam_policy_document.secret_manager_read_access.json
# }
