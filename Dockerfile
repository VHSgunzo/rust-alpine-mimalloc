FROM alpine:latest

COPY .cargo /root/.cargo

COPY build.sh /tmp

RUN /tmp/build.sh

ENV LD_PRELOAD=/usr/lib/libmimalloc.so

ENV PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV HOME=/root

RUN chmod a+rwx -R /root
