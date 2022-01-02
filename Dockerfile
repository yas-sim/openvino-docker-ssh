FROM openvino/ubuntu20_dev:2021.4.2
#FROM ubuntu:20.04
USER root

ARG TZ=UTC
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Enable SSH
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:rootroot' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Install some tools
RUN apt-get update && apt-get install -y sudo 
RUN apt-get update && apt-get install -y vim build-essential binutils cmake git
RUN apt-get update && apt-get install -y iproute2 zip x11-apps

# Create a 'sudo-able' user
ARG USERNAME="ovuser"
ARG UID=1001
ARG GID=1001
RUN groupadd --gid ${GID} ${USERNAME}
RUN useradd --create-home --shell /bin/bash --uid ${UID} --gid ${GID} -G sudo,video,users ${USERNAME}
RUN echo "${USERNAME}:${USERNAME}" | chpasswd
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup user environment
USER ${USERNAME}
WORKDIR /home/${USERNAME}
RUN echo "source /opt/intel/openvino/bin/setupvars.sh" >> /home/${USERNAME}/.bashrc
RUN echo "export QT_X11_NO_MITSHM=1" >> .bashrc
# Create aliases to the OpenVINO tools for user convenience
RUN echo "alias omz_downloader='${INTEL_OPENVINO_DIR}/deployment_tools/open_model_zoo/tools/downloader/downloader.py'" >> .bashrc
RUN echo "alias omz_converter='${INTEL_OPENVINO_DIR}/deployment_tools/open_model_zoo/tools/downloader/converter.py'" >> .bashrc
RUN echo "alias omz_quantizer='${INTEL_OPENVINO_DIR}/deployment_tools/open_model_zoo/tools/downloader/quantizer.py'" >> .bashrc
RUN echo "alias benchmark_app='${INTEL_OPENVINO_DIR}/deployment_tools/tools/benchmark_tool/benchmark_app.py'" >> .bashrc
RUN mkdir work

USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

# How to build a Docker image
#  docker build -t openvino_dev_ssh .

# How to start a Docker container
#  docker run -d --rm -p 22:22 --name ov -it openvino_dev_ssh
#  (Win: Start VcXsrv, a Xserver with 'Disable access control' option checked)
#  ssh ovuser@localhost
#  export DISPLAY=<host_IP_addr>:0.0
# Now you can run the X11 apps
