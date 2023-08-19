FROM nginx

RUN rm /etc/nginx/conf.d/default.conf

COPY artifacts /var/www/sustainity
COPY config/sustainity.conf /etc/nginx/conf.d/sustainity.conf

EXPOSE 80
