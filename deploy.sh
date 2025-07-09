#!/bin/bash
# Deploy Flutter web build to remote server

LOCAL_BUILD_PATH=build/web

# 1. Build the Flutter web project
echo "Building Flutter web..."
flutter build web
if [ $? -ne 0 ]; then
    echo "Flutter build failed."
    exit 1
fi
echo "Flutter build succeeded."

# 2. Compress the build output
echo "Compressing build files..."
tar -czf web_build.tar.gz -C $LOCAL_BUILD_PATH .
if [ $? -ne 0 ]; then
    echo "Compression failed."
    exit 1
fi

# 3. Copy the tarball to the remote server
echo "Uploading tarball to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH ..."
scp -P 21098 web_build.tar.gz $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH
if [ $? -ne 0 ]; then
    echo "Upload failed."
    rm -f web_build.tar.gz
    exit 1
fi

# 4. Extract the tarball on the remote server
echo "Extracting files on remote server..."
ssh -p 21098 $REMOTE_USER@$REMOTE_HOST "tar -xzf $REMOTE_PATH/web_build.tar.gz -C $REMOTE_PATH && rm $REMOTE_PATH/web_build.tar.gz"
if [ $? -ne 0 ]; then
    echo "Remote extraction failed."
    rm -f web_build.tar.gz
    exit 1
fi

# 5. Clean up local tarball
rm -f web_build.tar.gz

echo "Deployment complete."
