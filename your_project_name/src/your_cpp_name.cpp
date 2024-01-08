#include "your_project_name/your_hpp_name.hpp"

Your_Hpp_Name::Your_Hpp_Name()
    : Node("your_node_name")
{
  publisher_ = create_publisher<std_msgs::msg::String>("demo_topic", 10);
  mymsg_publisher_ = create_publisher<your_project_name::msg::Yourmsgname>("my_topic", 10);

  timer_ = create_wall_timer(std::chrono::seconds(1), std::bind(&Your_Hpp_Name::timerCallback, this));
}

void Your_Hpp_Name::timerCallback()
{
  auto string_message = std_msgs::msg::String();
  string_message.data = "Hello, ROS 2!";
  publisher_->publish(string_message);

  auto mymsg_message = std::make_shared<your_project_name::msg::Yourmsgname>();
  mymsg_message->id = 1;
  mymsg_message->name = "Example";
  mymsg_message->value = 3.14;

  // 发布消息
  mymsg_publisher_->publish(*mymsg_message);
}

int main(int argc, char **argv)
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Your_Hpp_Name>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
