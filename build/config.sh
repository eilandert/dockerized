#!/bin/bash
# Docker base image configuration
# Central source of truth for all dockerized build parameters

# ============================================================================
# DISTRO VERSIONS
# ============================================================================

# Ubuntu LTS / Latest stable to use for base image FROM clause
export UBUNTULTS="noble"

# Debian stable version to use for base image FROM clause
export DEBIANSTABLE="trixie"

# ============================================================================
# DOCKER BASE IMAGE TAG NAMING
# ============================================================================
# These tags are used when referencing already-built base images in FROM lines
# e.g., FROM eilandert/ubuntu-base:rolling

export UBUNTU_BASE_TAG="rolling"       # Tag for ubuntu-base image
export DEBIAN_BASE_TAG="stable"        # Tag for debian-base image

# ============================================================================
# DOCKER REGISTRY CONFIGURATION
# ============================================================================

export DOCKER_REGISTRY_DOMAIN="docker.io"
export DOCKER_REGISTRY_USER="eilandert"

# Full registry prefix for use in image references
export DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY_DOMAIN}/${DOCKER_REGISTRY_USER}"

# ============================================================================
# IMAGE NAME PREFIXES
# ============================================================================

export IMAGE_PREFIX_UBUNTU_BASE="ubuntu-base"
export IMAGE_PREFIX_DEBIAN_BASE="debian-base"
export IMAGE_PREFIX_PHP_FPM="php-fpm"
export IMAGE_PREFIX_NGINX="nginx"
export IMAGE_PREFIX_ANGIE="angie"
export IMAGE_PREFIX_APACHE="apache-phpfpm"

# ============================================================================
# PHP VERSIONS TO BUILD
# ============================================================================
# Used by: php-fpm/.generate.sh, nginx/.generate.sh, apache-phpfpm/.generate.sh

declare -ga PHP_VERSIONS=(5.6 7.4 8.0 8.2 8.4 8.5)

# ============================================================================
# REPOSITORY INFORMATION
# ============================================================================

export GITHUB_REPO_URL="https://github.com/eilandert/dockerized"
export GITHUB_REPO_USER="eilandert"

# ============================================================================
# PHP VERSION REMOVAL MARKERS
# ============================================================================
# Used in php-fpm/.generate.sh to remove deprecated features per PHP version

declare -gA PHP_REMOVAL_MARKERS=(
    [5.6]="removedinphp72,removedinphp74,removedinphp80"
    [7.4]="removedinphp80"
    [8.0]=""
    [8.2]=""
    [8.4]=""
    [8.5]=""
)
