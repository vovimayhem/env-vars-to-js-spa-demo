#! /bin/sh

# This is a simple script that uses envsubst to replace references to
# environment variables in our index.html file with the actual values:

# NOTE this is intended to work only inside a container started from our
# releasable image!
INDEX_HTML_FILE_PATH="/usr/share/nginx/html/index.html"
cat "${INDEX_HTML_FILE_PATH}" | envsubst > "${INDEX_HTML_FILE_PATH}"