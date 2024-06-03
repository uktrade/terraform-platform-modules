#!/bin/bash
# Change /path/to/your/project to your actual project directory
docker run --rm -v "$(pwd):/workdir" -i trufflesecurity/trufflehog:latest git file:///workdir --since-commit HEAD --no-verification --fail

# Note: Replace /path/to/your/project with the actual path to your project directory on your host machine. This will mount your project directory to the workdir inside the Docker container. 