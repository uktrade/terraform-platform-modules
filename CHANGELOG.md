# Changelog

## [5.1.1](https://github.com/uktrade/terraform-platform-modules/compare/5.1.0...5.1.1) (2024-08-14)


### Bug Fixes

* Add elastic load balancer modify permission for pipeline  ([#200](https://github.com/uktrade/terraform-platform-modules/issues/200)) ([936270c](https://github.com/uktrade/terraform-platform-modules/commit/936270ced78bb22a0fb6cc09adfca605fe44b182))
* DBTP-1169 Added Validation for Domain Name Length ([#198](https://github.com/uktrade/terraform-platform-modules/issues/198)) ([39b33cc](https://github.com/uktrade/terraform-platform-modules/commit/39b33cc261cbc40a82d9548d79e00a2ebdc2e2f6))

## [5.1.0](https://github.com/uktrade/terraform-platform-modules/compare/5.0.1...5.1.0) (2024-08-08)


### Features

* DBTP-1137 trigger prod pipeline from non-prod pipeline ([#195](https://github.com/uktrade/terraform-platform-modules/issues/195)) ([d350039](https://github.com/uktrade/terraform-platform-modules/commit/d3500394a8035cc94221dee4de0a48e1bccc42b7))


### Bug Fixes

* DBTP-1143 Prevent Trigger Being Deleted on TF Plan/Apply ([#193](https://github.com/uktrade/terraform-platform-modules/issues/193)) ([9e7c870](https://github.com/uktrade/terraform-platform-modules/commit/9e7c8703745be0d1221b55b4b8af9567e0240614))
* DBTP-1149 - Cancel Outstanding Approval Requests before Performing a Terraform Plan ([#196](https://github.com/uktrade/terraform-platform-modules/issues/196)) ([afb1829](https://github.com/uktrade/terraform-platform-modules/commit/afb1829c28d22e01358a388f55de7f457640aadf))

## [5.0.1](https://github.com/uktrade/terraform-platform-modules/compare/5.0.0...5.0.1) (2024-07-18)


### Bug Fixes

* DBTP-1128 - Connection Error when trying to connect to Redis via Conduit ([#184](https://github.com/uktrade/terraform-platform-modules/issues/184)) ([65cc75d](https://github.com/uktrade/terraform-platform-modules/commit/65cc75deae092f0287a32daa7119069c880dffc4))
* DBTP-1128 Allow Pipeline Account to Create IAM Roles ([#189](https://github.com/uktrade/terraform-platform-modules/issues/189)) ([f95d923](https://github.com/uktrade/terraform-platform-modules/commit/f95d923dcf950350dda822b097f5ff25783f0adf))

## [5.0.0](https://github.com/uktrade/terraform-platform-modules/compare/4.2.0...5.0.0) (2024-07-12)


### ⚠ BREAKING CHANGES

* DBTP-1072 Change ADDITIONAL_IP_LIST to EGRESS_IPS ([#179](https://github.com/uktrade/terraform-platform-modules/issues/179))

### Features

* Removing all copilot commands from the terraform pipelines ([#185](https://github.com/uktrade/terraform-platform-modules/issues/185)) ([68506bc](https://github.com/uktrade/terraform-platform-modules/commit/68506bcc541b349285dc3f63b5a02b2ab8a3e5a2))


### Bug Fixes

* DBTP-1166 - Fix failing e2e tests ([#183](https://github.com/uktrade/terraform-platform-modules/issues/183)) ([d09a696](https://github.com/uktrade/terraform-platform-modules/commit/d09a6965499748edf38e67624247306129499cb8))


### Miscellaneous Chores

* DBTP-1072 Change ADDITIONAL_IP_LIST to EGRESS_IPS ([#179](https://github.com/uktrade/terraform-platform-modules/issues/179)) ([0db3962](https://github.com/uktrade/terraform-platform-modules/commit/0db39629412f4c75c437f91b072a09b7358b3718))

## [4.2.0](https://github.com/uktrade/terraform-platform-modules/compare/4.1.0...4.2.0) (2024-07-05)


### Features

* DBTP-1116 - support configurable backup_retention_period for postgres DB ([#173](https://github.com/uktrade/terraform-platform-modules/issues/173)) ([53afce8](https://github.com/uktrade/terraform-platform-modules/commit/53afce8dbfe524b423043e933980351d63acfdf0))

## [4.1.0](https://github.com/uktrade/terraform-platform-modules/compare/4.0.0...4.1.0) (2024-07-03)


### Features

* DBTP-1040 support s3 lifecycle policy ([#168](https://github.com/uktrade/terraform-platform-modules/issues/168)) ([73aa377](https://github.com/uktrade/terraform-platform-modules/commit/73aa3777b99e49564393b5e170ea5522fd593ad0))


### Bug Fixes

* DBTP-1040 - filter_prefix terraform variable is optional ([#178](https://github.com/uktrade/terraform-platform-modules/issues/178)) ([d0c5a00](https://github.com/uktrade/terraform-platform-modules/commit/d0c5a00fbbffe67c6a9d88c7f9f1de2d937e648b))

## [4.0.0](https://github.com/uktrade/terraform-platform-modules/compare/3.0.0...4.0.0) (2024-07-01)


### ⚠ BREAKING CHANGES

* DBTP-958 Straighten up Postgres plans (replay) ([#135](https://github.com/uktrade/terraform-platform-modules/issues/135))

### Features

* DBTP-1072 As a developer, when I create an API and a frontend service in the same environment and put the frontend service behind the IP Filter, I want the front end service to be able to access the api ([#165](https://github.com/uktrade/terraform-platform-modules/issues/165)) ([4bcce04](https://github.com/uktrade/terraform-platform-modules/commit/4bcce0421e5a3f305ec5384b8b0987f49ec1113a))
* DBTP-958 Straighten up Postgres plans (replay) ([#135](https://github.com/uktrade/terraform-platform-modules/issues/135)) ([1d566f1](https://github.com/uktrade/terraform-platform-modules/commit/1d566f13c6184caf7f73a770457f08affd0c7739))


### Bug Fixes

* Add ListCertificates permission ([#170](https://github.com/uktrade/terraform-platform-modules/issues/170)) ([4f53a0c](https://github.com/uktrade/terraform-platform-modules/commit/4f53a0c120940f633d80392423afd7654d702e65))
* DBTP-1089 Move to shared log resource policy ([#166](https://github.com/uktrade/terraform-platform-modules/issues/166)) ([9527e75](https://github.com/uktrade/terraform-platform-modules/commit/9527e75131d001ca6ed52e3dd4d1268e2701eea5))
* DBTP-1104 Ensure Terraform plan resources are available during apply stage. ([#174](https://github.com/uktrade/terraform-platform-modules/issues/174)) ([7d2b397](https://github.com/uktrade/terraform-platform-modules/commit/7d2b397099ba327414bde68c28727d5338a0fa35))
* Don't generate environment Terraform manifest for demodjango toolspr ([#172](https://github.com/uktrade/terraform-platform-modules/issues/172)) ([f57b122](https://github.com/uktrade/terraform-platform-modules/commit/f57b122a3ef05557ddccab146bb166def492902a))
* Missing IAM permissions for pipeline to modify database ([#176](https://github.com/uktrade/terraform-platform-modules/issues/176)) ([33cd536](https://github.com/uktrade/terraform-platform-modules/commit/33cd5360afd4204b5ea43333834c13bf33a01708))

## [3.0.0](https://github.com/uktrade/terraform-platform-modules/compare/2.3.0...3.0.0) (2024-06-21)


### ⚠ BREAKING CHANGES

* New config file and support for multiple pipelines ([#159](https://github.com/uktrade/terraform-platform-modules/issues/159))

### Features

* New config file and support for multiple pipelines ([#159](https://github.com/uktrade/terraform-platform-modules/issues/159)) ([4399fc9](https://github.com/uktrade/terraform-platform-modules/commit/4399fc9ae2b25612ef06ca4bd1ae2938dcfdc944))

## [2.3.0](https://github.com/uktrade/terraform-platform-modules/compare/2.2.1...2.3.0) (2024-06-20)


### Features

* DBTP-946 vpc store nat egress ips in parameter store ([#157](https://github.com/uktrade/terraform-platform-modules/issues/157)) ([2a7b595](https://github.com/uktrade/terraform-platform-modules/commit/2a7b59512880bb555d8dc8fc9e5be9987ed6f6f4))


### Bug Fixes

* add prometheus-policy to plans.yml ([#163](https://github.com/uktrade/terraform-platform-modules/issues/163)) ([d98d468](https://github.com/uktrade/terraform-platform-modules/commit/d98d468aa50fd44e71796c02df00680e393da658))

## [2.2.1](https://github.com/uktrade/terraform-platform-modules/compare/2.2.0...2.2.1) (2024-06-14)


### Bug Fixes

* make readonly lambda invocation depend on app user invocation ([#160](https://github.com/uktrade/terraform-platform-modules/issues/160)) ([1e0fe0d](https://github.com/uktrade/terraform-platform-modules/commit/1e0fe0d19792049ceccd6f6326620e85e13480f1))

## [2.2.0](https://github.com/uktrade/terraform-platform-modules/compare/2.1.0...2.2.0) (2024-06-06)


### Features

* dbtp-928 option to disable cdn ([#155](https://github.com/uktrade/terraform-platform-modules/issues/155)) ([e86fd89](https://github.com/uktrade/terraform-platform-modules/commit/e86fd8900b7372c47d3859ce0b236c40eb04a285))

## [2.1.0](https://github.com/uktrade/terraform-platform-modules/compare/2.0.0...2.1.0) (2024-06-04)


### Features

* Pipeline slack alerts ([#150](https://github.com/uktrade/terraform-platform-modules/issues/150)) ([ead58f3](https://github.com/uktrade/terraform-platform-modules/commit/ead58f39b6faecd8ffcd9fb18cc607416d20770b))


### Bug Fixes

* Fixed extensions module that was broken on the cdn declaration ([#152](https://github.com/uktrade/terraform-platform-modules/issues/152)) ([c76ac9f](https://github.com/uktrade/terraform-platform-modules/commit/c76ac9f2aedf06bdb35db6c7615b4770d6e7c2b0))

## [2.0.0](https://github.com/uktrade/terraform-platform-modules/compare/1.5.0...2.0.0) (2024-06-04)


### ⚠ BREAKING CHANGES

* DBTP-928 Add CDN endpoint module ([#141](https://github.com/uktrade/terraform-platform-modules/issues/141))

### Features

* DBTP-928 Add CDN endpoint module ([#141](https://github.com/uktrade/terraform-platform-modules/issues/141)) ([20d6f5b](https://github.com/uktrade/terraform-platform-modules/commit/20d6f5b9d25c2a94bb02d38ad862a5fa5fb9f224))

## [1.5.0](https://github.com/uktrade/terraform-platform-modules/compare/1.4.0...1.5.0) (2024-05-31)

### Features

* DBTP-434 Add Redis endpoint with ssl_cert_reqs parameter ([#147](https://github.com/uktrade/terraform-platform-modules/issues/147)) ([f7470e8](https://github.com/uktrade/terraform-platform-modules/commit/f7470e821c262de4ce50b0f1ebb30563ce145c88))

### Bug Fixes

* DBTP-1010 Readonly postgres user doesn't have read perms ([#140](https://github.com/uktrade/terraform-platform-modules/issues/140)) ([1628440](https://github.com/uktrade/terraform-platform-modules/commit/1628440ab653a27ecc205cad4a32750cf7a22b62))
* DBTP-944 Correct Redis tags ([#147](https://github.com/uktrade/terraform-platform-modules/issues/147)) ([f7470e8](https://github.com/uktrade/terraform-platform-modules/commit/f7470e821c262de4ce50b0f1ebb30563ce145c88))

## [1.4.0](https://github.com/uktrade/terraform-platform-modules/compare/1.3.0...1.4.0) (2024-05-30)


### Features

* Enable Intelligent-Tiering to allow parameters with &gt; 4096 characters ([#139](https://github.com/uktrade/terraform-platform-modules/issues/139)) ([9be7595](https://github.com/uktrade/terraform-platform-modules/commit/9be7595e491a50fa65aebdc38e99494880b559a5))


### Bug Fixes

* DBTP-1010 Readonly postgres user doesn't have read perms ([#140](https://github.com/uktrade/terraform-platform-modules/issues/140)) ([1628440](https://github.com/uktrade/terraform-platform-modules/commit/1628440ab653a27ecc205cad4a32750cf7a22b62))
* DBTP-998 - Move pipeline to platform-sandbox ([#137](https://github.com/uktrade/terraform-platform-modules/issues/137)) ([e97dcd4](https://github.com/uktrade/terraform-platform-modules/commit/e97dcd41c8face3e5dbbf1be1aa367b5c6861057))

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
