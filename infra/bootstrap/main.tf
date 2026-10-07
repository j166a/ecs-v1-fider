resource "aws_ecr_repository" "fider" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "fider"
      Purpose = "container-registry"
    }
  )
}
