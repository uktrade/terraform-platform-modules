# locals {
#     tags = {
#         copilot-application = var.args.application
#         copilot-environment = each.value
#     }
# }

# locals {
#     addons_map = {for addon_items in flatten([for addons in var.args.addons :  {
#                 enabled_addon = addons
#             }
#         ]) : "${addon_items.enabled_addon}" => true
#     }
# }
