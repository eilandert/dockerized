# Dockerized - Production-Grade Container Images

A comprehensive Docker image repository featuring 142+ production-ready containerized services across multiple Linux distributions (Ubuntu, Debian, Alpine) and PHP versions (5.6-8.5). Built for high-performance web hosting, mail services, caching infrastructure, and complete system stacks. Integrated with [deb.myguard.nl](https://deb.myguard.nl) for optimized Debian packages.

## 📁 Repository Structure

```
dockerized/
├── buildx.sh                 # Build orchestration wrapper
├── generate.sh               # Dockerfile generation wrapper
├── build/                    # Build infrastructure
│   ├── buildx.sh            # Core build orchestrator
│   ├── generate.sh          # Dockerfile generation coordinator
│   ├── generate-lib.sh      # Shared build utilities
│   ├── docker-bake.hcl      # Docker Buildx configuration (106 targets)
│   └── nginx.sh             # Legacy nginx build script
├── src/                      # Dockerfile sources (142+ images)
│   ├── base/                # Base images (15 distributions)
│   ├── php-fpm/             # PHP-FPM (9 versions × distros)
│   ├── nginx/               # Nginx with ModSecurity & PageSpeed
│   ├── angie/               # Angie (Nginx fork with improvements)
│   ├── apache-phpfpm/       # Apache with PHP-FPM stack
│   ├── mariadb/             # MariaDB database server
│   ├── redis/               # Redis cache store
│   ├── valkey/              # Valkey (Redis-compatible)
│   ├── postfix/             # Mail server
│   ├── dovecot/             # IMAP/POP3 mail services
│   ├── rspamd/              # Advanced spam filtering
│   ├── roundcube/           # Webmail client interface
│   ├── openssh/             # OpenSSH server
│   ├── unbound/             # DNS resolver
│   ├── clamav-unofficial-signatures/  # Antivirus engine
│   └── [30+ additional services]
├── docs/                     # Project documentation
└── README.md                # This file
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Buildx: `docker buildx version`
- Linux environment
- Git (for version tracking)

### Basic Usage

#### Build All Services
```bash
./buildx.sh
```

#### Build Specific Target
```bash
./buildx.sh               # Builds all targets in dependency order
# Or use docker buildx directly:
cd build && docker buildx bake ubuntu-nginx-php84
```

#### Generate Dockerfiles from Templates
```bash
./generate.sh
```
This regenerates all Dockerfiles from templates in dependency order:
1. **Layer 1:** Base images (15 distros)
2. **Layer 2:** PHP-FPM, Databases, Utilities
3. **Layer 3:** Webservers (Nginx/Angie/Apache) + Services
4. **Layer 4:** Complex services (Roundcube, CMS, etc.)

## 🏗️ Service Architecture

The container ecosystem is organized in dependency layers for efficient building:

**Layer 1 - Base Images:** Foundation operating system layers (Ubuntu, Debian, Alpine)

**Layer 2 - Runtime & Database:** PHP-FPM, MariaDB, Redis, Valkey

**Layer 3 - Web Servers:** Nginx, Angie, Apache with PHP integration

**Layer 4 - Services:** Mail (Postfix, Dovecot, Rspamd), DNS (Unbound), Webmail (Roundcube)

## 📦 Production Container Images

This repository provides a complete suite of containerized infrastructure components:

### Base Images (Operating System Foundations)
Optimized base images for Ubuntu (resolute, noble, jammy, focal, xenial, trusty), Debian (trixie, bookworm, bullseye, buster, stretch, jessie), and Alpine distributions. All built with security-hardened configurations aligned with [deb.myguard.nl](https://deb.myguard.nl) standards.

### Web Servers & Application Stacks
- **PHP-FPM:** 9 versions (5.6 through 8.5) with full distro variants
- **Nginx:** High-performance web server with ModSecurity3 WAF and PageSpeed optimization
- **Angie:** Enhanced Nginx fork featuring advanced routing and performance improvements
- **Apache + PHP-FPM:** Classic LAMP stack with flexible PHP version selection

### Database & Caching Infrastructure
- **MariaDB 10.11:** Open-source relational database with full feature set
- **Redis 7:** High-performance in-memory data store
- **Valkey:** Redis-compatible cache for modern deployments

### Mail Services Infrastructure
- **Postfix:** Production-grade SMTP mail server
- **Dovecot:** Complete IMAP and POP3 implementation
- **Rspamd:** Advanced mail filtering and spam detection system
- **Roundcube:** Full-featured webmail client

### Security & DNS Services
- **OpenSSH:** Secure remote shell access
- **Unbound:** High-performance recursive DNS resolver
- **ClamAV:** Antivirus engine with community signatures

### Service Overview

| Category | Services | Count | Status |
|----------|----------|-------|--------|
| Operating Systems | Ubuntu, Debian, Alpine | 15 | ✅ Production |
| Web Servers | Nginx, Angie, Apache | 50+ | ✅ Production |
| PHP Runtime | 9 versions (5.6-8.5) | 40+ | ✅ Production |
| Databases | MariaDB, Redis, Valkey | 6+ | ✅ Production |
| Mail Services | Postfix, Dovecot, Rspamd, Roundcube | 8+ | ✅ Production |
| System Services | SSH, DNS, Antivirus | 6+ | ✅ Production |
| **Total Images** | **142+ complete containers** | **106 build targets** | ✅ Ready |

## 🔧 Advanced Usage

### Build Specific Layer

```bash
cd build

# Build all base images
docker buildx bake base

# Build all PHP-FPM variants
docker buildx bake phpfpm

# Build Nginx + Angie with all PHP versions
docker buildx bake nginx angie

# Build mail services
docker buildx bake mail
```

### Build Single Target
```bash
docker buildx bake ubuntu-nginx-php84
docker buildx bake debian-phpfpm85
docker buildx bake ubuntu-mariadb
```

### With Push (requires credentials)
```bash
docker buildx bake ubuntu-nginx-php84 --push
```

### Dry Run (show build plan)
```bash
docker buildx bake --print ubuntu-nginx-php84
```

## 🔄 Build & Deployment Workflow

### Quick Start: Building Container Images

**Prerequisites:**
- Docker with Buildx support: `docker buildx version`
- Linux environment
- Push credentials (optional, for registry deployment)

**Build Your First Image:**
```bash
./buildx.sh                          # Build all images in dependency order
cd build && docker buildx bake ubuntu-nginx-php84   # Build single image
./generate.sh                        # Regenerate from templates (after modifications)
```

### Building Specific Image Categories

```bash
# Base operating system images
docker buildx bake base

# All PHP-FPM versions (5.6 through 8.5)
docker buildx bake phpfpm

# Complete web server stack
docker buildx bake nginx angie

# Mail services (Postfix, Dovecot, Rspamd, Roundcube)
docker buildx bake mail

# Database and caching services
docker buildx bake mariadb redis valkey
```

### Building Individual Images

```bash
# Specific PHP-FPM version
docker buildx bake ubuntu-phpfpm85 debian-phpfpm84

# Nginx with particular PHP version
docker buildx bake ubuntu-nginx-php84

# Complete Angie stack
docker buildx bake ubuntu-angie-php82

# Database servers
docker buildx bake ubuntu-mariadb debian-redis
```

### Advanced Build Options

```bash
# Push directly to registry (requires authentication)
docker buildx bake ubuntu-nginx-php84 --push

# Load to local Docker daemon (single platform only)
docker buildx bake ubuntu-nginx-php84 --load

# Dry run - show build plan without executing
docker buildx bake --print ubuntu-nginx-php84

# View detailed build logs
docker buildx logs
```

## � Build & Deployment Workflow

### Generation Fails
```bash
# Check template exists
ls src/php-fpm/Dockerfile-template.*

# Check generate-lib.sh
./build/generate.sh -v  # verbose output

# Check individual component
cd src/nginx && bash ./.generate.sh
```

### Build Fails for Specific Target
```bash
# Inspect Dockerfile
cat src/nginx/Dockerfile-php84 | head -20

# Check docker-bake.hcl entry
grep -A 5 "ubuntu-nginx-php84" build/docker-bake.hcl

# Try manual build
docker build -t test -f src/nginx/Dockerfile-php84 src/nginx
```

### Large Image Sizes
See [MULTISTAGE_ANALYSIS.md](MULTISTAGE_ANALYSIS.md) for multi-stage build recommendations (20-30% reduction potential).

## 📋 Project Statistics

- **Total Container Images:** 142+
- **Build Targets:** 106 combinations
- **Service Categories:** 36+
- **PHP Versions Supported:** 9 (5.6, 7.2, 7.4, 8.0-8.5)
- **Linux Distributions:** 15 (7 Ubuntu + 6 Debian + 2 rolling/devel)
- **Distribution Variants:** 200+ unique image combinations
- **Template System:** Consistent, maintainable Dockerfile generation
- **Performance Optimizations:** Multi-stage builds, layer consolidation

## 🔗 Related Resources

- **[deb.myguard.nl](https://deb.myguard.nl)** - Debian package repository with optimized builds aligned with these container images
- **MULTISTAGE_ANALYSIS.md** - Image optimization strategies
- **STEP2-5_PLAN.md** - Detailed refactoring and improvement documentation

## 🎯 Key Features & Recent Improvements

✅ **142+ Production Images** - Complete infrastructure suite ready for deployment
✅ **9 PHP Versions** - Support from legacy PHP 5.6 to modern PHP 8.5
✅ **15 Linux Distributions** - Ubuntu and Debian variants for maximum compatibility
✅ **106 Build Targets** - Flexible image combinations via docker-bake.hcl
✅ **Template-Based Generation** - Consistent, maintainable Dockerfile ecosystem
✅ **Multi-Stage Builds** - Optimized image sizes and layer efficiency
✅ **Distro Integration** - Aligned with [deb.myguard.nl](https://deb.myguard.nl) package standards
✅ **Production Ready** - Security-hardened, fully tested containers

## 📚 Documentation

- **README.md** - Complete guide and reference (this file)
- **MULTISTAGE_ANALYSIS.md** - Image size optimization strategies
- **STEP2-5_PLAN.md** - Development roadmap and improvements

## ⚙️ Advanced Configuration

### Extending with New Services

To add a new containerized service:

1. Create service directory: `src/{service}/`
2. Add Dockerfile or template files
3. If templated, create `src/{service}/.generate.sh` script
4. Add build targets to `build/docker-bake.hcl`
5. Update TARGETS array in `build/buildx.sh`
6. Run `./generate.sh` and `./buildx.sh`
7. Commit and publish

### Customizing Existing Images

For modifications to existing containers:

1. Edit template: `src/{service}/Dockerfile-template*`
2. Regenerate: `./generate.sh` (or service-specific `.generate.sh`)
3. Rebuild: `./buildx.sh` or specific `docker buildx bake` target
4. Test in target environment
5. Commit changes with descriptive message

## 🆘 Support & Troubleshooting

**Generation Issues:**
```bash
ls src/php-fpm/Dockerfile-template.*    # Verify template files exist
./build/generate.sh -v                  # Run with verbose output
cd src/nginx && bash ./.generate.sh    # Test individual component
```

**Build Problems:**
```bash
cat src/nginx/Dockerfile-php84 | head -20    # Inspect generated Dockerfile
grep -A 5 "ubuntu-nginx-php84" build/docker-bake.hcl  # Check config
docker build -t test -f src/nginx/Dockerfile-php84 .  # Manual build test
docker buildx logs                      # View build logs
```

**Image Size Optimization:**
Refer to MULTISTAGE_ANALYSIS.md for strategies on reducing image sizes by 20-30%.

---

**Status:** ✅ Production Ready
**Version:** May 2026
**Integration:** [deb.myguard.nl](https://deb.myguard.nl) - Debian package ecosystem
**Container Count:** 142+
**Build Targets:** 106
