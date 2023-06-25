#!/bin/bash

# User inputs
release_type=$1
release_candidate=$2

version_file="pubspec.yaml"
build_number=0

# Extract the version from file
# It can match pattern "version: [0-9].[0-9].[0-9]+[0-9]-rc[0-9]" from any file
prev_version=$(grep -m 1 "version:" "$version_file" | sed -E 's/version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+[0-9]+)?(-rc[0-9]+)?(.*)?/\1\2\3/')
# On MacOS replace 'version: ' prefix with ''
prev_version="${prev_version/"version: "/}"


IFS='+' read -ra version_parts <<< "$prev_version"
version=${version_parts[0]}
suffix=${version_parts[1]}

IFS='-' read -ra suffix_parts <<< "$suffix"
build_number=${suffix_parts[0]#[0-9]+}
rc="${suffix_parts[1]/"rc"/""}"

IFS='.' read -ra version_numbers <<< "$version"
major=${version_numbers[0]}
minor=${version_numbers[1]}
patch=${version_numbers[2]}

case "$release_type" in
  "major")
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  "minor")
    minor=$((minor + 1))
    patch=0
    ;;
  "patch")
    patch=$((patch + 1))
    ;;
  *)
    echo "Invalid release type: '$1'. Valid type is major, minor or patch"
    exit
    ;;
esac

if [ "$release_candidate" = true ]; then
  if [ -n "$rc" ]; then
    rc="$((rc + 1))"
  else
    rc="1"
  fi
else
  rc=""
fi

build_number=$((build_number + 1))
new_version="$major.$minor.$patch+$build_number"

# Append rc if available
if [ -n "$rc" ]; then
  new_version="$new_version-rc$rc"
fi

# Check the operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux system
  sed_command="sed -i"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS system
  sed_command="sed -i.bak"
else
  echo "Unsupported operating system: $OSTYPE"
  exit 1
fi

# Replace the version in the file using the appropriate sed command
$sed_command "s/^version: $prev_version$/version: $new_version/" "$version_file"

echo "------------------------------"
echo "Version File: $version_file"
echo "-------------+----------------"
echo " Old Version | $prev_version"
echo " New Version | $new_version"
echo "-------------+----------------"
echo "Build Number | $build_number"
echo "   RC Number | $rc"
echo "-------------+----------------"
