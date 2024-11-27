#!/usr/bin/env bash
set -e

architectures=("amd64" "armhf" "armv7" "aarch64" "i386")
addons_yaml_file=.addons.yml
output_file="created_images.txt"
> "$output_file"

# Extract repository and image pairs
mapfile -t addons < <(awk '/repository:/ {repo=$2} /image:/ {img=$2; print repo ";" img}' $addons_yaml_file)

for addon in "${addons[@]}"; do
  repository=$(echo "$addon" | cut -d';' -f1)
  image=$(echo "$addon" | cut -d';' -f2)

  for arch in "${architectures[@]}"; do
    image_with_arch=${image//\{arch\}/$arch}
    latest_image_version=$(curl --silent -qI "https://github.com/${repository}/releases/latest" | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')
    full_image=${image_with_arch}:${latest_image_version}

    echo "Download $full_image"

    if ! podman pull "$full_image"; then
      echo "Failed to pull $full_image. Skipping this image."
      continue
    fi

    container_id=$(podman create "$full_image")
    podman start "$container_id"


    podman exec "$container_id" sh -c "mkdir -p /etc/cont-init.d"
    podman cp scripts/notify-migration.sh "${container_id}:/etc/cont-init.d/00-migration.sh"
    podman exec "$container_id" sh -c "chmod +x /etc/cont-init.d/00-migration.sh"

    podman stop "$container_id"
    new_image_tag="${full_image}-migrate"
    podman commit "$container_id" "$new_image_tag"

    podman rm "$container_id"

    echo "Created new image: $new_image_tag"
    echo "$new_image_tag" >> "$output_file"
  done
done
