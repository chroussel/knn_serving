import argparse
import os
import io
import sys
import pyarrow.parquet as pq
import time
import logging
import struct


def floatListToBytes(floatListValue):
    b = io.BytesIO()
    for f in floatListValue:
        b.write(floatToBytes(f))
    return b.getvalue()


def floatToBytes(floatValue):
    return struct.pack("f", floatValue)


def intToBytes(intValue):
    return intValue.to_bytes(4, byteorder='little', signed=True)


def longToBytes(longValue):
    return longValue.to_bytes(8, byteorder='little', signed=True)


class NonRecoEmbeddingTranscoder():
    def transcode(self, parquet_file):
        pqfile = pq.ParquetFile(parquet_file)
        logging.info(f"Processing : {parquet_file}")
        t0 = time.clock()
        with open(parquet_file+".bin", "wb") as fw:
            for i in range(0, pqfile.num_row_groups):
                rowgroup = pqfile.read_row_group(i)
                for b in self.parseFormat(rowgroup):
                    fw.write(b)
        end = time.clock() - t0
        logging.info(f"Processing done for {parquet_file} in {end}")

    def parseFormat(self, rowgroup):
        productPartnerKey = rowgroup.column(0)
        embedding = rowgroup.column(1)
        for j in range(0, rowgroup.num_rows):
            currentProductPartnerKey = productPartnerKey[j]
            currentEmbedding = embedding[j].as_py()
            b = io.BytesIO()
            productId = currentProductPartnerKey["productId"].as_py()
            partnerId = currentProductPartnerKey["partnerId"].as_py()
            b.write(longToBytes(productId))
            b.write(intToBytes(partnerId))
            b.write(intToBytes(len(currentEmbedding)))
            b.write(floatListToBytes(currentEmbedding))
            yield b.getvalue()


class IndexTranscoder():
    def transcode(self, parquet_file):
        pqfile = pq.ParquetFile(parquet_file)
        logging.info(f"Processing : {parquet_file}")
        t0 = time.clock()
        for i in range(0, pqfile.num_row_groups):
            rowgroup = pqfile.read_row_group(i)
            partnerChunks = rowgroup.column(0)
            indices = rowgroup.column(1)
            for j in range(0, rowgroup.num_rows):
                currentChunk = partnerChunks[j]
                currentIndex = indices[j].as_buffer()
                partnerId = currentChunk["partnerId"].as_py()
                chunkId = currentChunk["chunkId"].as_py()
                with open(os.path.join(os.path.dirname(parquet_file), f"index-{partnerId}-{chunkId}.bin"), "wb") as index_file:
                    index_file.write(currentIndex)
        end = time.clock() - t0
        logging.info(f"Processing done for {parquet_file} in {end}")


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", help="parquet folder path", required=True)
    parser.add_argument("--is_index", help="parquet folder path", action="store_true", default=False)
    parser.add_argument("--output", help="output folder path")
    args = parser.parse_args()

    if args.is_index:
        transcoder = IndexTranscoder()
    else:
        transcoder = NonRecoEmbeddingTranscoder()

    for (current_folder, folders, files) in os.walk(args.path):
        for f in files:
            if (f.endswith(".parquet")):
                if args.is_index:
                    transcoder.transcode(os.path.join(current_folder, f))
                else:
                    if current_folder.endswith("non-recommendable"):
                        transcoder.transcode(os.path.join(current_folder, f))


if __name__ == "__main__":
    main()
