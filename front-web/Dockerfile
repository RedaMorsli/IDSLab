FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# Clear default nginx site content
RUN rm -rf ./*

# Nginx config with WebSocket proxy to backend
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built front-end assets
COPY . .
RUN rm -f nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
