#!/bin/bash

set -e
set -x
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

function usage() {
    echo "$0 <platform> <embedding_version>"
}


if [[ "$#" -ne 2 ]]; then
    echo "Invalid number of argument! $#"
    usage
    exit 1
fi

platform=$1
embedding_version=$2


embedding_root="/user/deepr/prod/popularity-embeddings"
indices_root="/user/deepr/prod/knn-indices"

embedding_path=$embedding_root/$platform/$embedding_version
indices_path=$indices_root/$platform/$embedding_version
python $SCRIPTPATH/hdfs_downloader.py --usehdfs --host prod-am6 -O "./embeddings" $embedding_path
python $SCRIPTPATH/hdfs_downloader.py --usehdfs --host prod-am6 -O "./indices" $indices_path