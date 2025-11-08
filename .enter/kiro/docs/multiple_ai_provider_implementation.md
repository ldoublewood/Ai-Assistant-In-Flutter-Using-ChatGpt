# 多AI提供商功能实现文档

## 概述
本文档记录了多AI提供商功能的实现过程，该功能支持OpenAI、DeepSeek、Google Gemini和自定义OpenAI兼容的AI服务。

## 实现的功能

### 1. 支持的AI提供商
- **OpenAI**: 支持GPT-3.5-turbo、GPT-4等模型
- **DeepSeek**: 支持deepseek-chat、deepseek-coder模型
- **Google Gemini**: 支持gemini-1.5-flash-latest、gemini-1.5-pro-latest等模型
- **自定义**: 支持任何OpenAI兼容的API服务

### 2. 核心功能
- AI提供商配置管理
- API密钥和模型设置
- 自定义API URL配置（用于自定义提供商）
- 连接测试功能
- 提供商切换功能
- 配置持久化存储

## 新增文件

### 1. 模型文件
- `lib/model/ai_provider.dart`: AI提供商类型和配置模型

### 2. 服务文件
- `lib/services/ai_provider_config.dart`: AI提供商配置管理服务
- `lib/services/ai_service.dart`: 统一的AI服务调用接口

### 3. 界面文件
- `lib/screen/ai_provider_settings_screen.dart`: AI提供商设置界面

## 修改的文件

### 1. API调用更新
- `lib/apis/apis.dart`: 更新为使用新的多提供商AI服务

### 2. 界面更新
- `lib/screen/feature/chatbot_feature.dart`: 添加AI提供商设置入口
- `lib/controller/chat_controller.dart`: 添加打开AI提供商设置的方法

### 3. 路由配置
- `lib/main.dart`: 添加AI提供商设置页面的路由

## 技术实现细节

### 1. 配置存储
使用Hive数据库存储AI提供商配置，包括：
- 当前选择的提供商类型
- 各提供商的API密钥、模型和自定义URL配置

### 2. API调用统一化
通过`AIService`类统一处理不同提供商的API调用：
- Gemini使用官方SDK
- OpenAI、DeepSeek、自定义使用HTTP请求调用OpenAI兼容API

### 3. 配置验证
实现了完整的配置验证机制：
- API密钥格式验证
- 自定义URL格式验证
- 连接测试功能

### 4. 用户界面
提供了直观的标签页界面：
- 每个提供商一个标签页
- 实时显示配置状态
- 支持配置保存、测试和切换

## 使用方法

### 1. 配置AI提供商
1. 在聊天界面点击AI提供商设置按钮（大脑图标）
2. 选择要配置的提供商标签页
3. 输入API密钥
4. 选择或输入模型名称
5. 对于自定义提供商，还需输入API地址
6. 点击"保存配置"
7. 点击"测试连接"验证配置
8. 点击"设为当前提供商"激活该配置

### 2. 切换提供商
在AI提供商设置界面中，点击已配置提供商的"设为当前提供商"按钮即可切换。

## 配置示例

### OpenAI配置
- API Key: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 模型: gpt-3.5-turbo
- API地址: https://api.openai.com/v1 (自动)

### DeepSeek配置
- API Key: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 模型: deepseek-chat
- API地址: https://api.deepseek.com/v1 (自动)

### 自定义配置
- API Key: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 模型: gpt-3.5-turbo
- API地址: https://your-custom-api.com/v1

## 注意事项

1. **API密钥安全**: 所有API密钥都存储在本地设备上，不会上传到服务器
2. **网络连接**: 需要确保设备能够访问相应的API服务
3. **配置备份**: 建议用户记录重要的配置信息
4. **兼容性**: 自定义提供商必须兼容OpenAI的API格式

## 后续优化建议

1. **配置导入导出**: 支持配置的导入和导出功能
2. **使用统计**: 添加各提供商的使用统计
3. **成本估算**: 根据模型和使用量估算成本
4. **批量测试**: 支持一键测试所有配置的连接
5. **模型信息**: 显示各模型的详细信息和特性

## 错误处理

系统实现了完善的错误处理机制：
- 网络连接错误提示
- API密钥无效提示
- 模型不支持提示
- 配置格式错误提示

所有错误信息都会以用户友好的方式显示，并记录详细的调试日志。