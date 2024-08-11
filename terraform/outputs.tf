output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "access_entries" {
  value = module.eks.access_entries
}

output "eks_managed_node_groups_autoscaling_group_names" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}



