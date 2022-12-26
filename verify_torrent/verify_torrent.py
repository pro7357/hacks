#!/usr/bin/python3

# pip install fast-bencode
import io, sys, os, hashlib, bencode

def pieces_generator(info):
    """Yield pieces from download file(s)."""
    piece_length = info['piece length']
    if 'files' in info: # yield pieces from a multi-file torrent
        piece = b""
        for file_info in info['files']:
            path = os.sep.join([info['name']] + file_info['path'])
            print(path)
            sfile = open(path, "rb")
            while True:
                piece = b"".join([piece, sfile.read(piece_length-len(piece)) ])
                if len(piece) != piece_length:
                    sfile.close()
                    break
                yield piece
                piece = b""
        if piece != b"":
            yield piece
    else: # yield pieces from a single file torrent
        path = info['name']
        print(path)
        sfile = open(path, "rb")
        while True:
            piece = sfile.read(piece_length)
            if not piece:
                sfile.close()
                return
            yield piece

def corruption_failure():
    """Display error message and exit"""
    print("download incomplete or corrupt")
    exit(1)

def main():
    # Open torrent file
    torrent_file = open(sys.argv[1], "rb")
    metainfo = bencode.bdecode(torrent_file.read())
    info = metainfo['info']
    pieces = io.BytesIO(info['pieces'])
    # Iterate through pieces
    for piece in pieces_generator(info):
        # Compare piece hash with expected hash
        piece_hash = hashlib.sha1(piece).digest()
        if (piece_hash != pieces.read(20)):
            #corruption_failure()
            break
    # ensure we've read all pieces
    if pieces.read():
        print("Error: Incomplete verified")
        exit(3)
    else:
        print("All successfully verified")
        exit(0)

if __name__ == "__main__":
    main()
