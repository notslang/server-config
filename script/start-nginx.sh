docker run -d --name nginx \
       -v /data/nginx/log:/var/log/nginx/ \
       -v /data/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
       -v /data/nginx/config:/etc/nginx/conf.d:ro \
       -v /data/nginx/content:/usr/share/nginx/html:ro \
       -v /data/certbot:/etc/letsencrypt:ro \
       -p 80:80 \
       -p 443:443 \
       -p 6984:6984 \
       -p 5984:5984 \
       --restart=always \
       nginx:1.19.8-alpine
