FROM gapsystem/gap-docker-base

MAINTAINER The GAP Group <support@gap-system.org>

# Prerequirements
RUN    sudo apt-get update -qq \
    && sudo apt-get -qq install -y \
                                   # for ANUPQ package to build in 32-bit mode
                                   gcc-multilib \
                                   # for ZeroMQ package
                                   libzmq3-dev \
                                   # for Jupyter
                                   python3-pip

RUN sudo pip3 install notebook jupyterlab_launcher jupyterlab traitlets ipython vdom

RUN    cd /home/gap/inst/ \
    && rm -rf gap-4.9.1 \
    && wget -q https://github.com/gap-system/gap/archive/master.zip \
    && unzip -q master.zip \
    && rm master.zip \
    && cd gap-master \
    && ./autogen.sh \
    && ./configure \
    && make \
    && mkdir pkg \
    && cd pkg \
    && wget -q https://www.gap-system.org/pub/gap/gap4pkgs/packages-master.tar.gz \
    && tar xzf packages-master.tar.gz \
    && rm packages-master.tar.gz \
    && ../bin/BuildPackages.sh \
    && cd JupyterKernel-* \
    && python3 setup.py install --user

RUN jupyter serverextension enable --py jupyterlab --user

USER root

RUN     apt-get -qq install -y curl \
    &&  curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - \
    &&  apt-get install -yq nodejs && npm install -g npm

USER gap

RUN     cd /home/gap/inst/gap-master/pkg \
    &&  git clone https://github.com/mcmartins/francy.git \
    &&  cd francy \
    &&  cd js \
    &&  sudo npm install && npm run build \
    &&  cd ../gap \
    &&  sudo npm install && npm run build \
    &&  cd ../extensions/jupyter \
    &&  sudo npm install && npm run build \
    &&  sudo pip3 install -e . \
    &&  cd ../.. \
    &&  mv /home/gap/inst/gap-master/pkg/francy/extensions/jupyter/jupyter_francy/nbextension /home/gap/inst/gap-master/pkg/francy/extensions/jupyter/jupyter_francy/jupyter_francy \
    &&  jupyter nbextension install /home/gap/inst/gap-master/pkg/francy/extensions/jupyter/jupyter_francy/jupyter_francy --user \
    &&  jupyter nbextension enable jupyter_francy/extension --user

ENV PATH /home/gap/inst/gap-master/pkg/JupyterKernel-*/bin:${PATH}
ENV JUPYTER_GAP_EXECUTABLE /home/gap/inst/gap-master/bin/gap.sh

# Set up new user and home directory in environment.
# Note that WORKDIR will not expand environment variables in docker versions < 1.3.1.
# See docker issue 2637: https://github.com/docker/docker/issues/2637
USER gap
ENV HOME /home/gap
ENV GAP_HOME /home/gap/inst/gap-master
ENV PATH ${GAP_HOME}/bin:${PATH}

# Start at $HOME.
WORKDIR /home/gap

# Start from a BASH shell.
CMD ["bash"]
