docker run -d --name ipfs \
       -e IPFS_PROFILE="server" \
       -v /data/ipfs/export:/export \
       -v /data/ipfs/ipfs:/data/ipfs \
       -p 4001:4001 \
       -p 8080:8080 \
       --restart=always \
       ipfs/go-ipfs:latest
