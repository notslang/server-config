for site in 301r.dev bellasurfaces.com genomena.com jkniselylandscaping.com slang.cx
do
  docker run -it --rm --name certbot \
             -v "/data/nginx/content/$site:/webroot" \
             -v "/data/certbot:/etc/letsencrypt" \
             certbot/certbot certonly --webroot -w /webroot -d "$site"
done

docker restart nginx
