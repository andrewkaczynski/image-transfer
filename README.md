# Docker Image Transfer Script

A bash script to transfer Docker images between container registries using Skopeo. Supports batch transfers with comments and whitespace handling in the image list file.

## Table of Contents

- [Features](#features)
- [Dependencies](#dependencies)
- [Installation](#installation)
  - [Install Skopeo](#install-skopeo)
  - [Install the Script](#install-the-script)
- [Authentication](#authentication)
  - [Registry Login](#registry-login)
  - [Using Credentials in Script](#using-credentials-in-script)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Images File Format](#images-file-format)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Features

- ✅ Batch transfer of Docker images between registries
- ✅ Support for multi-architecture images
- ✅ Comment support in image list (lines starting with `#`)
- ✅ Automatic skipping of empty lines and whitespace
- ✅ Colored output for better readability
- ✅ Transfer summary with success/failure counts
- ✅ Error handling and validation

## Dependencies

The script requires the following tools to be installed:

- **bash** (version 4.0 or higher)
- **skopeo** (container image management tool)

### What is Skopeo?

Skopeo is a command-line utility for various operations on container images and image repositories. It can copy images between different storage mechanisms without requiring a Docker daemon.

## Installation

### Install Skopeo

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y skopeo
```

#### RHEL/CentOS/Rocky Linux

```bash
sudo yum install -y skopeo
```

For RHEL 8+:
```bash
sudo dnf install -y skopeo
```

#### Fedora

```bash
sudo dnf install -y skopeo
```

#### macOS

```bash
brew install skopeo
```

#### Arch Linux

```bash
sudo pacman -S skopeo
```

#### From Source

```bash
git clone https://github.com/containers/skopeo
cd skopeo
make binary-local
sudo make install
```

### Verify Skopeo Installation

```bash
skopeo --version
```

### Install the Script

1. Download the script:
```bash
curl -O https://your-repo/transfer-images.sh
# or
wget https://your-repo/transfer-images.sh
```

2. Make it executable:
```bash
chmod +x transfer-images.sh
```

3. (Optional) Move to a directory in your PATH:
```bash
sudo mv transfer-images.sh /usr/local/bin/transfer-images
```

## Authentication

### Registry Login

Before transferring images, you need to authenticate with both source and destination registries.

#### Method 1: Using Skopeo Login (Recommended)

```bash
# Login to source registry
skopeo login registry-a.example.com

# Login to destination registry
skopeo login registry-b.example.com
```

You'll be prompted for username and password. Credentials are stored in `${XDG_RUNTIME_DIR}/containers/auth.json` or `~/.docker/config.json`.

#### Method 2: Docker Login (Alternative)

If you have Docker installed, Skopeo can use Docker credentials:

```bash
docker login registry-a.example.com
docker login registry-b.example.com
```

#### Method 3: Using Environment Variables

```bash
export SOURCE_REGISTRY_USER="username"
export SOURCE_REGISTRY_PASS="password"
export DEST_REGISTRY_USER="username"
export DEST_REGISTRY_PASS="password"
```

### Using Credentials in Script

If you need to pass credentials directly in the script (for automation), you can modify the `skopeo copy` command:

```bash
skopeo copy \
  --src-creds "${SOURCE_REGISTRY_USER}:${SOURCE_REGISTRY_PASS}" \
  --dest-creds "${DEST_REGISTRY_USER}:${DEST_REGISTRY_PASS}" \
  --multi-arch all \
  "$SOURCE_IMAGE" \
  "$DEST_IMAGE"
```

**Security Note:** Avoid hardcoding credentials in scripts. Use environment variables or credential stores.

## Usage

### Basic Usage

```bash
./transfer-images.sh <source-registry> <dest-registry> [images-file]
```

**Arguments:**
- `source-registry`: Source registry URL (e.g., `registry-a.example.com` or `docker.io`)
- `dest-registry`: Destination registry URL (e.g., `registry-b.example.com`)
- `images-file`: Path to file containing image list (default: `images.txt`)

### Images File Format

Create a text file (e.g., `images.txt`) with one image per line:

```
# Format: namespace/image:tag

# Base images
library/nginx:latest
library/redis:7.0
library/postgres:15-alpine

# Application images
myapp/backend:v1.2.3
myapp/frontend:v1.2.3

# Empty lines and whitespace are ignored

# Monitoring stack
prometheus/prometheus:v2.45.0
grafana/grafana:10.0.0
```

**Rules:**
- One image per line in format: `namespace/image:tag`
- Lines starting with `#` are treated as comments
- Empty lines and whitespace-only lines are automatically skipped
- Leading/trailing whitespace is trimmed from image names

## Examples

### Example 1: Transfer from Docker Hub to Private Registry

```bash
# Login to registries
skopeo login docker.io
skopeo login registry.mycompany.com

# Create images.txt
cat > images.txt << EOF
# Base images from Docker Hub
library/nginx:latest
library/alpine:3.18
library/postgres:15
EOF

# Transfer images
./transfer-images.sh docker.io registry.mycompany.com images.txt
```

### Example 2: Transfer Between Private Registries

```bash
# Login to both registries
skopeo login old-registry.example.com
skopeo login new-registry.example.com

# Transfer images
./transfer-images.sh old-registry.example.com new-registry.example.com images.txt
```

### Example 3: Transfer with Custom Images File

```bash
./transfer-images.sh registry-a.com registry-b.com /path/to/my-images.txt
```

### Example 4: Transfer from Harbor to Quay.io

```bash
# Login to Harbor
skopeo login harbor.mycompany.com

# Login to Quay.io
skopeo login quay.io

# Create images list
cat > harbor-images.txt << EOF
# Production images
myproject/webapp:v2.1.0
myproject/api:v2.1.0
myproject/worker:v2.1.0
EOF

# Transfer
./transfer-images.sh harbor.mycompany.com quay.io harbor-images.txt
```

### Example 5: Automated Transfer with Credentials

```bash
#!/bin/bash

# Set credentials as environment variables
export SOURCE_REGISTRY_USER="source-user"
export SOURCE_REGISTRY_PASS="source-pass"
export DEST_REGISTRY_USER="dest-user"
export DEST_REGISTRY_PASS="dest-pass"

# Run transfer (if script modified to use these variables)
./transfer-images.sh registry-a.com registry-b.com images.txt
```

## Sample Output

```
==========================================
Docker Image Transfer
==========================================
Source Registry: registry-a.example.com
Destination Registry: registry-b.example.com
Images File: images.txt
==========================================

[1] Processing: library/nginx:latest
✓ Successfully transferred: library/nginx:latest

[2] Processing: library/redis:7.0
✓ Successfully transferred: library/redis:7.0

[3] Processing: myapp/backend:v1.2.3
✓ Successfully transferred: myapp/backend:v1.2.3

==========================================
Transfer Summary
==========================================
Total images processed: 3
Successful: 3
Failed: 0
==========================================
```

## Troubleshooting

### Issue: "skopeo: command not found"

**Solution:** Install Skopeo using the instructions in the [Installation](#install-skopeo) section.

### Issue: Authentication Failed

**Solution:** 
1. Verify your credentials are correct
2. Login using `skopeo login <registry>`
3. Check if your registry requires specific authentication methods

```bash
skopeo login --get-login registry.example.com
```

### Issue: "manifest unknown" or Image Not Found

**Solution:**
1. Verify the image exists in the source registry
2. Check the image name format (namespace/image:tag)
3. Test manually with:

```bash
skopeo inspect docker://registry-a.com/namespace/image:tag
```

### Issue: TLS Certificate Errors

**Solution:** If using self-signed certificates:

```bash
# Add --src-tls-verify=false or --dest-tls-verify=false
skopeo copy --src-tls-verify=false docker://source/image:tag docker://dest/image:tag
```

Modify the script to add these flags if needed.

### Issue: Rate Limiting

**Solution:** Add delays between transfers by modifying the script:

```bash
# Add after the skopeo copy command
sleep 2
```

### Issue: Large Images Failing

**Solution:** Increase timeout or retry failed transfers:

```bash
# Manually retry with:
skopeo copy --retry-times=3 docker://source/image:tag docker://dest/image:tag
```

## Advanced Usage

### Transfer Specific Image Digests

Instead of tags, you can specify digests in `images.txt`:

```
library/nginx@sha256:abc123...
myapp/backend@sha256:def456...
```

### Preserve Original Registry Path

If you want to preserve the source registry path structure, modify images in the list:

```
# This will copy from registry-a.com/prod/app:v1
# to registry-b.com/prod/app:v1
prod/app:v1
```

### Dry Run (Manual Testing)

Test a single image transfer before running the batch:

```bash
skopeo copy \
  --multi-arch all \
  docker://registry-a.com/myapp/image:tag \
  docker://registry-b.com/myapp/image:tag
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use and modify as needed.

## Related Tools

- [Skopeo Documentation](https://github.com/containers/skopeo)
- [Podman](https://podman.io/)
- [Buildah](https://buildah.io/)

## Support

For issues related to:
- **Script**: Open an issue in this repository
- **Skopeo**: Check [Skopeo GitHub Issues](https://github.com/containers/skopeo/issues)
- **Registry-specific**: Consult your registry provider's documentation