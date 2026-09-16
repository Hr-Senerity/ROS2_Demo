#include <memory>

#include "your_project_name/your_hpp_name.hpp"

int main(int argc, char **argv)
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Your_Hpp_Name>();
  // rclcpp::spin(node);
  node->run();  // 使用 run 函数代替 rclcpp::spin(node)

  rclcpp::shutdown();
  return 0;
}
