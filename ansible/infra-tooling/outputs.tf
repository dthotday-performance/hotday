output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_instance.app_vm.*.public_ip
}