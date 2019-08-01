output "cluster_name"{
    value = "${azurerm_kubernetes_cluster.test.name}"
}
output "cluster_rg" {
  value = "${azurerm_resource_group.test.name}"
}

output "eh_name" {
    value = "${azurerm_eventhub.test.name}"
}

output "eh_ns_name" {
    value = "${azurerm_eventhub_namespace.test.name}"
}

output "stg_container_name" {
    value = "${azurerm_storage_container.test.name}"
}

output "stg_name" {
    value = "${azurerm_storage_account.test.name}"
}