resource "random_string" "bucket_random_suffix" {
  length    = 16
  special   = false
  upper     = false
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "deployment-pipeline-bucket-${random_string.bucket_random_suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket_ownership" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_public_access_block" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

  stage {
    name = "Deploy-React-App"

    action {
      name             = "Deploy-React-App"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy_react_app.name
      }
    }
  }
}

