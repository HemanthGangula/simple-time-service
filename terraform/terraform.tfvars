aws_region      = "us-east-1"
cluster_name    = "timeservice-eks"
cluster_version = "1.31"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

node_instance_type = "t3.small"
node_desired_count = 2
node_min_count     = 1
node_max_count     = 2
