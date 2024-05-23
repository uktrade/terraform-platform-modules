# Changelog

## [2.0.0](https://github.com/uktrade/terraform-platform-modules/compare/v1.3.0...2.0.0) (2024-05-23)


### ⚠ BREAKING CHANGES

* "DBTP-958 Straighten up Postgres plans ([#112](https://github.com/uktrade/terraform-platform-modules/issues/112))" (#132)
* DBTP-958 Straighten up Postgres plans ([#112](https://github.com/uktrade/terraform-platform-modules/issues/112))

### Features

* (DBTP-855) Add tests for Postgres ([#30](https://github.com/uktrade/terraform-platform-modules/issues/30)) ([c51bb7a](https://github.com/uktrade/terraform-platform-modules/commit/c51bb7abec366599ead5da15861059d97ece7eb4))
* 872 checkov baseline file ([#109](https://github.com/uktrade/terraform-platform-modules/issues/109)) ([975fa06](https://github.com/uktrade/terraform-platform-modules/commit/975fa066fe62304d4981b81cd370468fb14a8ac3))
* add cloud watch subscription filter to open search module ([#82](https://github.com/uktrade/terraform-platform-modules/issues/82)) ([fd22b9b](https://github.com/uktrade/terraform-platform-modules/commit/fd22b9b7e9b2879a33de1d1eaad22eb892668d7c))
* Changed to new assume role name ([#128](https://github.com/uktrade/terraform-platform-modules/issues/128)) ([ca17b44](https://github.com/uktrade/terraform-platform-modules/commit/ca17b44a867245fc527d0a577823fde517a994a9))
* DBTP 843 vpc peering ([#83](https://github.com/uktrade/terraform-platform-modules/issues/83)) ([3684d87](https://github.com/uktrade/terraform-platform-modules/commit/3684d877bf631a19aaf214dee330c55f3a42c0fb))
* DBTP-892 release-please to automate releases/tagging ([#89](https://github.com/uktrade/terraform-platform-modules/issues/89)) ([a8d4754](https://github.com/uktrade/terraform-platform-modules/commit/a8d4754baf2de1d18e3d8ddedb90133627240383))
* DBTP-909 - Run `copilot env deploy` in pipeline ([#126](https://github.com/uktrade/terraform-platform-modules/issues/126)) ([15abc7b](https://github.com/uktrade/terraform-platform-modules/commit/15abc7b37d7c5a8eee70a38be7c8c076df2084df))
* DBTP-910 - Environment log resource policy overrides ([#95](https://github.com/uktrade/terraform-platform-modules/issues/95)) ([fa64beb](https://github.com/uktrade/terraform-platform-modules/commit/fa64beb3a84d3eeb93d5a7bbe5916b6bec17c4ec))
* DBTP-911 Barebones environment pipeline module ([#81](https://github.com/uktrade/terraform-platform-modules/issues/81)) ([10a65ab](https://github.com/uktrade/terraform-platform-modules/commit/10a65ab2f9699193a55eebcfc3415886c781fd20))
* DBTP-913 - Run terraform plan in environment pipelines ([#110](https://github.com/uktrade/terraform-platform-modules/issues/110)) ([a66f04a](https://github.com/uktrade/terraform-platform-modules/commit/a66f04ab4d4ddfde269406241ad79ea352175d16))
* DBTP-914 - Environment pipeline terraform apply ([#116](https://github.com/uktrade/terraform-platform-modules/issues/116)) ([a7f701c](https://github.com/uktrade/terraform-platform-modules/commit/a7f701c6f0fbe94ec34a715fdcbcf173b5214391))
* Make ``platform-helper copilot make-addons` run in the pipeline ([#125](https://github.com/uktrade/terraform-platform-modules/issues/125)) ([2da6d2e](https://github.com/uktrade/terraform-platform-modules/commit/2da6d2e1d5fe66c0ada7a97a2496ea72b10cef7d))


### Bug Fixes

* (DBTP-881) tweak monitoring tests to not require aws credentials ([#54](https://github.com/uktrade/terraform-platform-modules/issues/54)) ([7f4cf3f](https://github.com/uktrade/terraform-platform-modules/commit/7f4cf3f5cb0065c6bf09aa7e18fc4458c6d02da8))
* add default volume size for rds local variable ([#124](https://github.com/uktrade/terraform-platform-modules/issues/124)) ([92bdd32](https://github.com/uktrade/terraform-platform-modules/commit/92bdd32fc6fea68a7f67f82fd26ecd2972564f0b))
* Add domain provider alias to extensions unit test ([#86](https://github.com/uktrade/terraform-platform-modules/issues/86)) ([4a62675](https://github.com/uktrade/terraform-platform-modules/commit/4a62675df58a522717ec93a16fddcc42c0e8e3df))
* Change secrets type to SecureString ([#74](https://github.com/uktrade/terraform-platform-modules/issues/74)) ([36a0878](https://github.com/uktrade/terraform-platform-modules/commit/36a08785abfa9e2a6803ead04863281fe73464be))
* Dbtp 1016 update kms key alias name ([#131](https://github.com/uktrade/terraform-platform-modules/issues/131)) ([485792f](https://github.com/uktrade/terraform-platform-modules/commit/485792f1bfea2a0eb1a21be06a7f4f098f7a7b99))
* DBTP 951 fix prod prod cert bug ([#113](https://github.com/uktrade/terraform-platform-modules/issues/113)) ([38cb5e0](https://github.com/uktrade/terraform-platform-modules/commit/38cb5e0ebd6856de4626f1804479000668ac51a0))
* DBTP-839 Add tags for monitoring resources ([#102](https://github.com/uktrade/terraform-platform-modules/issues/102)) ([5f56af5](https://github.com/uktrade/terraform-platform-modules/commit/5f56af5e6ced9d5b39f460d7a8eb70fcd2932dab))
* DBTP-842 - Fix postgres permission on version 15 ([#71](https://github.com/uktrade/terraform-platform-modules/issues/71)) ([f18e826](https://github.com/uktrade/terraform-platform-modules/commit/f18e826d4a913d28573988d6aaaa7ad2dfeb87cc))
* DBTP-879 fix alb cert bug ([#56](https://github.com/uktrade/terraform-platform-modules/issues/56)) ([141b8ea](https://github.com/uktrade/terraform-platform-modules/commit/141b8ea70435752d3549832af46e3b84a1b546da))
* DBTP-884 - Rename Redis parameter ([#58](https://github.com/uktrade/terraform-platform-modules/issues/58)) ([bedef58](https://github.com/uktrade/terraform-platform-modules/commit/bedef5800708690994c440d7dac03af5f90db776))
* DBTP-893 Add option for additional domains and multi-provider fix. ([#77](https://github.com/uktrade/terraform-platform-modules/issues/77)) ([b042d22](https://github.com/uktrade/terraform-platform-modules/commit/b042d22310e6acfbb720d207cae6b2187eba2871))
* DBTP-896 - invalid opensearch config ([#73](https://github.com/uktrade/terraform-platform-modules/issues/73)) ([7e30b05](https://github.com/uktrade/terraform-platform-modules/commit/7e30b05036c2b3281ce28f58feaa1957c7c281a2))
* DBTP-931 Fix OpenSearch tests ([#98](https://github.com/uktrade/terraform-platform-modules/issues/98)) ([3267c5b](https://github.com/uktrade/terraform-platform-modules/commit/3267c5b8e1b9d06f8c6a18cbb8fd73217655b1d7))
* DBTP-951 add prod check for additional address list ([#111](https://github.com/uktrade/terraform-platform-modules/issues/111)) ([53c9639](https://github.com/uktrade/terraform-platform-modules/commit/53c963902d9586b7b95ed5d1e2b42fd920f5c740))
* DBTP-958 Straighten up Postgres plans ([#112](https://github.com/uktrade/terraform-platform-modules/issues/112)) ([e15e12d](https://github.com/uktrade/terraform-platform-modules/commit/e15e12de752d560a03d68e77d70a5fd826e96a07))
* dbtp-971 add rollback option for HA OS ([#117](https://github.com/uktrade/terraform-platform-modules/issues/117)) ([d742850](https://github.com/uktrade/terraform-platform-modules/commit/d742850813e6d66f992f78dd2a98695e5cea60c2))
* Parameterised account ID in unit test to allow tests to run in other accounts ([#84](https://github.com/uktrade/terraform-platform-modules/issues/84)) ([cec7852](https://github.com/uktrade/terraform-platform-modules/commit/cec7852be7c7e73393fb34b15a1b53eecb4a5ec5))
* Reinstate KMS alias ([#53](https://github.com/uktrade/terraform-platform-modules/issues/53)) ([6c8dd98](https://github.com/uktrade/terraform-platform-modules/commit/6c8dd98288d9a8a6e2100e7cb7dd33c9db8f69fe))


### Reverts

* "DBTP-958 Straighten up Postgres plans ([#112](https://github.com/uktrade/terraform-platform-modules/issues/112))" ([#132](https://github.com/uktrade/terraform-platform-modules/issues/132)) ([3df7ab9](https://github.com/uktrade/terraform-platform-modules/commit/3df7ab972473fd35b1754b0b0c1fb32e9c184a2c))

## [1.3.0](https://github.com/uktrade/terraform-platform-modules/compare/1.2.2...1.3.0) (2024-05-23)


### Features

* Changed to new assume role name ([#128](https://github.com/uktrade/terraform-platform-modules/issues/128)) ([ca17b44](https://github.com/uktrade/terraform-platform-modules/commit/ca17b44a867245fc527d0a577823fde517a994a9))
* DBTP-909 - Run `copilot env deploy` in pipeline ([#126](https://github.com/uktrade/terraform-platform-modules/issues/126)) ([15abc7b](https://github.com/uktrade/terraform-platform-modules/commit/15abc7b37d7c5a8eee70a38be7c8c076df2084df))
* DBTP-914 - Environment pipeline terraform apply ([#116](https://github.com/uktrade/terraform-platform-modules/issues/116)) ([a7f701c](https://github.com/uktrade/terraform-platform-modules/commit/a7f701c6f0fbe94ec34a715fdcbcf173b5214391))
* Make ``platform-helper copilot make-addons` run in the pipeline ([#125](https://github.com/uktrade/terraform-platform-modules/issues/125)) ([2da6d2e](https://github.com/uktrade/terraform-platform-modules/commit/2da6d2e1d5fe66c0ada7a97a2496ea72b10cef7d))


### Bug Fixes

* add default volume size for rds local variable ([#124](https://github.com/uktrade/terraform-platform-modules/issues/124)) ([92bdd32](https://github.com/uktrade/terraform-platform-modules/commit/92bdd32fc6fea68a7f67f82fd26ecd2972564f0b))
* Dbtp 1016 update kms key alias name ([#131](https://github.com/uktrade/terraform-platform-modules/issues/131)) ([485792f](https://github.com/uktrade/terraform-platform-modules/commit/485792f1bfea2a0eb1a21be06a7f4f098f7a7b99))
* DBTP-958 Straighten up Postgres plans ([#112](https://github.com/uktrade/terraform-platform-modules/issues/112)) ([e15e12d](https://github.com/uktrade/terraform-platform-modules/commit/e15e12de752d560a03d68e77d70a5fd826e96a07))


## [1.2.2](https://github.com/uktrade/terraform-platform-modules/compare/1.2.1...1.2.2) (2024-05-14)


### Bug Fixes

* dbtp-971 add rollback option for HA OS ([#117](https://github.com/uktrade/terraform-platform-modules/issues/117)) ([d742850](https://github.com/uktrade/terraform-platform-modules/commit/d742850813e6d66f992f78dd2a98695e5cea60c2))

## [1.2.1](https://github.com/uktrade/terraform-platform-modules/compare/1.2.0...1.2.1) (2024-05-07)


### Bug Fixes

* DBTP 951 fix prod prod cert bug ([#113](https://github.com/uktrade/terraform-platform-modules/issues/113)) ([38cb5e0](https://github.com/uktrade/terraform-platform-modules/commit/38cb5e0ebd6856de4626f1804479000668ac51a0))

## [1.2.0](https://github.com/uktrade/terraform-platform-modules/compare/1.1.0...1.2.0) (2024-05-03)


### Features

* 872 checkov baseline file ([#109](https://github.com/uktrade/terraform-platform-modules/issues/109)) ([975fa06](https://github.com/uktrade/terraform-platform-modules/commit/975fa066fe62304d4981b81cd370468fb14a8ac3))
* DBTP-910 - Environment log resource policy overrides ([#95](https://github.com/uktrade/terraform-platform-modules/issues/95)) ([fa64beb](https://github.com/uktrade/terraform-platform-modules/commit/fa64beb3a84d3eeb93d5a7bbe5916b6bec17c4ec))
* DBTP-911 Barebones environment pipeline module ([#81](https://github.com/uktrade/terraform-platform-modules/issues/81)) ([10a65ab](https://github.com/uktrade/terraform-platform-modules/commit/10a65ab2f9699193a55eebcfc3415886c781fd20))
* DBTP-913 - Run terraform plan in environment pipelines ([#110](https://github.com/uktrade/terraform-platform-modules/issues/110)) ([a66f04a](https://github.com/uktrade/terraform-platform-modules/commit/a66f04ab4d4ddfde269406241ad79ea352175d16))


### Bug Fixes

* DBTP-839 Add tags for monitoring resources ([#102](https://github.com/uktrade/terraform-platform-modules/issues/102)) ([5f56af5](https://github.com/uktrade/terraform-platform-modules/commit/5f56af5e6ced9d5b39f460d7a8eb70fcd2932dab))
* DBTP-931 Fix OpenSearch tests ([#98](https://github.com/uktrade/terraform-platform-modules/issues/98)) ([3267c5b](https://github.com/uktrade/terraform-platform-modules/commit/3267c5b8e1b9d06f8c6a18cbb8fd73217655b1d7))
* DBTP-951 add prod check for additional address list ([#111](https://github.com/uktrade/terraform-platform-modules/issues/111)) ([53c9639](https://github.com/uktrade/terraform-platform-modules/commit/53c963902d9586b7b95ed5d1e2b42fd920f5c740))

## [1.1.0](https://github.com/uktrade/terraform-platform-modules/compare/1.0.0...1.1.0) (2024-04-19)


### Features

* DBTP 843 vpc peering ([#83](https://github.com/uktrade/terraform-platform-modules/issues/83)) ([3684d87](https://github.com/uktrade/terraform-platform-modules/commit/3684d877bf631a19aaf214dee330c55f3a42c0fb))
* DBTP-892 release-please to automate releases/tagging ([#89](https://github.com/uktrade/terraform-platform-modules/issues/89)) ([a8d4754](https://github.com/uktrade/terraform-platform-modules/commit/a8d4754baf2de1d18e3d8ddedb90133627240383))


### Bug Fixes

* Add domain provider alias to extensions unit test ([#86](https://github.com/uktrade/terraform-platform-modules/issues/86)) ([4a62675](https://github.com/uktrade/terraform-platform-modules/commit/4a62675df58a522717ec93a16fddcc42c0e8e3df))
* DBTP-896 - invalid opensearch config ([#73](https://github.com/uktrade/terraform-platform-modules/issues/73)) ([7e30b05](https://github.com/uktrade/terraform-platform-modules/commit/7e30b05036c2b3281ce28f58feaa1957c7c281a2))
* Parameterised account ID in unit test to allow tests to run in other accounts ([#84](https://github.com/uktrade/terraform-platform-modules/issues/84)) ([cec7852](https://github.com/uktrade/terraform-platform-modules/commit/cec7852be7c7e73393fb34b15a1b53eecb4a5ec5))
