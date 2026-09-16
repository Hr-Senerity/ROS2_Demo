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
│       ├── your_cpp_name.cpp          # 节点实现（构造/析构/定时器/串口/run 循环）
│       └── main.cpp                   # 程序入口（main 与节点实现分离）
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

基于 `rclcpp` 的节点示例，`main()` 与节点实现分离：`src/main.cpp` 只负责 `rclcpp::init/shutdown` 与运行方式选择，节点逻辑全部在 `src/your_cpp_name.cpp` 和 `include/your_project_name/your_hpp_name.hpp` 中。

发布话题：

| 话题 | 类型 | 频率 |
|---|---|---|
| `demo_topic` | `std_msgs/msg/String` | 1 Hz |
| `my_topic` | `your_msg/msg/Yourmsgname` | 1 Hz |

其他内容：

- 串口示例：基于官方 `serial_driver` 打开串口并挂异步接收回调（设备不存在时仅告警，不影响其余功能）
- 两种运行方式（在 `src/main.cpp` 中切换）：`rclcpp::spin(node)`（回调驱动）或 `node->run()`（`rclcpp::Rate` 定频循环 + `spin_some`，默认启用）

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

`scripts/rename_project.sh` 一键重命名 `your_project_name` 模板包：

```bash
./scripts/rename_project.sh my_new_package              # 节点名默认为 my_new_package_node
./scripts/rename_project.sh my_new_package my_node_name # 同时指定节点名
```

脚本会完成：

1. 目录重命名：`your_project_name/` → `my_new_package/`，`include/your_project_name/` → `include/my_new_package/`
2. 文件重命名：`your_hpp_name.hpp`、`your_cpp_name.cpp` → `my_new_package.hpp`、`my_new_package.cpp`
3. 内容替换（`CMakeLists.txt`、`package.xml`、`src/`、`include/`）：
   - 包名：`your_project_name` → `my_new_package`
   - 节点名：`your_node_name` → `my_new_package_node`
   - `#include` 路径与 CMake 源文件路径中的头/源文件名
   - include 守卫宏：`YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_` → `MY_NEW_PACKAGE__MY_NEW_PACKAGE_HPP_`
   - 类名：`Your_Hpp_Name` → `MyNewPackage`（新包名的 PascalCase）

重命名完成后重新 `colcon build` 即可；git 仓库内脚本使用 `git mv` 保留文件历史。

> 注意：脚本只能对未重命名的原始模板执行。`your_msg` 包名不受影响，如需一并修改请手动处理。

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

## 常见修改点

| 需求 | 修改位置 |
|---|---|
| 修改话题名/队列深度 | `src/your_cpp_name.cpp` 中的 `create_publisher(...)` |
| 修改节点名 | `src/your_cpp_name.cpp` 构造函数中的 `Node("...")` |
| 修改可执行名 | `CMakeLists.txt` 的 `add_executable` 与 `install(TARGETS ...)` |
| 新增源文件 | 加入 `CMakeLists.txt` 的 `add_executable` 源文件列表 |
| 切换运行方式 | `src/main.cpp` 中启用 `rclcpp::spin(node)` 或 `node->run()` |
| 修改串口设备/波特率 | `src/your_cpp_name.cpp` 的 `setupSerial()` |
| 新增消息 | `your_msg/msg/` 下新建 `.msg`，并加入 `your_msg/CMakeLists.txt` 的 `rosidl_generate_interfaces` |
| 新增依赖 | `CMakeLists.txt` 的 `find_package` + `ament_target_dependencies` 与 `package.xml` 成对添加 |

## 环境要求

- ROS 2 foxy / humble（Ubuntu 20.04 / 22.04）
- colcon：`sudo apt install python3-colcon-common-extensions`
