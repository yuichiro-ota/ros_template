# ros_template

ROS 2 Humble 開発用の Docker テンプレートです。基本的には Linux 環境での利用を想定しています。`docker-compose.yml` は Linux 上で `host network` と X11 GUI を使う前提の構成です。非 Linux 向けには `docker-compose.nonlinux.yml` を用意しています。

## 前提

- 基本対象は Linux
- Docker Engine または Docker Desktop
- Docker Compose v2
- Linux 以外では `host network` や X11 マウントをそのまま使えない場合があります
- DDS 実装は環境差の影響を受けるため、このテンプレートでは `rmw_cyclonedds_cpp` を既定にしています

## セットアップ

1. `.env` を作成します。

```bash
cp .env.example .env
```

2. Linux ではホストの UID/GID に合わせて `.env` を修正します。

```bash
id
```

`USER_NAME` はデフォルトで `ros_developer` にしてあります。Linux で bind mount 時の所有権を揃えたい場合は、`USER_ID` と `USER_GID` をホストに合わせて変更してください。必要なら `USER_NAME` も変更して構いません。

`USER_ID=1000` と `USER_GID=1000` は Ubuntu 系でよくある初期値ですが、環境によって異なります。必ず `id` の結果を確認してください。

3. 利用する環境に応じてコンテナを起動します。

`requirements.txt` を変更した場合はイメージの再 build が必要です。依存関係を追加・変更した後は、初回起動と同じく `up --build` を使ってください。
pip パッケージを追加したい場合は、リポジトリ直下の `requirements.txt` に追記してください。その後、コンテナを再 build するとインストールされます。

## Linux で使う場合

これがメインの利用方法です。

初回 build と起動:

```bash
xhost +local:
docker compose up -d --build
```

2回目以降の起動:

```bash
xhost +local:
docker compose up -d
```

起動中コンテナに入る:

```bash
docker compose exec ros_humble bash
```

コンテナを停止:

```bash
docker compose down
```

終了後に X11 許可を戻す場合:

```bash
xhost -local:
```

## Linux 以外で使う場合

Docker Desktop などの非 Linux 環境では、`docker-compose.nonlinux.yml` を使ってください。このファイルでは `host network` と X11 mount を外しています。

初回 build と起動:

```bash
docker compose -f docker-compose.nonlinux.yml up -d --build
```

2回目以降の起動:

```bash
docker compose -f docker-compose.nonlinux.yml up -d
```

起動中コンテナに入る:

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
```

コンテナを停止:

```bash
docker compose -f docker-compose.nonlinux.yml down
```

## ワークスペース構成

`/app` がリポジトリルートとしてマウントされます。ROS 2 ワークスペースは `ros2_ws` を想定しています。

```text
.
├── docker-compose.yml
├── docker-compose.nonlinux.yml
├── Dockerfile
├── entrypoint.sh
└── ros2_ws
    └── src
```

ワークスペースをビルドする例:

```bash
docker compose run --rm ros_humble bash -lc "cd /app/ros2_ws && colcon build"
```

## 起動後の確認

コンテナに入ります。

```bash
docker compose exec ros_humble bash
```

非 Linux 環境では次を使ってください。

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
```

### 環境変数の確認

`.env` で設定した値と、コンテナ内の値が一致していることを確認します。

```bash
echo $ROS_DOMAIN_ID
echo $RMW_IMPLEMENTATION
```

`.env` で `ROS_DOMAIN_ID=0`、`RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` を設定している場合は、上の結果も同じ値になっていれば問題ありません。

必要であれば ROS 2 環境が読まれていることも確認できます。

```bash
which ros2
printenv | grep ROS
```

### 必要なパッケージが入っているかの確認

ROS Debian パッケージの確認例:

```bash
dpkg -l | grep ros-humble-rmw-cyclonedds-cpp
```

pip パッケージの確認例:

```bash
pip list | grep python-dotenv
```

他の追加したパッケージを確認したい場合は、`grep` の後ろを対象のパッケージ名に変えてください。

### pub/sub の動作確認

環境によっては DDS 実装の差で pub/sub の成否が変わることがあります。まずは `.env` の `RMW_IMPLEMENTATION` が `rmw_cyclonedds_cpp` になっていることを確認してください。

1つ目のターミナルで listener を起動します。

```bash
docker compose exec ros_humble bash
ros2 run demo_nodes_cpp listener
```

非 Linux 環境では次を使ってください。

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
ros2 run demo_nodes_cpp listener
```

2つ目のターミナルで talker を起動します。

```bash
docker compose exec ros_humble bash
ros2 run demo_nodes_cpp talker
```

非 Linux 環境では次を使ってください。

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
ros2 run demo_nodes_cpp talker
```

listener 側に `I heard: [Hello World: ...]` が表示されれば、基本的な pub/sub は動作しています。

`selected interface "lo" is not multicast-capable: disabling multicast` と表示されても、`I heard:` が出ていればこの確認としては問題ありません。

listener 側の出力例:

```text
[INFO] [...] [listener]: I heard: [Hello World: 1]
[INFO] [...] [listener]: I heard: [Hello World: 2]
```

talker 側の出力例:

```text
[INFO] [...] [talker]: Publishing: 'Hello World: 1'
[INFO] [...] [talker]: Publishing: 'Hello World: 2'
```

### turtlesim の動作確認

X11 転送が有効な状態で turtlesim を起動できます。

1つ目のターミナルで turtlesim のウィンドウを起動します。

```bash
docker compose exec ros_humble bash
ros2 run turtlesim turtlesim_node
```

非 Linux 環境では次を使ってください。

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
ros2 run turtlesim turtlesim_node
```

2つ目のターミナルでキーボード操作ノードを起動します。

```bash
docker compose exec ros_humble bash
ros2 run turtlesim turtle_teleop_key
```

非 Linux 環境では次を使ってください。

```bash
docker compose -f docker-compose.nonlinux.yml exec ros_humble bash
ros2 run turtlesim turtle_teleop_key
```

`turtle_teleop_key` を起動したターミナルにフォーカスを当てた状態で矢印キーを押すと、ウィンドウ内の亀が動きます。

## 補足

- `entrypoint.sh` は `bash /app/entrypoint.sh` として実行するため、ホスト側の実行権限に依存しません。
- `.dockerignore` により `.env` や `.git` はイメージへコピーされません。
- `requirements.txt` には一般的に使いやすい最小限の Python パッケージだけを入れています。追加のライブラリが必要な場合は `requirements.txt` に追記し、`docker compose up -d --build` で再 build してください。
- USB シリアル、カメラ、GPIO などのデバイスファイルが必要な場合は、`docker-compose.yml` に `devices:` や `group_add:` を追加してコンテナへ渡してください。

例: USB シリアルとカメラを使う場合

```yaml
services:
  ros_humble:
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
      - /dev/video0:/dev/video0
    group_add:
      - dialout
      - video
```

この例では、ホスト側の `/dev/ttyUSB0` と `/dev/video0` をコンテナ内へそのまま渡しています。必要なデバイス名やグループ名は環境に合わせて変更してください。
