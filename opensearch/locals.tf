locals {
    # tags = {
    #     Application = var.application
    #     Environment = var.environment
    #     Name = var.name
    # }

    # domain        = "${var.name}-engine"
    master_user   = "opensearch_user"
}

# locals {
#     for_each = fileset("${path.module}/config/app", "*.yml")
#     source =  yamldecode(templatefile("${path.module}/config/app/${each.value}", {}))
#     addons_map = {for subnet_items in flatten([for type in local.source : [
#             for addons in type.addons : {
#                 enabled_addon = addons
#             }
#         ]
#         ]) : "${subnet_items.enabled_addon}" => true
#     }
# }

# locals {
#     addons_map = {for addon_items in flatten([for addons in var.args.addons :  {
#                 enabled_addon = addons
#             }
#         ]) : "${addon_items.enabled_addon}" => true
#     }
# }
