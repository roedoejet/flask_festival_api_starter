FROM ubuntu:xenial

# copy src files from http://tts.speech.cs.cmu.edu/11-823/hints/clock.html
RUN mkdir /app /app/audio
COPY ./src /src
COPY ./api.py /app/
COPY ./requirements.txt /app/
COPY model /app/model

# install necessary packages
RUN apt-get update -y
RUN apt-get install -y libncurses5-dev sox patch build-essential
RUN apt-get install -y festlex-poslex festlex-cmu
RUN apt-get install -y automake bc curl g++ git libc-dev libreadline-dev libtool make ncurses-dev nvi pkg-config python3 python-dev python-setuptools unzip wavpack wget zip zlib1g-dev python3-pip
RUN pip3 install -r /app/requirements.txt

# unpack src
RUN mkdir /build
RUN cd build && tar zxvf /src/SPTK-3.6.tar.gz
RUN cd build && tar zxvf /src/speech_tools-2.5.0-current.tar.gz
RUN cd build && tar zxvf /src/festival-2.5.0-current.tar.gz
RUN cd build && tar zxvf /src/festlex_CMU.tar.gz
RUN cd build && tar zxvf /src/festlex_POSLEX.tar.gz
RUN cd build && tar zxvf /src/festvox_kallpc16k.tar.gz
RUN cd build && tar zxvf /src/festvox_rablpc16k.tar.gz
RUN cd build && tar zxvf /src/festvox-2.7.3-current.tar.gz

# set env variables
ENV ESTDIR=/build/speech_tools
# ENV FLITEDIR=/build/flite
ENV FESTVOXDIR=/build/festvox
ENV SPTKDIR=/build/SPTK
ENV FESTIVALDIR = /build/festival
ENV VOICEPATH = /app/model/eng_clock/festvox/nrc_time_ap_ldom.scm
ENV MODELPATH = /app/model/eng_clock
ENV VOICENAME = nrc_time_ap_ldom
ENV AUDIODIR = /app/audio

# patch
RUN cd build && mkdir SPTK
RUN cd build && patch -p0 <festvox/src/clustergen/SPTK-3.6.patch 

# compile
RUN cd /build/SPTK-3.6 && ./configure --prefix=$SPTKDIR && make && make install && make distclean
RUN cd /build/speech_tools && ./configure && make
RUN cd /build/festival && ./configure && make
RUN cd /build/festvox && ./configure && make

CMD gunicorn api --bind 0.0.0.0:$PORT