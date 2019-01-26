FROM ubuntu:latest

RUN apt-get update -y && \
    apt-get install -y ssh

RUN mkdir -p /sftp/run && \
    chown sshd /sftp
RUN mkdir /run/sshd

COPY config/ /sftp/

COPY default_env.sh /etc/preseed
COPY preseed.sh /usr/bin/preseed

ENTRYPOINT ["/usr/bin/preseed"]