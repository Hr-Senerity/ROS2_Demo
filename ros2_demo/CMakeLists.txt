cmake_minimum_required(VERSION 3.5)
project(ros2_demo)

# Default to C99
if(NOT CMAKE_C_STANDARD)
  set(CMAKE_C_STANDARD 99)
endif()

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclpy REQUIRED)
find_package(serial REQUIRED)
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(nav2_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)
find_package(pcl_ros REQUIRED)
find_package(nav2_util REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(ros2_demo REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Mymsg.msg"
  DEPENDENCIES geometry_msgs
)

# 包含头文件目录
include_directories(include)

# 添加可执行文件
add_executable(ros2_demo_node src/ros2_demo.cpp)

# 链接库
ament_target_dependencies(ros2_demo_node
  rclcpp
  rclpy
  serial
  std_msgs
  sensor_msgs
  geometry_msgs
  tf2_ros
  nav2_msgs
  nav_msgs
  tf2
  tf2_geometry_msgs
  pcl_ros
  nav2_util
  pcl_conversions
  ros2_demo
  # 如果还有其他依赖项，请在这里添加
)

# 安装目标
install(TARGETS
  ros2_demo_node
  DESTINATION lib/${PROJECT_NAME})

install(DIRECTORY include/
  DESTINATION include/
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # uncomment the line when a copyright and license is not present in all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # uncomment the line when this package is not in a git repo
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()




ament_package()