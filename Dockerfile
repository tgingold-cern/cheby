# cheby container

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y ca-certificates python3-setuptools build-essential

COPY . /cheby

# Install cheby
RUN cd /cheby && python3 setup.py install

# clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



