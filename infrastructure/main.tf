terraform {
  backend "s3" {
    bucket         = "minimal-provider-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "minimal-provider-terraform-lock-table"
    encrypt        = true
  }
}

module "vpc" {
  source        = "./modules/vpc"
  aws_region    = var.aws_region
  project_name  = var.project_name
}

module "security_groups" {
  source                = "./modules/security_groups"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  web_port              = var.web_port
}

module "alb" {
  source                  = "./modules/alb"
  minimal_provider_sg_id  = module.security_groups.minimal_provider_sg_id
  subnets                 = module.vpc.subnet_ids
  vpc_id                  = module.vpc.vpc_id
  web_port                = var.web_port
}

module "ecr" {
  source                = "./modules/ecr"
  ecr_repository_name   = "${var.project_name}-repo"
}

module "iam" {
  source                            = "./modules/iam"
  project_name                      = var.project_name
  openai_api_key_arn                = module.secret_manager.openai_api_key_arn
  anthropic_api_key_arn             = module.secret_manager.anthropic_api_key_arn
  notdiamond_api_key_arn            = module.secret_manager.notdiamond_api_key_arn
  market_api_key_arn                = module.secret_manager.market_api_key_arn
  app_completions_endpoint_arn      = module.secret_manager.app_completions_endpoint_arn
}

module "secret_manager" {
  source                = "./modules/secret_manager"
  project_name          = var.project_name
}

module "ecs" {
  source                            = "./modules/ecs"
  project_name                      = var.project_name
  cpu_architecture                  = var.cpu_architecture
  web_port                          = var.web_port
  ecr_repository_url                = module.ecr.repository_url
  docker_image_tag                  = var.docker_image_tag
  openai_api_key_arn                = module.secret_manager.openai_api_key_arn
  anthropic_api_key_arn             = module.secret_manager.anthropic_api_key_arn
  notdiamond_api_key_arn            = module.secret_manager.notdiamond_api_key_arn
  market_api_key_arn                = module.secret_manager.market_api_key_arn
  app_completions_endpoint_arn      = module.secret_manager.app_completions_endpoint_arn
  public_subnet_ids                 = module.vpc.subnet_ids
  execution_role_arn                = module.iam.ecs_execution_role_arn
  task_role_arn                     = module.iam.ecs_task_role_arn
  aws_region                        = var.aws_region
  alb_target_group_arn              = module.alb.alb_target_group_arn
  minimal_provider_sg_id            = module.security_groups.minimal_provider_sg_id
}
