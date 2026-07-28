import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/features/task/data/datasource/task_remote_datasource.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskRemoteDatasourceImpl implements TaskRemoteDatasource {
  final SupabaseClient supabaseClient;

  TaskRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<TaskModel>> getTasks(
    String businessId,
    String userId,
    bool isOwner,
  ) async {
    if (businessId.trim().isEmpty || userId.trim().isEmpty) return [];

    if (isOwner) {
      final bizCheck = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('id', businessId)
          .eq('owner_id', userId)
          .maybeSingle();
      if (bizCheck == null) return [];
    } else {
      final assignedCheck = await supabaseClient
          .from('staff_businesses')
          .select('business_id')
          .eq('staff_id', userId)
          .eq('business_id', businessId)
          .maybeSingle();
      if (assignedCheck == null) return [];
    }

    var query = supabaseClient
        .from('tasks')
        .select()
        .eq('business_id', businessId);
    if (!isOwner) {
      query = query.eq('assigned_to', userId);
    }

    final response = await query;
    return response.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<List<TaskModel>> getAllTasks({
    required String userId,
    required bool isOwner,
  }) async {
    if (userId.trim().isEmpty) return [];

    if (isOwner) {
      final businessResponse = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('owner_id', userId);

      final businessIds = businessResponse
          .map((b) => b['id'] as String)
          .where((id) => id.trim().isNotEmpty)
          .toList();
      if (businessIds.isEmpty) return [];

      final response = await supabaseClient
          .from('tasks')
          .select()
          .inFilter('business_id', businessIds);
      return response.map((row) => _fromRow(row)).toList();
    } else {
      final assignedResponse = await supabaseClient
          .from('staff_businesses')
          .select('business_id')
          .eq('staff_id', userId);

      final businessIds = assignedResponse
          .map((b) => b['business_id'] as String)
          .where((id) => id.trim().isNotEmpty)
          .toList();
      if (businessIds.isEmpty) return [];

      final response = await supabaseClient
          .from('tasks')
          .select()
          .inFilter('business_id', businessIds)
          .eq('assigned_to', userId);
      return response.map((row) => _fromRow(row)).toList();
    }
  }

  @override
  Future<List<TaskModel>> getPersonalTasks(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      final response = await supabaseClient
          .from('tasks')
          .select()
          .or('task_type.eq.personal,business_id.is.null')
          .or('created_by.eq.$userId,assigned_to.eq.$userId');
      return response.map((row) => _fromRow(row)).toList();
    } catch (e) {
      final response = await supabaseClient
          .from('tasks')
          .select()
          .or('created_by.eq.$userId,assigned_to.eq.$userId');
      final list = response.map((row) => _fromRow(row)).toList();
      return list.where((t) => t.isPersonal || t.businessId.trim().isEmpty).toList();
    }
  }

  @override
  Future<void> createTask(TaskModel task) async {
    final isPersonal = task.isPersonal || task.taskType == 'personal' || task.businessId.trim().isEmpty;
    final Map<String, dynamic> insertData = {
      if (task.id.trim().isNotEmpty) 'id': task.id,
      'business_id': isPersonal ? null : (task.businessId.trim().isNotEmpty ? task.businessId : null),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'title': task.title,
      'description': task.description,
      'priority': task.priority,
      'due_date': task.dueDate.toUtc().toIso8601String(),
      'status': task.status,
      'assigned_to': (task.assignedto.trim().isNotEmpty && task.assignedto != 'null') ? task.assignedto : null,
      'created_by': (task.createdBy.trim().isNotEmpty && task.createdBy != 'null') ? task.createdBy : null,
      'is_notified': false,
      'task_type': isPersonal ? 'personal' : 'business',
      'repeat': TaskRepeatMapper.toDb(task.repeat),
    };
    await supabaseClient.from('tasks').insert(insertData);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    if (task.id.trim().isEmpty) return;
    final isPersonal = task.isPersonal || task.taskType == 'personal' || task.businessId.trim().isEmpty;
    final Map<String, dynamic> updateData = {
      'title': task.title,
      'description': task.description,
      'priority': task.priority,
      'due_date': task.dueDate.toUtc().toIso8601String(),
      'status': task.status,
      'assigned_to': (task.assignedto.trim().isNotEmpty && task.assignedto != 'null') ? task.assignedto : null,
      'created_by': (task.createdBy.trim().isNotEmpty && task.createdBy != 'null') ? task.createdBy : null,
      'is_notified': task.isNotified,
      if (task.completedAt != null)
        'completed_at': task.completedAt!.toUtc().toIso8601String(),
      'task_type': isPersonal ? 'personal' : 'business',
      'business_id': isPersonal ? null : (task.businessId.trim().isNotEmpty ? task.businessId : null),
      'repeat': TaskRepeatMapper.toDb(task.repeat),
    };

    await supabaseClient
        .from('tasks')
        .update(updateData)
        .eq('id', task.id);
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    final response = await supabaseClient
        .from('tasks')
        .select()
        .eq('id', id)
        .single();
    return _fromRow(response);
  }

  @override
  Future<void> deleteTask(String id) async {
    await supabaseClient.from('tasks').delete().eq('id', id);
  }

  @override
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final cleanIds = userIds
        .where((id) => id.trim().isNotEmpty && id != 'null')
        .toList();
    if (cleanIds.isEmpty) return {};

    try {
      final response = await supabaseClient
          .from('users')
          .select('id, name')
          .inFilter('id', cleanIds);

      final Map<String, String> namesMap = {};
      for (var row in response) {
        final id = row['id']?.toString() ?? '';
        final name = row['name']?.toString() ?? '';
        if (id.isNotEmpty) {
          namesMap[id] = name;
        }
      }
      return namesMap;
    } catch (e) {
      print("Error fetching user names: $e");
      return {};
    }
  }

  @override
  Future<Map<String, String>> getBusinessNames(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    final cleanIds = businessIds
        .where((id) => id.trim().isNotEmpty && id != 'null')
        .toList();
    if (cleanIds.isEmpty) return {};

    try {
      final response = await supabaseClient
          .from('businesses')
          .select('id, business_name')
          .inFilter('id', cleanIds);

      final Map<String, String> businessMap = {};
      for (var row in response) {
        final id = row['id']?.toString() ?? '';
        final name = row['business_name']?.toString() ?? '';
        if (id.isNotEmpty) {
          businessMap[id] = name;
        }
      }
      return businessMap;
    } catch (e) {
      print("Error fetching business names: $e");
      return {};
    }
  }

  @override
  Future<bool> checkOccurrenceExists({
    required String title,
    required String repeat,
    required String userId,
    required DateTime dueDate,
  }) async {
    if (userId.trim().isEmpty) return false;
    try {
      final dbRepeat = TaskRepeatMapper.toDb(repeat);
      final startWindow = dueDate.subtract(const Duration(minutes: 1)).toUtc().toIso8601String();
      final endWindow = dueDate.add(const Duration(minutes: 1)).toUtc().toIso8601String();

      final response = await supabaseClient
          .from('tasks')
          .select('id')
          .eq('title', title)
          .eq('repeat', dbRepeat)
          .or('created_by.eq.$userId,assigned_to.eq.$userId')
          .gte('due_date', startWindow)
          .lte('due_date', endWindow)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print("Error checking occurrence exists: $e");
      return false;
    }
  }

  // Row mapper logic with Local Time conversion
  TaskModel _fromRow(Map<String, dynamic> row) {
    final statusStr = row['status'] as String? ?? '';
    final isComp = statusStr.toLowerCase() == 'completed' ||
        statusStr.toLowerCase() == 'completed late';
    return TaskModel(
      id: row['id'] as String? ?? '',
      businessId: row['business_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] ?? '',
      priority: row['priority'] ?? 'Medium',
      dueDate: TaskModel.parseDueDate(row['due_date']),
      isCompleted: isComp,
      status: statusStr.isNotEmpty ? statusStr : null,
      completedAt: row['completed_at'] != null
          ? TaskModel.parseDueDate(row['completed_at'])
          : null,
      isNotified: row['is_notified'] ?? false,
      createdBy: row['created_by']?.toString() ?? '',
      assignedto: row['assigned_to']?.toString() ?? '',
      createdAt: row['created_at'] != null
          ? TaskModel.parseDueDate(row['created_at'])
          : DateTime.now(),
      ownerId: '',
      taskType: row['task_type']?.toString(),
      repeat: TaskRepeatMapper.toDb(row['repeat']?.toString()),
    );
  }
}
