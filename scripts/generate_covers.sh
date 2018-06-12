#!/bin/bash

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -H "GData-Version: 2" \
    https://picasaweb.google.com/data/feed/api/user/109525183506894367838/albumid/6566108506954922257 |
  sed 's/&quot;/\\&/g' | xsltproc $(dirname $0)/atom_to_json.xsl - |
  jq -j '[.feed.entry[]."media:group"."media:content".url | sub("/(?<a>[^/]+)$"; "/s720/\(.a)")]' \
    > _data/covers.json
