output "masternode_public_dns" {
    description = "Kube Master and Worker DNS Name"
    value = aws_cloudformation_stack.tf_kubernetes_cluster.outputs
   
}


output "controlnodeip" {
  value = aws_instance.nodes[0].public_ip
}

output "privates" {
  value = aws_instance.nodes.*.private_ip
}

