docker run --rm -p 222:222 -v "$(pwd)/users:/sftp/users:ro" -v "$(pwd)/data:/sftp/root/data:ro" -v "/home/marco/tmp/homes:/sftp/root/homes" -v "$(pwd)/seed-file:/tmp/seed-file" sftp --preseed-debug --seed=/tmp/seed-file
