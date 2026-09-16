# ROS2_Demo

ROS2 通用功能包模板，兼容 **foxy / humble**。

包含一个自定义消息接口包 `your_msg` 和一个 C++ 节点包 `your_project_name`，并附带快速重命名脚本，可直接作为新项目的起手模板。

## 工作空间结构

```text
ROS2_Demo/
├── your_msg/                          # 自定义消息接口包
│   ├── CMakeLists.txt
│   ├── package.xml
│   └── msg/
│       └── Yourmsgname.msg            # 自定义消息定义
├── your_project_name/                 # C++ 节点包（依赖 your_msg）
│   ├── CMakeLists.txt
│   ├── package.xml
│   ├── include/your_project_name/
│   │   └── your_hpp_name.hpp          # 节点类声明
│   └── src/
│       └── your_cpp_name.cpp          # 节点实现与 main
└── scripts/
    └── rename_project.sh              # 快速重命名模板包脚本
```

## 包说明

### your_msg（消息接口包）

只负责接口定义与生成，与节点逻辑解耦。多个节点包可以共同依赖同一个消息包，避免每个包内重复生成接口。

- 消息定义：`your_msg/msg/Yourmsgname.msg`（当前为 `uint32 id` / `string name` / `float32 value`）
- 新增消息：在 `msg/` 下新建 `xxx.msg`，并在 `your_msg/CMakeLists.txt` 的 `rosidl_generate_interfaces` 中追加一行 `"msg/xxx.msg"`
- 消息中若使用其他包的字段类型（如 `geometry_msgs/Pose`），需在 `rosidl_generate_interfaces` 的 `DEPENDENCIES` 以及 `package.xml` 中补充对应依赖

### your_project_name（C++ 节点包）

基于 `rclcpp` 的节点示例：

- 发布 `std_msgs/msg/String` 到 `demo_topic`
- 发布自定义消息 `your_msg/msg/Yourmsgname` 到 `my_topic`
- 串口示例：基于官方 `serial_driver` 打开串口并挂异步接收回调（设备不存在时仅告警，不影响其余功能）
- `main` 中演示两种运行方式：`rclcpp::spin(node)` 与 `run()` 内使用 `rclcpp::Rate` 的定频循环（默认启用后者）

## 依赖

`your_project_name/CMakeLists.txt` 中已引入常用库，未用到的可从 `CMakeLists.txt` 与 `package.xml` 中成对删除：

`rclcpp`、`rclpy`、`serial_driver`、`io_context`、`asio`、`std_msgs`、`sensor_msgs`、`geometry_msgs`、`tf2`、`tf2_ros`、`tf2_geometry_msgs`、`nav_msgs`、`nav2_msgs`、`nav2_util`、`pcl_ros`、`pcl_conversions`、`your_msg`

Ubuntu 下安装（`pcl_ros` 等若源内不可用则需源码安装。注意：`serial_driver` 的 apt 包会带上 `io_context` 与 `libasio-dev`，但 `asio_cmake_module` 属于构建期模块、不在运行时依赖里，必须显式安装，否则下游 `find_package` 时会报找不到 `asio_cmake_moduleConfig.cmake`）：

```bash
sudo apt install \
  ros-$ROS_DISTRO-serial-driver \
  ros-$ROS_DISTRO-asio-cmake-module \
  ros-$ROS_DISTRO-pcl-ros \
  ros-$ROS_DISTRO-pcl-conversions \
  ros-$ROS_DISTRO-nav2-msgs \
  ros-$ROS_DISTRO-nav2-util \
  ros-$ROS_DISTRO-tf2-ros \
  ros-$ROS_DISTRO-tf2-geometry-msgs
```

## 编译与运行

```bash
# 在工作空间根目录（本仓库根目录）执行
colcon build
source install/setup.bash

# 运行节点
ros2 run your_project_name your_node_name

# 验证话题
ros2 topic list
ros2 topic echo /my_topic
```

也可以只编译其中一个包：

```bash
colcon build --packages-select your_msg
colcon build --packages-select your_project_name
```

> `your_project_name` 依赖 `your_msg`，首次编译建议按 `your_msg` -> `your_project_name` 的顺序，或直接在工作空间根目录 `colcon build` 让 colcon 自动处理依赖顺序。

## 快速重命名（模板用法）

`scripts/rename_project.sh` 可将 `your_project_name` 一键重命名为自己的包名，包括目录、`include/` 子目录，以及 `CMakeLists.txt`、`package.xml`、`src/`、`include/` 中出现的 project_name 与 node_name：

```bash
./scripts/rename_project.sh my_new_package              # 节点名默认为 my_new_package_node
./scripts/rename_project.sh my_new_package my_node_name # 同时指定节点名
```

重命名完成后重新 `colcon build` 即可。

> 脚本不处理 `your_cpp_name.cpp`、`your_hpp_name.hpp`、类名 `Your_Hpp_Name` 等占位文件名/类名，如有需要请手动重命名，并同步修改 `#include` 路径与 `CMakeLists.txt` 中的源文件名。

## 串口示例（serial_driver）

串口使用 ROS2 官方维护的 [transport_drivers](https://github.com/ros-drivers/transport_drivers)（Humble 源内没有 ROS1 时代的 `ros-humble-serial`；wjwwood/serial 是纯 catkin 工程，不支持 ROS2）：

```bash
sudo apt install ros-humble-serial-driver ros-humble-asio-cmake-module
```

`your_project_name` 节点启动时调用 `setupSerial()`：打开 `/dev/ttyUSB0`（115200，8N1），挂 `async_receive` 回调打印收到的字节数。

- 设备名/波特率在 `src/your_cpp_name.cpp` 的 `setupSerial()` 中修改
- 打开失败（如无该设备）只打印警告并跳过串口功能，节点其余部分正常运行
- 回调运行在 `io_context` 的 asio 工作线程，与 `run()` 中 `spin_some` 的线程不同，回调内访问共享数据需自行加锁
- `asio_cmake_module` 是构建期 CMake 模块（提供 `FindASIO`），不在 `serial_driver` 的运行时依赖中，需单独安装
- 不需要串口时：删除 CMakeLists.txt 与 package.xml 中 `serial_driver`/`io_context`/`asio`/`asio_cmake_module` 相关条目，并去掉 `setupSerial()` 调用即可

> 模板代码按 humble 分支的 1.2.0 API 编写，与 apt 安装的版本一致。main 分支的 API（`IoContext::start/stop`、新版 `SerialDriver`）尚未发布到任何发行版。

## 环境要求

- ROS 2 foxy / humble（Ubuntu 20.04 / 22.04）
- colcon：`sudo apt install python3-colcon-common-extensions`
