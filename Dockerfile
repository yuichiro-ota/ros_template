FROM ubuntu:22.04

# ============================================================
# 基本設定
# ============================================================
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ロケール・基本ツール
RUN apt-get update && apt-get install -y \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    build-essential \
    git \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# ROS 2 Humble
# ============================================================
# リポジトリ登録（apt-key 非推奨のため signed-by 方式を使用）
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/ros2.list

# コアパッケージ（ros-humble-desktop に rclpy 等を含む）
RUN apt-get update && apt-get install -y \
    ros-humble-desktop \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

# rosdep 初期化
RUN rosdep init || true && rosdep update

# ============================================================
# [オプション] 追加 ROS パッケージ
# プロジェクトに応じてコメントを解除してください
# ============================================================
# DDS ミドルウェア（デフォルト fastDDS の代替）・ロボット記述言語
RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-xacro \
    && rm -rf /var/lib/apt/lists/*

# カメラ
# RUN apt-get update && apt-get install -y ros-humble-v4l2-camera && rm -rf /var/lib/apt/lists/*

# MQTT 通信
# RUN apt-get update && apt-get install -y ros-humble-mqtt-client && rm -rf /var/lib/apt/lists/*

# SLAM
# RUN apt-get update && apt-get install -y ros-humble-slam-toolbox && rm -rf /var/lib/apt/lists/*

# ナビゲーション
# RUN apt-get update && apt-get install -y ros-humble-navigation2 ros-humble-nav2-bringup && rm -rf /var/lib/apt/lists/*

# ============================================================
# Python 環境・システムツール
# ============================================================
RUN apt-get update && apt-get install -y \
    sudo \
    python3-pip \
    python3-setuptools \
    python3-venv \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Python パッケージのインストール
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# ============================================================
# ユーザー設定
# ============================================================
ARG USER_NAME
ARG USER_ID
ARG USER_GID

RUN groupadd -f -g ${USER_GID} ${USER_NAME} \
    && useradd -m -u ${USER_ID} -g ${USER_GID} -s /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/${USER_NAME}/.config/pulse \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# ============================================================
# 作業ディレクトリ・ファイルコピー
# ============================================================
WORKDIR /app
COPY . /app
RUN chown -R ${USER_NAME}:${USER_NAME} /app \
    && chmod +x /app/entrypoint.sh

# ============================================================
# ユーザー切り替え・環境変数
# ============================================================
USER ${USER_ID}:${USER_GID}

RUN echo "source /opt/ros/humble/setup.bash" >> /home/${USER_NAME}/.bashrc \
    && echo "[ -f /app/ros2_ws/install/setup.bash ] && source /app/ros2_ws/install/setup.bash" >> /home/${USER_NAME}/.bashrc

ENV ROS_PYTHON_VERSION=3
ENV PATH=/opt/ros/humble/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/ros/humble/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH=/opt/ros/humble/lib/python3.10/site-packages:$PYTHONPATH
ENV COLCON_PREFIX_PATH=/opt/ros/humble:$COLCON_PREFIX_PATH

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
CMD ["bash", "-l"]
