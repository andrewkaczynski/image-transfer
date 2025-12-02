#!/bin/bash

# Docker Image Transfer Script using Skopeo
# Usage: ./transfer-images.sh <source-registry> <dest-registry> [images-file]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
IMAGES_FILE="${3:-images.txt}"
SOURCE_REGISTRY="${1:-}"
DEST_REGISTRY="${2:-}"

# Function to print usage
usage() {
    echo "Usage: $0 <source-registry> <dest-registry> [images-file]"
    echo ""
    echo "Arguments:"
    echo "  source-registry  Source registry URL (e.g., registry-a.example.com)"
    echo "  dest-registry    Destination registry URL (e.g., registry-b.example.com)"
    echo "  images-file      Path to file containing image list (default: images.txt)"
    echo ""
    echo "Images file format:"
    echo "  - One image per line in format: namespace/image:tag"
    echo "  - Lines starting with # are treated as comments"
    echo "  - Empty lines and whitespace-only lines are skipped"
    echo ""
    echo "Example images.txt:"
    echo "  # Base images"
    echo "  library/nginx:latest"
    echo "  library/redis:7.0"
    echo "  "
    echo "  # Application images"
    echo "  myapp/backend:v1.2.3"
    exit 1
}

# Check if skopeo is installed
if ! command -v skopeo &> /dev/null; then
    echo -e "${RED}Error: skopeo is not installed${NC}"
    echo "Please install skopeo first:"
    echo "  - Ubuntu/Debian: apt-get install skopeo"
    echo "  - RHEL/CentOS: yum install skopeo"
    echo "  - macOS: brew install skopeo"
    exit 1
fi

# Validate arguments
if [[ -z "$SOURCE_REGISTRY" ]] || [[ -z "$DEST_REGISTRY" ]]; then
    echo -e "${RED}Error: Both source and destination registries must be specified${NC}"
    echo ""
    usage
fi

# Check if images file exists
if [[ ! -f "$IMAGES_FILE" ]]; then
    echo -e "${RED}Error: Images file '$IMAGES_FILE' not found${NC}"
    exit 1
fi

# Initialize counters
TOTAL=0
SUCCESS=0
FAILED=0
SKIPPED=0

echo "=========================================="
echo "Docker Image Transfer"
echo "=========================================="
echo "Source Registry: $SOURCE_REGISTRY"
echo "Destination Registry: $DEST_REGISTRY"
echo "Images File: $IMAGES_FILE"
echo "=========================================="
echo ""

# Read images file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and lines with only whitespace
    if [[ -z "${line// /}" ]]; then
        continue
    fi
    
    # Skip comment lines (starting with #)
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Trim whitespace
    image=$(echo "$line" | xargs)
    
    # Skip if empty after trimming
    if [[ -z "$image" ]]; then
        continue
    fi
    
    TOTAL=$((TOTAL + 1))
    
    echo -e "${YELLOW}[$TOTAL] Processing: $image${NC}"
    
    SOURCE_IMAGE="docker://${SOURCE_REGISTRY}/${image}"
    DEST_IMAGE="docker://${DEST_REGISTRY}/${image}"
    
    # Transfer image using skopeo
    if skopeo copy --insecure-policy --format=oci "$SOURCE_IMAGE" "$DEST_IMAGE"; then
        echo -e "${GREEN}✓ Successfully transferred: $image${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}✗ Failed to transfer: $image${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
    
done < "$IMAGES_FILE"

# Print summary
echo "=========================================="
echo "Transfer Summary"
echo "=========================================="
echo "Total images processed: $TOTAL"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo "Failed: $FAILED"
fi
echo "=========================================="

# Exit with error if any transfers failed
if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
