import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

/// 分组更新服务示例
class GroupUpdateService with DependencyInjectionService, MvcDependableObject {
  // 不同分组的数据
  int _uiCounterValue = 0;
  String _dataValue = "Initial Data";
  String _statusValue = "Ready";

  // UI 相关的数据
  int get uiCounterValue => _uiCounterValue;
  
  // 数据相关的值
  String get dataValue => _dataValue;
  
  // 状态相关的值
  String get statusValue => _statusValue;

  /// 更新 UI 相关数据，只通知 UI 分组
  void updateUIData() {
    _uiCounterValue++;
    notifyDependentsInGroup('ui');
  }

  /// 更新数据，只通知 data 分组
  void updateData() {
    _dataValue = "Updated at ${DateTime.now().millisecondsSinceEpoch}";
    notifyDependentsInGroup('data');
  }

  /// 更新状态，只通知 status 分组
  void updateStatus() {
    final statuses = ['Ready', 'Loading', 'Success', 'Error'];
    _statusValue = statuses[(_statusValue.length + 1) % statuses.length];
    notifyDependentsInGroup('status');
  }

  /// 更新所有数据，通知所有依赖
  void updateAll() {
    _uiCounterValue++;
    _dataValue = "All Updated at ${DateTime.now().millisecondsSinceEpoch}";
    _statusValue = "All Updated";
    notifyAllDependents();
  }
}

/// UI 计数器 Widget - 只关注 UI 分组更新
class UICounterWidget extends MvcStatelessWidget {
  const UICounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.getMvcService<GroupUpdateService>();
    context.dependOnMvcService(service, group: 'ui');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'UI Counter (只响应 UI 分组更新)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '计数: ${service.uiCounterValue}',
              style: const TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: service.updateUIData,
              child: const Text('更新 UI 数据'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 数据显示 Widget - 只关注数据分组更新
class DataDisplayWidget extends MvcStatelessWidget {
  const DataDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.getMvcService<GroupUpdateService>();
    context.dependOnMvcService(service, group: 'data');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Data Display (只响应数据分组更新)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '数据: ${service.dataValue}',
              style: const TextStyle(fontSize: 16),
            ),
            ElevatedButton(
              onPressed: service.updateData,
              child: const Text('更新数据'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态显示 Widget - 只关注状态分组更新
class StatusDisplayWidget extends MvcStatelessWidget {
  const StatusDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.getMvcService<GroupUpdateService>();
    context.dependOnMvcService(service, group: 'status');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Status Display (只响应状态分组更新)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '状态: ${service.statusValue}',
              style: const TextStyle(fontSize: 16),
            ),
            ElevatedButton(
              onPressed: service.updateStatus,
              child: const Text('更新状态'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 全局控制 Widget - 不指定分组，响应所有更新
class GlobalControlWidget extends MvcStatelessWidget {
  const GlobalControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.dependOnMvcServiceOfExactType<GroupUpdateService>();
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Global Control (响应所有更新)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('UI计数: ${service.uiCounterValue}'),
            Text('数据: ${service.dataValue}'),
            Text('状态: ${service.statusValue}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: service.updateAll,
              child: const Text('更新所有数据'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 依赖分组更新示例页面
class DependencyGroupExamplePage extends StatelessWidget {
  const DependencyGroupExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MvcDependencyProvider(
      provider: (collection) {
        collection.addSingleton<GroupUpdateService>((_) => GroupUpdateService());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('依赖分组更新示例'),
          backgroundColor: Colors.blue.shade100,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '这个示例展示了如何使用 MvcDependableObject 的分组功能：\n'
                '• 每个 Widget 只监听特定分组的更新\n'
                '• 点击不同按钮只会更新对应分组的 Widget\n'
                '• "全局控制" Widget 监听所有更新',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 16),
              UICounterWidget(),
              SizedBox(height: 8),
              DataDisplayWidget(),
              SizedBox(height: 8),
              StatusDisplayWidget(),
              SizedBox(height: 8),
              GlobalControlWidget(),
            ],
          ),
        ),
      ),
    );
  }
}