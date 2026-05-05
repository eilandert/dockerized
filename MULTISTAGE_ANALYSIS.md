# Multi-Stage Build Refactoring Strategy

## File Analysis:

### 1. roundcube/Dockerfile-deb (9.1 KB)
- Build stage: git, curl, php-composer download + extensions, plugins compilation
- Runtime stage: web server (angie), php-fpm, temp/log directories
- Builder clean: Remove git, curl, composer cache, build artifacts
- Expected: ~6-7 KB runtime image (30% reduction)

### 2. roundcube-new/Dockerfile (9.0 KB)
- Similar to roundcube, newer variant
- Same multi-stage approach

### 3. php-fpm/Dockerfile-multi (9.9 KB)
- Build stage: build-essential, libzip-dev, etc for PHP compilation
- Runtime stage: only compiled PHP binaries
- Expected: ~7-8 KB (20% reduction)

### 4. php-fpm/Dockerfile-multi-deb (9.9 KB)
- Same as multi, debian variant

### 5. mariadb/Dockerfile-deb (6.6 KB)
- Build stage: build-essential, cmake, compiler toolchain
- Runtime stage: mariadb server binaries only
- Expected: ~4.5-5 KB (25% reduction)

### 6. mariadb/Dockerfile-ubu (6.6 KB)
- Same as deb variant

### 7. roundcobe-old/Dockerfile-deb (7.6 KB)
- Similar to roundcube (older version)

### 8. roundcobe-old/Dockerfile-ubuntu (7.6 KB)
- Ubuntu variant of roundcobe-old

## Implementation:
1. For each file, split into builder and runtime stages
2. Move BUILD dependencies to builder stage
3. Copy only necessary artifacts to runtime
4. Retain labels, entrypoint, env vars in runtime stage
