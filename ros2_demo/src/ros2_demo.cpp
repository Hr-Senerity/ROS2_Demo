#include "ros2_demo/ros2_demo.hpp"

Ros2Demo::Ros2Demo()
    : Node("ros2_demo_node")
{
  publisher_ = create_publisher<std_msgs::msg::String>("demo_topic", 10);
  mymsg_publisher_ = create_publisher<ros2_demo::msg::Mymsg>("my_topic", 10);

  timer_ = create_wall_timer(std::chrono::seconds(1), std::bind(&Ros2Demo::timerCallback, this));
}

void Ros2Demo::timerCallback()
{
  auto string_message = std_msgs::msg::String();
  string_message.data = "Hello, ROS 2!";
  publisher_->publish(string_message);

  auto mymsg_message = std::make_shared<ros2_demo::msg::Mymsg>();
  mymsg_message->id = 1;
  mymsg_message->name = "Example";
  mymsg_message->value = 3.14;

  // 发布消息
  mymsg_publisher_->publish(*mymsg_message);
}

int main(int argc, char **argv)
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Ros2Demo>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
