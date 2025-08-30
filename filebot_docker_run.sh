#!/bin/bash

# Find all volumes matching data*
VOLUMES=($(docker volume ls --format '{{.Name}}' | grep -E '^data[0-9]*$'))

# Find an unused volume
VOLUME_NAME=""
for v in "${VOLUMES[@]}"; do
  if ! docker ps --format '{{.Mounts}}' | grep -q "${v}:/data"; then
    VOLUME_NAME="$v"
    break
  fi
done

# If all are in use or none exist, pick next available name
if [[ -z "$VOLUME_NAME" ]]; then
  # Find the highest existing dataN number
  max=-1
  for v in "${VOLUMES[@]}"; do
    n=${v#data}
    [[ -z "$n" ]] && n=0
    (( n > max )) && max=$n
  done
  VOLUME_NAME="data$((max+1))"
  docker volume create "$VOLUME_NAME" >/dev/null
fi

docker run --rm \
  -v ${VOLUME_NAME}:/data \
  -v /zpool3/zpool3/media:/zpool3/zpool3/media \
  -v /zpool3/zpool3/media_temp/filebot_watch:/watch \
  -v /zpool3/zpool3/media_temp/filebot_temp:/temp \
  rednoah/filebot -script fn:amc /watch --output /zpool3/zpool3/media --action keeplink -non-strict --log-file amc.log \
  --def excludeList=/temp/amc-exclude-list.txt \
        movieFormat="/zpool3/zpool3/media/movies/{n.space('.')}.{y}/{n.space('.')}.{y}.{source}.{vf}.{vc}.{af}.{ac}" \
        seriesFormat="/zpool3/zpool3/media/tv/{n}/{'season_'+s}/{n}_{s00e00}_{t}"