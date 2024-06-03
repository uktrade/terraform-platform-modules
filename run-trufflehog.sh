#!/bin/bash
docker run --rm -v "$(pwd):/workdir" -i trufflesecurity/trufflehog:latest git file:///workdir --since-commit HEAD --no-verification --fail
