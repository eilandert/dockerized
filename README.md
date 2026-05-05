# Dockerized - Comprehensive Multi-Container Repository

A production-ready Docker build infrastructure with 142+ containerized services, automated generation from templates, and support for multiple Linux distributions (Ubuntu, Debian, Alpine) and PHP versions (5.6-8.5).

## 📁 Project Structure

```
dockerized/
├── buildx.sh                 # Main build orchestration wrapper (entry point)
├── generate.sh               # Dockerfile generation wrapper
├── build/                    # Build infrastructure and scripts
│   ├── buildx.sh            # Core build orchestrator with layer management
│   ├── generate.sh          # Dockerfile generation coordinator
│   ├── generate-lib.sh      # Shared utilities for template processing
│   ├── docker-bake.hcl      # Docker Buildx HCL2 configuration (106 targets)
│   └── nginx.sh             # Legacy nginx build script
├── src/                      # All Dockerfile sources (142+ containers)
│   ├── base/                # Base images (15 distributions)
│   ├── php-fpm/             # PHP-FPM (9 versions × 2 distros = 18+)
│   ├── nginx/               # Nginx with ModSecurity & PageSpeed
│   ├── angie/               # Angie (Nginx fork)
│   ├── apache-phpfpm/       # Apache with PHP-FPM
│   ├── mariadb/             # MariaDB database
│   ├── redis/               # Redis cache
│   ├── valkey/              # Valkey (Redis alternative)
│   ├── postfix/             # Mail server
│   ├── dovecot/             # IMAP/POP3
│   ├── rspamd/              # Spam filter
│   ├── roundcube/           # Webmail client
│   ├── openssh/             # SSH server
│   ├── unbound/             # DNS resolver
│   ├── clamav-unofficial-signatures/  # Antivirus
│   └── [30+ more services]
├── docs/                     # Documentation
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

## 🏗️ Build Infrastructure

### Architecture

The build system uses **layered dependency management**:

```
Base Images (Layer 1)
├── Ubuntu: resolute, noble, jammy, focal, bionic, xenial, trusty
├── Debian: trixie, bookworm, bullseye, buster, stretch, jessie
└── Other: devel, rolling

Dependencies
    ↓

PHP-FPM & Databases (Layer 2)
├── PHP-FPM: 9 versions (5.6, 7.2, 7.4, 8.0-8.5)
├── PHP-FPM Multi (all versions in one)
├── MariaDB 10.11
├── Redis 7
└── Valkey (Redis alternative)

Dependencies
    ↓

Web Servers (Layer 3)
├── Nginx (ModSecurity3 + PageSpeed)
├── Angie (Nginx fork with enhancements)
├── Apache + PHP-FPM
├── Webmail (Roundcube)
└── CMS & Tools

Services
    ↓

Mail & DNS (Layer 3)
├── Postfix (SMTP)
├── Dovecot (IMAP/POP3)
├── Rspamd (Spam filter)
└── Unbound (DNS resolver)
```

### Dockerfile Generation

**Template-Based System** ensures consistency:

- **Template Files:** Located in `src/{service}/`
  - `Dockerfile.template` or `Dockerfile-template.php`
  - Marker placeholders: `#MARKER#` replaced during generation
  - Supports version-specific markers (e.g., `#removedinphp72#`)

- **Generation Process:**
  ```
  Templates → process_template() → safe_sed() → Generated Dockerfiles
  ```

- **Multi-Variant Support:**
  - Ubuntu + Debian variants (18 files per PHP version)
  - Multi-PHP build (all versions combined)
  - Version-specific cleanup markers

### Build Configuration

**docker-bake.hcl** defines 106 build targets:
- **Groups:** default, base-current, base, phpfpm, multiphp, nginx, angie, nginx-php, apache, etc.
- **Tags:** Comprehensive versioning (e.g., `php-fpm:8.4`, `nginx:php8.4`, `nginx:deb-php8.4`)
- **Platforms:** Multi-architecture support ready

### Build Optimization

**STEP 5 Improvements:**
- **RUN Consolidation:** 10+ layers removed
  - docker-cms: 7 RUN → 3 RUN (57% reduction)
  - wosbotv4: 4 RUN → 3 RUN (25% reduction)
- **Layer Efficiency:** Smaller metadata, faster builds
- **Cache Optimization:** Dependency-based layering

**STEP 3: Multi-Stage Builds Framework** (Ready for Implementation)
- **Target:** 8 large images (roundcube, php-fpm-multi, mariadb, etc.)
- **Expected Savings:** 20-30% image size reduction
- **Documentation:** See [MULTISTAGE_ANALYSIS.md](MULTISTAGE_ANALYSIS.md)

## 📦 Available Services

### Base Infrastructure
| Service | Type | Variants | Status |
|---------|------|----------|--------|
| Ubuntu Base | Base Image | resolute, noble, jammy, focal, bionic, xenial, trusty | ✅ Active |
| Debian Base | Base Image | trixie, bookworm, bullseye, buster, stretch, jessie | ✅ Active |

### Web Servers
| Service | Versions | Variants | Status |
|---------|----------|----------|--------|
| PHP-FPM | 5.6, 7.2, 7.4, 8.0-8.5 | ubuntu/debian + multi | ✅ Active |
| Nginx | - | base, php56-85, multi | ✅ Active |
| Angie | - | base, php56-85, multi | ✅ Active |
| Apache+PHP | 5.6, 7.2, 7.4, 8.0-8.5 | ubuntu/debian + multi | ✅ Active |

### Databases
| Service | Version | Variants | Status |
|---------|---------|----------|--------|
| MariaDB | 10.11 | ubuntu/debian | ✅ Active |
| Redis | 7 | ubuntu/debian | ✅ Active |
| Valkey | Latest | ubuntu/debian | ✅ Active |

### Services
| Service | Type | Variants | Status |
|---------|------|----------|--------|
| Postfix | Mail | ubuntu/debian | ✅ Active |
| Dovecot | IMAP/POP3 | ubuntu/debian | ✅ Active |
| Rspamd | Spam Filter | alpine/debian | ✅ Active |
| Roundcube | Webmail | debian | ✅ Active |
| OpenSSH | SSH Server | debian | ✅ Active |
| Unbound | DNS | alpine | ✅ Active |
| ClamAV | Antivirus | debian | ✅ Active |

### Total Count
- **142+ Dockerfiles** across 36 service categories
- **106 Build Targets** in docker-bake.hcl
- **30+ Services** available

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

## 🔄 Workflow: Adding PHP 8.5 Support

**STEP 1: PHP Version Addition** - Done ✅
```bash
# Files updated:
src/php-fpm/.generate.sh          # Added 8.5 to VERSIONS array
src/nginx/.generate.sh            # Added 8.5 variant generation
src/apache-phpfpm/.generate.sh    # Added 8.5 support
build/docker-bake.hcl             # Added 12 PHP 8.5 targets
build/buildx.sh                   # Added 8 PHP 8.5 build targets

# Result: 8 new Dockerfiles generated automatically
```

### Regeneration After Template Changes

If you modify templates in `src/{service}/Dockerfile-template`:

```bash
# Regenerate affected service
./generate.sh

# This will:
# 1. Process templates with proper markers
# 2. Create Ubuntu & Debian variants
# 3. Apply version-specific cleanup
# 4. Commit changes to git
# 5. Push to remote
```

## 📊 Generation System Deep Dive

### Template Processing

**Step 1: Copy Template**
```bash
cp src/php-fpm/Dockerfile-template.php Dockerfile-8.5
```

**Step 2: Apply Substitutions**
```bash
safe_sed "#PHPVERSION#" "8.5" Dockerfile-8.5
```

**Step 3: Remove Version-Specific Markers**
```bash
remove_markers Dockerfile-8.5 "#removedinphp72#"
remove_markers Dockerfile-8.5 "#removedinphp74#"
```

**Step 4: Create Debian Variant**
```bash
cp Dockerfile-8.5 Dockerfile-8.5-deb
safe_sed "eilandert/ubuntu-base:rolling" "eilandert/debian-base:stable" Dockerfile-8.5-deb
```

### Multi-PHP Variant Generation

Combines all PHP versions into single Dockerfile:

```bash
# Header (FROM, initial RUN, etc.)
cat Dockerfile-template.header > Dockerfile-multi

# Each PHP version's packages
for version in 5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4 8.5; do
    cat Dockerfile-template.generated.php${version} >> Dockerfile-multi
done

# Footer (cleanup, entrypoint)
cat Dockerfile-template.footer >> Dockerfile-multi
```

Result: Single image with all PHP versions available.

## 🛠️ Maintenance

### Update Dependencies
```bash
# Check for outdated packages
cd src/php-fpm && grep -E "php[0-9]+-" Dockerfile-template.php

# Modify template
nano Dockerfile-template.php

# Regenerate all variants
./generate.sh
```

### Dockerfile Naming Convention

**Uniform Format** (STEP 2 complete ✅):
- Ubuntu variants: `Dockerfile` (no suffix)
- Debian variants: `Dockerfile-deb`
- Version variants: `Dockerfile-{version}`
- Debian+Version: `Dockerfile-{version}-deb`

Examples:
```
php-fpm/Dockerfile-8.4          # PHP 8.4 Ubuntu
php-fpm/Dockerfile-8.4-deb      # PHP 8.4 Debian
nginx/Dockerfile                 # Nginx Ubuntu base
nginx/Dockerfile-deb            # Nginx Debian base
nginx/Dockerfile-php84          # Nginx with PHP 8.4 Ubuntu
nginx/Dockerfile-php84-deb      # Nginx with PHP 8.4 Debian
```

### Code Quality Improvements

**Generate-lib.sh** utilities:
```bash
safe_sed pattern replacement file         # Safe sed with | delimiter
process_template template output key=val  # Template processing
remove_markers file marker                # Marker removal
compose_dockerfile output hdr body ftr    # Header+body+footer assembly
create_debian_variant ubuntu debian       # Standardized variant creation
validate_templates template1 template2    # Template validation
```

## 📝 Docker Buildx Tips

### Create Custom Builder
```bash
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

### Push to Registry
```bash
# Set push flag in buildx.sh or run:
docker buildx bake ubuntu-nginx-php84 --push
```

### Load Locally (single platform)
```bash
docker buildx bake ubuntu-nginx-php84 --load
```

### Inspect Build Configuration
```bash
cd build
docker buildx bake --print ubuntu-nginx-php84
```

## 🚨 Troubleshooting

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

- **Total Dockerfiles:** 142+
- **Build Targets:** 106
- **Service Categories:** 36
- **PHP Versions:** 9 (5.6, 7.2, 7.4, 8.0-8.5)
- **Linux Distros:** 15 (7 Ubuntu + 6 Debian + 2 rolling)
- **Distribution Variants:** 200+ unique images
- **Template Markers:** 40+ version-specific conditions
- **Optimized Layers:** 10+ removed via RUN consolidation

## 🎯 Recent Improvements (May 2026)

✅ **STEP 1:** PHP 8.5 Support
- Added to all generation scripts
- 12 new docker-bake.hcl targets
- 8 new Dockerfiles generated

✅ **STEP 2:** Uniform Dockerfile Naming
- Standardized 79 files to `-deb`/`-ubu` format
- 103 references updated
- All generators updated

✅ **STEP 3:** Multi-Stage Build Framework
- Documentation prepared
- 8 target files identified for 20-30% size reduction

✅ **STEP 4:** Generation Script Refactoring
- 3 new utility functions added
- Duplicate code removed
- Code reusability improved

✅ **STEP 5:** RUN Consolidation
- 10+ layers removed
- 57% reduction in docker-cms
- Faster builds, smaller metadata

✅ **STEP 6:** Project Reorganization
- All 142 Dockerfiles moved to `src/`
- All build scripts moved to `build/`
- Top-level `buildx.sh` and `generate.sh` wrappers created
- All paths updated for new structure

## 📚 Documentation Files

- **[README.md](README.md)** - This file (comprehensive walkthrough)
- **[MULTISTAGE_ANALYSIS.md](MULTISTAGE_ANALYSIS.md)** - Multi-stage build strategy
- **[STEP2-5_PLAN.md](STEP2-5_PLAN.md)** - Refactoring plan details

## 🤝 Contributing

When adding new services:

1. Create directory: `src/{service}/`
2. Add Dockerfiles or template
3. Create `src/{service}/.generate.sh` if templated
4. Add targets to `build/docker-bake.hcl`
5. Update TARGETS array in `build/buildx.sh`
6. Run `./generate.sh` and `./buildx.sh`
7. Commit and push

## 📞 Support

- Check logs: `docker buildx logs`
- Inspect Dockerfile: `cat src/{service}/Dockerfile*`
- Review config: `grep {target} build/docker-bake.hcl`
- Check template: `ls src/{service}/Dockerfile-template*`

---

**Last Updated:** May 5, 2026  
**Status:** Production Ready  
**License:** [Your License]  
**Maintainer:** [Your Team]
