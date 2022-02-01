FROM ubuntu:20.04
WORKDIR /opt

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/GMT
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates locales g++ gcc libc6-dev make pkg-config wget git libopus-dev libavcodec-dev libgstreamer1.0-dev ffmpeg apt-utils ssh-client && \
    apt install -y gcc cmake gstreamer1.0-libav libgstreamer-plugins-base1.0-dev gstreamer1.0-tools libnss3-dev libatk1.0-dev libatk-bridge2.0-dev libxcomposite-dev libxdamage-dev xvfb gstreamer1.0-plugins-ugly gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/supersen/gstcefsrc.git && mkdir gstcefsrc/build && cd gstcefsrc/build && cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release .. && make
ENV GST_PLUGIN_PATH /opt/gstcefsrc/build/Release:/usr/lib/x86_64-linux-gnu/gstreamer-1.0

ENV SCR_WIDTH 1920
ENV SCR_HEIGHT 1080
ENV SCR_FPS 30
ENV YOUTUBE_URL rtmp://a.rtmp.youtube.com/live2

ENV URL webpage2stream
ENV KEY youtube_key

ENTRYPOINT xvfb-run --server-args="-screen 0 ${SCR_WIDTH}x${SCR_HEIGHT}x${SCR_FPS}" gst-launch-1.0 cefsrc url="$URL" ! \
    video/x-raw, width=${SCR_WIDTH}, height=${SCR_HEIGHT}, framerate=${SCR_FPS}/1 ! \
    cefdemux name=d \
    d.video ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=3000000000 ! videoconvert ! x264enc key-int-max=60 bitrate=3000 ! h264parse ! \
    flvmux name=mux \
    d.audio ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=3000000000 ! audioconvert ! avenc_aac ! aacparse ! mux. \
    mux. ! rtmpsink location="$YOUTUBE_URL/$KEY"