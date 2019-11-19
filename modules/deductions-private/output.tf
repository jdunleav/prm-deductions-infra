output "deductions_private_ecs_cluster_id" {
  value       = "${aws_ecs_cluster.ecs-cluster.id}"
}

output "deductions_private_ecs_tasks_sg_id" {
  value       = "${aws_security_group.ecs-tasks-sg.id}"
}

output "deductions_private_private_subnets" {
  value       = "${module.vpc.private_subnets}"
}

# output "deductions_private_alb_tg_arn" {
#   value       = "${aws_alb_target_group.alg-tg.arn}"
# }