locals {
  name   = "heartcentrix_feldmann_challenge"
  region = "us-east-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Project = local.name
    Purpose = "Marcio-Feldmann-new-employee-at-HeartCentrix"
  }
}
