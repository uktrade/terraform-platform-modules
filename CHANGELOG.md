# Changelog

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
