#ifndef YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_
#define YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"
#include "your_project_name/msg/yourmsgname.hpp"


class Your_Hpp_Name : public rclcpp::Node
{
public:
  Your_Hpp_Name();

  void run();  // 新增函数原型

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::Publisher<your_project_name::msg::Yourmsgname>::SharedPtr mymsg_publisher_;
  rclcpp::TimerBase::SharedPtr timer_;

  void timerCallback();
};

#endif  // YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_
