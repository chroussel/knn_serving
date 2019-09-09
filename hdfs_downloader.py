#!/bin/env python3

import argparse
import pyarrow as pa
import requests
import os
import queue
import time
import logging
import signal
import sys


class Downloader():
    def list_file_to_download(self, uri):
        pass

    def download(self, root_source, root_dest):
        pass


class HDfsDownloader(Downloader):
    def __init__(self, host=""):
        self.fs = pa.hdfs.connect(host)
        self.download_queue = queue.Queue()

    def download(self, root_source, root_dest):
        while not self.download_queue.empty():
            source = self.download_queue.get()
            dest = HDfsDownloader.build_dest(source, root_source, root_dest)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, 'wb') as f:
                logging.info(f"Start downloading {source}")
                t0 = time.clock()
                self.fs.download(source, dest)
                end = time.clock() - t0
                logging.info(f"End downloading {source}, took {end} seconds")

    def build_dest(uri, root, dest):
        sp = uri.split(root)
        if len(sp) == 2:
            return os.path.join(dest, sp[1])
        else:
            return os.path.join(dest, uri)

    def list_file_to_download(self, uri):
        if not self.fs.exists(uri):
            logging.error(f"{uri} does not exists")
            return
        file_q = queue.Queue()
        logging.info(f"Listing {uri}")
        for r in self.fs.ls(uri, True):
            file_q.put(r)
        while not file_q.empty():
            current = file_q.get()
            file_name = current["name"]
            is_dir = current['kind'] == 'directory'
            if is_dir:
                logging.info(f"Listing {uri}")
                for item in self.fs.ls(file_name, True):
                    file_q.put(item)
            else:
                logging.info(f"Adding {file_name}")
                self.download_queue.put(file_name)


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    parser = argparse.ArgumentParser("Download data from hdfs")
    parser.add_argument("--usehdfs", action="store_true", help="Use hdfs to download data, default: use web")
    parser.add_argument("--host", help="Hdfs host to use")
    parser.add_argument('-O', "--dest", help="Folder to download to", default=".")
    parser.add_argument("uris", metavar='URI', help="List of uris to download data from", nargs='+')
    args = parser.parse_args()

    if (args.usehdfs):
        downloader = HDfsDownloader(args.host)
        for u in args.uris:
            if not u.endswith("/"):
                u = u + "/"
            sp = u.split("/")
            dirname = sp[-2]
            dest = os.path.join(args.dest, dirname)
            logging.info(f"Downloading {u} to {dest}")

            downloader.list_file_to_download(u)
            downloader.download(u, dest)


if __name__ == "__main__":
    main()
