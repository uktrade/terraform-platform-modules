locals {
  # tags = {
  #     Application = var.application
  #     Environment = var.environment
  #     Name = var.name
  # }

    # domain        = "${var.name}-engine"
    master_user   = "opensearch_user"

    plans = {
        # 2 vCPU, 2GB RAM, volume size range 10-100GB
        tiny = {
            volume_size = 80
            instances = 1
            master = false
            instance = "t3.small.search"

        }
        # 2 vCPU, 4GB RAM, volume size range 10-200GB
        small = {
            volume_size = 200
            instances   = 1
            master      = false
            instance    = "t3.medium.search"
        }
        # 2 nodes with 2 vCPU, 4GB RAM, volume size range 10-200GB
        small-ha = {
            volume_size = 200
            instances   = 2
            master      = false
            instance    = "t3.medium.search"
        }
        # 2 vCPU, 8GB RAM, volume size range 10-512GB
        medium = {
            volume_size = 512
            instances   = 1
            master      = false
            instance    = "m6g.large.search"
        }
        # 2 nodes with 2 vCPU, 8GB RAM, volume size range 10-512GB
        medium-ha = {
            volume_size = 512
            instances   = 2
            master      = false
            instance    = "m6g.large.search"
        }
        # 4 vCPU, 16GB RAM, volume size range 10-1000GB
        large = {
            volume_size = 1000
            instances   = 1
            master      = false
            instance    = "m6g.xlarge.search"
        }
        # 2 nodes with 4 vCPU, 16GB RAM, volume size range 10-1000GB
        large-ha = {
            volume_size = 1000
            instances   = 2
            master      = false
            instance    = "m6g.xlarge.search"
        }
        # 8 vCPU, 32GB RAM, volume size range 10-1500GB
        x-large = {
            volume_size = 1500
            instances   = 1
            master      = false
            instance    = "m6g.2xlarge.search"
        }
        # 2 nodes with 8 vCPU, 32GB RAM, volume size range 10-1500GB
        x-large-ha = {
            volume_size = 1500
            instances   = 2
            master      = false
            instance    = "m6g.2xlarge.search"
        }
    }
}
