# cheby container

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y ca-certificates python3-pip build-essential git

COPY . /cheby

# Install cheby
RUN cd /cheby && python3 -m pip install .

# clean up
RUN apt-get -y autoremove git
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



