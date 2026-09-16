#include "your_project_name/your_hpp_name.hpp"

Your_Hpp_Name::Your_Hpp_Name()
    : Node("your_node_name")
{
  publisher_ = create_publisher<std_msgs::msg::String>("demo_topic", 10);
  mymsg_publisher_ = create_publisher<your_msg::msg::Yourmsgname>("my_topic", 10);

  timer_ = create_wall_timer(std::chrono::seconds(1), std::bind(&Your_Hpp_Name::timerCallback, this));

  setupSerial();
}

Your_Hpp_Name::~Your_Hpp_Name()
{
  if (serial_port_) {
    // close() 内部使用 error_code 非抛出重载，端口未打开时也安全
    serial_port_->close();
    serial_port_.reset();
  }
  if (io_context_) {
    io_context_.reset();  // IoContext 析构时结束内部工作线程
  }
}

void Your_Hpp_Name::setupSerial()
{
  // 按实际硬件修改设备名与波特率
  constexpr const char * kSerialDevice = "/dev/ttyUSB0";
  constexpr uint32_t kSerialBaudRate = 115200;

  // 1 个工作线程运行 asio io_service，驱动异步收发回调
  io_context_ = std::make_shared<drivers::common::IoContext>(1);

  drivers::serial_driver::SerialPortConfig port_config(
    kSerialBaudRate,
    drivers::serial_driver::FlowControl::NONE,
    drivers::serial_driver::Parity::NONE,
    drivers::serial_driver::StopBits::ONE);

  serial_port_ = std::make_shared<drivers::serial_driver::SerialPort>(
    *io_context_, kSerialDevice, port_config);

  try {
    // open() 失败（设备不存在、权限不足等）会抛异常
    serial_port_->open();
  } catch (const std::exception & e) {
    RCLCPP_WARN(get_logger(), "串口打开失败(%s): %s", kSerialDevice, e.what());
    serial_port_.reset();
    io_context_.reset();
    return;
  }

  // 挂异步接收回调；serial_driver 收到数据后会自动继续监听，勿在回调内重复挂载
  serial_port_->async_receive(
    std::bind(&Your_Hpp_Name::serialReceiveCallback, this,
    std::placeholders::_1, std::placeholders::_2));

  RCLCPP_INFO(
    get_logger(), "串口已打开: %s @ %u",
    kSerialDevice, static_cast<unsigned>(kSerialBaudRate));
}

void Your_Hpp_Name::serialReceiveCallback(std::vector<uint8_t> & data, const size_t & size)
{
  // 回调运行在 io_context 的工作线程（与 run() 中 spin_some 的线程不同），
  // 访问共享数据需自行加锁。示例仅打印字节数，可在此解析协议或转发成话题。
  RCLCPP_INFO(get_logger(), "串口收到 %zu 字节", size);
  (void)data;
}

void Your_Hpp_Name::timerCallback()
{
  auto string_message = std_msgs::msg::String();
  string_message.data = "Hello, ROS 2!";
  publisher_->publish(string_message);

  auto mymsg_message = std::make_shared<your_msg::msg::Yourmsgname>();
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
