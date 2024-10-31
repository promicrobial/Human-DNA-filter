FROM paketobuildpacks/miniconda:0
LABEL maintainer="Linux Foundation"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/bowtie2-2.5.1-linux-x86_64

RUN apt-get update -q && apt-get install -q -y --no-install-recommends bzip2 ca-certificates git libglib2.0-0 libsm6 libxext6 libxrender1 mercurial openssh-client procps subversion wget default-jre unzip
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

COPY human-filtration.yml ./
RUN conda env create -f human-filtration.yml
