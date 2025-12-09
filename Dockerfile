FROM nginx:alpine

# Copy docs to nginx
COPY Docs /usr/share/nginx/html

# Custom nginx config
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Swift-DocC - SPA with special handling for data files
    location /generated/swift-docc/ {
        # Serve actual files (js, css, images, json data, etc.)
        try_files $uri @swiftdocc_fallback;
    }
    
    # Fallback for Swift-DocC SPA routes
    location @swiftdocc_fallback {
        rewrite ^/generated/swift-docc/(.*)$ /generated/swift-docc/index.html break;
    }

    # Doxygen directory - serve directly without fallback
    location /generated/doxygen/ {
        try_files $uri $uri/ =404;
    }

    # Default - SPA fallback for unified index only
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]