#ifndef ROS2_DEMO__ROS2_DEMO_HPP_
#define ROS2_DEMO__ROS2_DEMO_HPP_

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"
#include "ros2_demo/msg/mymsg.hpp"

class Ros2Demo : public rclcpp::Node
{
public:
  Ros2Demo();

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::Publisher<ros2_demo::msg::Mymsg>::SharedPtr mymsg_publisher_;
  rclcpp::TimerBase::SharedPtr timer_;

  void timerCallback();
};

#endif  // ROS2_DEMO__ROS2_DEMO_HPP_
