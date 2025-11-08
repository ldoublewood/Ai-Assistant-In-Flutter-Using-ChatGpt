import 'package:flutter/material.dart';

import '../model/ai_provider.dart';
import '../services/ai_provider_config.dart';
import '../services/ai_service.dart';
import '../helper/my_dialog.dart';
import '../utils/logger.dart';

/// AI提供商设置界面
class AIProviderSettingsScreen extends StatefulWidget {
  const AIProviderSettingsScreen({super.key});

  @override
  State<AIProviderSettingsScreen> createState() => _AIProviderSettingsScreenState();
}

class _AIProviderSettingsScreenState extends State<AIProviderSettingsScreen> {
  AIProviderType _currentProvider = AIProviderType.gemini;
  final Map<AIProviderType, AIProviderConfig> _configs = {};
  final Map<AIProviderType, GlobalKey<FormState>> _formKeys = {};
  final Map<AIProviderType, Map<String, TextEditingController>> _controllers = {};
  
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadConfigs();
  }

  /// 初始化控制器
  void _initializeControllers() {
    for (final type in AIProviderType.values) {
      _formKeys[type] = GlobalKey<FormState>();
      _controllers[type] = {
        'apiKey': TextEditingController(),
        'model': TextEditingController(),
        'customUrl': TextEditingController(),
      };
    }
  }

  /// 加载配置
  void _loadConfigs() {
    setState(() {
      _currentProvider = AIProviderConfigService.getCurrentProviderType();
      
      for (final type in AIProviderType.values) {
        final config = AIProviderConfigService.getProviderConfig(type) ?? 
                      AIProviderConfigService.getDefaultConfig(type);
        _configs[type] = config;
        
        // 更新控制器
        _controllers[type]!['apiKey']!.text = config.apiKey;
        _controllers[type]!['model']!.text = config.model;
        _controllers[type]!['customUrl']!.text = config.customUrl ?? '';
      }
    });
  }

  /// 保存配置
  Future<void> _saveConfig(AIProviderType type) async {
    if (!_formKeys[type]!.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = AIProviderConfig(
        type: type,
        apiKey: _controllers[type]!['apiKey']!.text.trim(),
        model: _controllers[type]!['model']!.text.trim(),
        customUrl: type == AIProviderType.custom 
            ? _controllers[type]!['customUrl']!.text.trim()
            : null,
      );

      await AIProviderConfigService.saveProviderConfig(config);
      _configs[type] = config;
      
      MyDialog.success('${type.name}配置保存成功');
      Logger.config('${type.name}配置已保存');
    } catch (e) {
      Logger.error('保存配置失败: $e', error: e);
      MyDialog.error('保存配置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试连接
  Future<void> _testConnection(AIProviderType type) async {
    if (!_formKeys[type]!.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final config = AIProviderConfig(
        type: type,
        apiKey: _controllers[type]!['apiKey']!.text.trim(),
        model: _controllers[type]!['model']!.text.trim(),
        customUrl: type == AIProviderType.custom 
            ? _controllers[type]!['customUrl']!.text.trim()
            : null,
      );

      final isConnected = await AIService.testConnection(config);
      
      if (isConnected) {
        MyDialog.success('${type.name}连接测试成功');
      } else {
        MyDialog.error('${type.name}连接测试失败，请检查配置');
      }
    } catch (e) {
      Logger.error('连接测试失败: $e', error: e);
      MyDialog.error('连接测试失败: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// 设置为当前提供商
  Future<void> _setAsCurrentProvider(AIProviderType type) async {
    final config = _configs[type];
    if (config == null || !config.isValid) {
      MyDialog.info('请先保存有效的${type.name}配置');
      return;
    }

    try {
      await AIProviderConfigService.setCurrentProviderType(type);
      setState(() {
        _currentProvider = type;
      });
      MyDialog.success('已切换到${type.name}');
    } catch (e) {
      Logger.error('切换提供商失败: $e', error: e);
      MyDialog.error('切换提供商失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI提供商设置'),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: AIProviderType.values.length,
        child: Column(
          children: [
            // 当前提供商状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前AI提供商',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentProvider.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // 标签栏
            TabBar(
              isScrollable: true,
              tabs: AIProviderType.values.map((type) {
                final isConfigured = _configs[type]?.isValid ?? false;
                final isCurrent = type == _currentProvider;
                
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.name),
                      const SizedBox(width: 4),
                      if (isCurrent)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        )
                      else if (isConfigured)
                        Icon(
                          Icons.circle,
                          size: 16,
                          color: Colors.green.withValues(alpha: 0.7),
                        )
                      else
                        Icon(
                          Icons.circle_outlined,
                          size: 16,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            // 标签页内容
            Expanded(
              child: TabBarView(
                children: AIProviderType.values.map((type) {
                  return _buildProviderConfigTab(type);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建提供商配置标签页
  Widget _buildProviderConfigTab(AIProviderType type) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeys[type],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提供商信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (type != AIProviderType.custom) ...[
                      Text('默认API地址: ${type.defaultApiUrl}'),
                      const SizedBox(height: 4),
                    ],
                    Text('默认模型: ${type.defaultModel}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // API Key输入
            TextFormField(
              controller: _controllers[type]!['apiKey'],
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: '请输入API密钥',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入API密钥';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 自定义URL输入（仅自定义提供商）
            if (type == AIProviderType.custom) ...[
              TextFormField(
                controller: _controllers[type]!['customUrl'],
                decoration: const InputDecoration(
                  labelText: 'API地址',
                  hintText: '请输入OpenAI兼容的API地址',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入API地址';
                  }
                  if (!value.startsWith('http')) {
                    return 'API地址必须以http或https开头';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // 模型选择
            DropdownButtonFormField<String>(
              initialValue: _controllers[type]!['model']!.text.isNotEmpty 
                  ? _controllers[type]!['model']!.text 
                  : type.defaultModel,
              decoration: const InputDecoration(
                labelText: '模型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.psychology),
              ),
              items: type.supportedModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _controllers[type]!['model']!.text = value;
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择模型';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _saveConfig(type),
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? '保存中...' : '保存配置'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : () => _testConnection(type),
                    icon: _isTesting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_protected_setup),
                    label: Text(_isTesting ? '测试中...' : '测试连接'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 设为当前提供商按钮
            if (type != _currentProvider)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _setAsCurrentProvider(type),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('设为当前提供商'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controllers in _controllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}