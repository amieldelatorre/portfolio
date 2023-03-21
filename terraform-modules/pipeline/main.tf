resource "random_string" "bucket_random_suffix" {
  length    = 16
  special   = false
  upper     = false
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "deployment-pipeline-bucket-${random_string.bucket_random_suffix.result}"
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
    statement {
      sid     = "CodepipelineAllowAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = ["codepipeline.amazonaws.com"]
      }
    }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "PortfolioCodepipelineRole"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
    statement {
      sid     = "CodepipelineAllowS3Access"
      effect  = "Allow"

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject",
      ]

      resources = [
        aws_s3_bucket.codepipeline_bucket.arn,
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    }

    statement {
      sid     = "CodepipelineAllowCodestarConnectionUse"
      effect  = "Allow"
      actions = ["codestar-connections:UseConnection"]
      resources = [aws_codestarconnections_connection.github.arn]
    }

    statement {
      sid     = "CodepipelineCodeBuildAllow"
      effect  = "Allow"

      actions = [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
      ]

      resources = ["*"]
    }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "PortfolioPipelineRolePolicy"  
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


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

resource "aws_codepipeline" "codepipeline" {
  name = "portfolio-repo-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = 1
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "amieldelatorre/portfolio"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Deploy-Infrastructure"

    action {
      name             = "Deploy-Infrastructure"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy_infrastructure.name
      }
    }
  }
}

