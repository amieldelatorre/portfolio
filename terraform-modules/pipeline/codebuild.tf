
data "aws_iam_policy_document" "codebuild_assume_role" {
    statement {
      sid     = "CodebuildAllowAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = ["codebuild.amazonaws.com"]
      }
    }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "PortfolioCodebuildRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_policy" {
    statement {
      sid     = "CodebuildAllowLogAccess"
      effect  = "Allow"

      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]

      resources = [
        "arn:aws:logs:ap-southeast-2:778196150762:log-group:/aws/codebuild/portfolio-repo-deploy-infrastructure",   
        "arn:aws:logs:ap-southeast-2:778196150762:log-group:/aws/codebuild/portfolio-repo-deploy-infrastructure:*"
      ]
    }

    statement {
      sid     = "CodebuildAllowS3Access"
      effect  = "Allow"

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject",
      ]

      resources = [
        "arn:aws:s3:::terraform-remote-state-inventory",
        "arn:aws:s3:::terraform-remote-state-inventory/*",
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
    }

    statement {
      sid     = "CodebuildAllowDynamoDbAccess"
      effect  = "Allow"

      actions = [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ]

      resources = ["arn:aws:dynamodb:ap-southeast-2:778196150762:table/terraform-remote-state-inventory"]
    }

    statement {
      sid     = "CodebuildAllow"
      effect  = "Allow"

      actions = [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
      ]

      resources = ["arn:aws:codebuild:ap-southeast-2:778196150762:report-group/portfolio-repo-deploy-infrastructure*"]
    }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "PortfolioBuildRolePolicy"  
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}


resource "aws_codebuild_project" "deploy_infrastructure" {
  name        = "portfolio-repo-deploy-infrastructure"
  description = "For the deployment of the infrastucture for the portfolio repository"
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type = "CODEPIPELINE"
    buildspec = file("buildspecs/deploy-infrastructure.yml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
}

resource "aws_codebuild_project" "deploy_react_app" {
  name        = "portfolio-repo-deploy-react-app"
  description = "For the deployment of the react app for the portfolio repository"
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type = "CODEPIPELINE"
    buildspec = file("buildspecs/deploy-react-app.yml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
}