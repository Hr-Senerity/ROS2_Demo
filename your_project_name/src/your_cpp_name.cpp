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

void Your_Hpp_Name::run()
{
  rclcpp::Rate rate(100); // 设置频率为10Hz

  while (rclcpp::ok()) {

    // 这里可以添加一些自定义逻辑

    RCLCPP_WARN(this->get_logger(), "这是一个警告消息！");

    // 处理当前可用的回调
    rclcpp::spin_some(shared_from_this());
    rate.sleep();
  }
}



int main(int argc, char **argv)
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Your_Hpp_Name>();
  // rclcpp::spin(node);
  node->run();  // 使用 run 函数代替 rclcpp::spin(node)

  rclcpp::shutdown();
  return 0;
}
