# STEPS 2-5: Dockerfile Refactoring Plan

## STEP 2: Uniform Dockerfile Naming (-deb/-ubu postfix)

### Target Files (rename to new format):
- php-fpm/Dockerfile-*debian → Dockerfile-*-deb
- nginx/Dockerfile-*debian → Dockerfile-php*-deb
- apache-phpfpm/Dockerfile-*debian → Dockerfile-*-deb
- mariadb/Dockerfile.debian → Dockerfile-deb
- mariadb/Dockerfile.ubuntu → Dockerfile-ubu
- redis/Dockerfile.debian → Dockerfile-deb
- redis/Dockerfile.ubuntu → Dockerfile-ubu
- valkey/Dockerfile.debian → Dockerfile-deb
- valkey/Dockerfile.ubuntu → Dockerfile-ubu
- postfix/Dockerfile-ubuntu → Dockerfile-ubu (if exists)
- dovecot/Dockerfile-ubuntu → Dockerfile-ubu (if exists)
- roundcube/Dockerfile-debian → Dockerfile-deb (if exists)
- rspamd-git/Dockerfile-ubuntu → Dockerfile-ubu (if exists)
- angie/Dockerfile-*debian → Dockerfile-php*-deb

### Process:
1. Identify all *-debian and .debian files
2. Rename files in each directory
3. Update docker-bake.hcl dockerfile references
4. Update .generate.sh scripts to output new names
5. Run generate.sh to verify

## STEP 3: Multi-Stage Builds for 8 Large Files

### Target Files (for multi-stage refactoring):
1. roundcube/Dockerfile-debian (9.3 KB)
2. roundcube-new/Dockerfile (9.2 KB)
3. php-fpm/Dockerfile-multi (8.8 KB)
4. php-fpm/Dockerfile-multidebian (8.8 KB)
5. mariadb/Dockerfile.debian (7.0 KB)
6. mariadb/Dockerfile.ubuntu (7.0 KB)
7. roundcobe-old/Dockerfile-debian (7.7 KB)
8. roundcobe-old/Dockerfile-ubuntu (7.7 KB)

### Strategy:
- Separate build stage (with dev tools, compilers)
- Runtime stage (only production binaries)
- Expected: 20-30% image size reduction

## STEP 4: Generation Script Refactoring

### Tasks:
1. Extract header/footer composition function to generate-lib.sh
2. Convert php-fpm/.generate.sh to declarative VARIANTS config
3. Fix apache-phpfpm/.generate.sh duplicate section (already detected)
4. Add template validation function calls

## STEP 5: Additional RUN Consolidation

### Target Files:
- php-fpm/Dockerfile-multi: 11 RUN → 3
- php-fpm/Dockerfile-multidebian: 11 RUN → 3
- docker-cms/Dockerfile: 7 RUN → 2
- Others as identified

### Expected Savings:
- ~10 layer reduction total
- Faster builds
- Smaller metadata
