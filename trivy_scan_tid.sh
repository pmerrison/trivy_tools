#!/bin/bash
#These arrays let us contruct the various combinations of images and tags that we care about scanning
tag_stem=( "-tetrate-v0-debug" "-tetrate-v0-distroless" "-tetratefips-v0-debug" "-tetratefips-v0-distroless" )
version_list=( "1.15.1" "1.15.3" "1.14.5" "1.14.4" )
image_list=("proxyv2" "operator" "pilot")
declare -a final_tag_list

#First go and build a list of complete tag names from the versions list and the tag stem lists
for version in "${version_list[@]}"
do
    for tag in "${tag_stem[@]}"
    do
        tag_name="$version$tag"
        final_tag_list+=($tag_name)
        echo $tag_name
    done
done

mkdir -p scan_results

#Now go and scan the combination of each image in image_list and each tag that we constructed
for tag in "${final_tag_list[@]}"
do
    for image in "${image_list[@]}"
    do
        root_url="containers.istio.tetratelabs.com/"
        url="$root_url$image:$tag"
        echo $url
        set -e
        trivy image -f json -o scan_results/$image$tag.json $url
    done
done