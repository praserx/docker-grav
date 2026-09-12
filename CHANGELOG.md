# v2.0.26-1

- PHP: v8.3.33
- Grav: v2.0.26
- Image: added `linux/amd64` and `linux/arm64` builds
- Image: run nginx, PHP-FPM, and Supervisor without requiring root privileges for Kubernetes deployments
- Image: added a Makefile with configuration checks and HTTP smoke tests

# v2.0.26

- PHP: v8.3.33
- Grav: v2.0.26

# v2.0.24

- PHP: v8.3.33
- Grav: v2.0.24

# v1.7.45

- PHP: v8.2.17
- Grav: v1.7.45

# v1.7.44

- PHP: v8.2.15
- Grav: v1.7.44

# v1.7.43

- PHP: v8.2.11
- Grav: v1.7.43

# v1.7.42.3

- PHP: v8.2.8
- Grav: v1.7.42.3

# v1.7.41.2

- PHP: v8.2.7
- Grav: v1.7.41.2
- Switched from Apache to NGINX (due to some session start issues)
  - Switched base image from php:8.2.6-apache to php:8.2.7-fpm

# v1.7.41.1

- PHP: v8.2.6
- Grav: v1.7.41.1
