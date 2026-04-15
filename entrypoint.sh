#!/bin/bash
set -e

# ROS 2 環境の読み込み
source /opt/ros/humble/setup.bash

# ワークスペースがビルド済みであれば読み込む
if [ -f "/app/ros2_ws/install/setup.bash" ]; then
    source /app/ros2_ws/install/setup.bash
fi

exec "$@"
