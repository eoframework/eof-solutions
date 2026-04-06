#------------------------------------------------------------------------------
# Azure Virtual Network Module
#------------------------------------------------------------------------------
# Creates VNet with:
# - Multiple subnets with service endpoints and delegations
# - Network security groups
# - Service endpoints for Azure services
#------------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Subnets
#------------------------------------------------------------------------------
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Disabled")
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", false)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = lookup(delegation.value, "actions", null)
      }
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Network Security Groups
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_security_rule" "this" {
  for_each = { for rule in local.nsg_rules : "${rule.nsg_name}-${rule.name}" => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", null)
  source_port_ranges          = lookup(each.value, "source_port_ranges", null)
  destination_port_range      = lookup(each.value, "destination_port_range", null)
  destination_port_ranges     = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix       = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes     = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.nsg_name].name
}

#------------------------------------------------------------------------------
# NSG to Subnet Association
#------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "nsg_name", null) != null }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_name].id
}

#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  nsg_rules = flatten([
    for nsg_name, nsg in var.network_security_groups : [
      for rule in lookup(nsg, "rules", []) : merge(rule, { nsg_name = nsg_name })
    ]
  ])
}
