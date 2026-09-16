#ifndef YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_
#define YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_

#include <functional>
#include <string>
#include <vector>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"
#include "your_msg/msg/yourmsgname.hpp"

#include "io_context/io_context.hpp"
#include "serial_driver/serial_port.hpp"

class Your_Hpp_Name : public rclcpp::Node
{
public:
  Your_Hpp_Name();
  ~Your_Hpp_Name();

  void run();

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::Publisher<your_msg::msg::Yourmsgname>::SharedPtr mymsg_publisher_;
  rclcpp::TimerBase::SharedPtr timer_;

  // 串口（serial_driver）：设备缺失时仅告警，不影响节点其余功能
  void setupSerial();
  void serialReceiveCallback(std::vector<uint8_t> & data, const size_t & size);

  // 声明顺序即析构顺序：serial_port_ 依赖 io_context_，必须先于 io_context_ 释放
  std::shared_ptr<drivers::common::IoContext> io_context_;
  std::shared_ptr<drivers::serial_driver::SerialPort> serial_port_;

  void timerCallback();
};

#endif  // YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_
