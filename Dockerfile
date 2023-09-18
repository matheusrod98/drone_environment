# Uses the ROS Humble as base image
FROM ros:humble-ros-base-jammy

# Shell to be used during the build process and the container's default.
SHELL ["/bin/bash", "-c"]

# Update and upgrade system.
RUN apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install mavros and mavlink.
RUN apt update && DEBIAN_FRONTEND=noninteractive \
    && apt install -y ros-humble-rqt ros-humble-mavros ros-humble-mavros-extras ros-humble-mavros-msgs ros-humble-mavlink \
    && wget https://raw.githubusercontent.com/mavlink/mavros/ros2/mavros/scripts/install_geographiclib_datasets.sh \
    && chmod +x install_geographiclib_datasets.sh \
    && ./install_geographiclib_datasets.sh \
    && rm -rf install_geographiclib_datasets.sh

# Ardupilot
RUN apt update && DEBIAN_FRONTEND=noninteractive \
    && apt install -y default-jre socat \
    && cd \
    && git clone --recurse-submodules https://github.com/ardupilot/Micro-XRCE-DDS-Gen.git \
    && cd Micro-XRCE-DDS-Gen \
    && ./gradlew assemble \
    && export PATH=$PATH:/root/Micro-XRCE-DDS-Gen/scripts \
    && echo "export PATH=$PATH:/root/Micro-XRCE-DDS-Gen/scripts" >> /root/.bashrc \
    && source /root/.bashrc \
    && source /opt/ros/humble/setup.bash \
    && cd \
    && apt install -y python3-future python3-serial \
    && mkdir -p /root/catkin_ws/src \
    && cd /root/catkin_ws/src \
    && wget https://raw.githubusercontent.com/ArduPilot/ardupilot/master/Tools/ros2/ros2.repos \
    && vcs import --recursive < ros2.repos \
    && cd .. \
    && apt update \
    && rosdep update \
    && rosdep install --rosdistro humble --from-paths src -r -y \
    && colcon build --cmake-args -DBUILD_TESTING=ON \
    && export PATH=$PATH:/root/catkin_w/src/ardupilot/Tools/autotest \
    && echo "export PATH=$PATH:/root/catkin_ws/src/ardupilot/Tools/autotest" >> /root/.bashrc

# Gazebo Garden
RUN apt update && DEBIAN_FRONTEND=noninteractive \
    && apt install -y install lsb-release wget gnupg \
    && wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
    && apt install -y gz-garden

# ardupilot_gz
RUN apt update && DEBIAN_FRONTEND=noninteractive \
    && cd /root/catkin_ws/src \
    && wget https://raw.githubusercontent.com/ArduPilot/ardupilot_gz/main/ros2_gz.repos \
    && vcs import --recursive < ros2_gz.repos \
    && export GZ_VERSION=garden \
    && echo "export GZ_VERSION=garden" >> /root/.bashrc \
    && cd .. \
    && source /opt/ros/humble/setup.bash \
    && apt update \
    && rosdep update \
    && rosdep install --rosdistro humble --from-paths src -i -r -y \
    && colcon build --cmake-args -DBUILD_TESTING=ON

# Install robot_localization
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ros-humble-robot-localization

# Install rtabmap
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ros-humble-rtabmap-ros

# Python deps
# COPY ./requirements.txt requirements.txt
# RUN pip install -r requirements.txt

# Configure environment
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y tmux htop vim
RUN echo 'source /opt/ros/humble/setup.bash' >> $HOME/.bashrc
RUN echo "set -g mouse on" >> /root/.tmux.conf
RUN echo "set-option -g history-limit 20000" >> /root/.tmux.conf
RUN mkdir -p /root/catkin_ws/src
WORKDIR /root/catkin_ws
