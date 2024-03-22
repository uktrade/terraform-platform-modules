#   {{ addon_config.prefix }}SubscriptionFilter:
#     Type: AWS::Logs::SubscriptionFilter
#     DependsOn:
#       - {{ addon_config.prefix }}DBInstance
#     Properties:
#       RoleArn: !Sub 'arn:aws:iam::${AWS::AccountId}:role/CWLtoSubscriptionFilterRole'
#       LogGroupName: !Sub '/aws/rds/instance/${{ '{' }}{{ addon_config.prefix }}DBInstance}/postgresql'
#       FilterName: !Sub '/aws/rds/instance/${App}/${Env}/${{ '{' }}{{ addon_config.prefix }}DBInstance}/postgresql'
#       FilterPattern: ''
#       DestinationArn: !If [{{ addon_config.prefix }}CreateProdSubFilter, '{{ log_destination.prod }}', '{{ log_destination.dev }}']