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
    if (isOwner) {
      // Security check: Verify that this business belongs to this owner
      final bizCheck = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('id', businessId)
          .eq('owner_id', userId)
          .maybeSingle();
      if (bizCheck == null) return [];
    } else {
      // Security check: Verify that this business is assigned to this staff member
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
    if (isOwner) {
      // Fetch all business IDs belonging to this owner
      final businessResponse = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('owner_id', userId);
      
      final businessIds = businessResponse.map((b) => b['id'] as String).toList();
      if (businessIds.isEmpty) return [];

      final response = await supabaseClient
          .from('tasks')
          .select()
          .inFilter('business_id', businessIds);
      return response.map((row) => _fromRow(row)).toList();
    } else {
      // Staff: fetch all tasks assigned to them which belong to their assigned businesses
      final assignedResponse = await supabaseClient
          .from('staff_businesses')
          .select('business_id')
          .eq('staff_id', userId);
      
      final businessIds = assignedResponse.map((b) => b['business_id'] as String).toList();
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
  Future<void> createTask(TaskModel task) async {
    await supabaseClient.from('tasks').insert({
      'id': task.id,
      'business_id': task.businessId,
      'created_at': DateTime.now().toIso8601String(),
      'title': task.title,
      'description': task.description,
      'priority': task.priority,
      'due_date': task.dueDate.toIso8601String(),
      'status': task.isCompleted ? 'Completed' : 'Pending',
      "assigned_to": task.assignedto,
      "created_by": task.createdBy,
    });
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await supabaseClient
        .from('tasks')
        .update({
          'title': task.title,
          'description': task.description,
          'priority': task.priority,
          'due_date': task.dueDate.toIso8601String(),
          'status': task.isCompleted ? 'Completed' : 'Pending',
          "assigned_to": task.assignedto,
          "created_by": task.createdBy,
        })
        .eq('id', task.id);
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    final response = await supabaseClient.from('tasks').select().eq('id', id).single();
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

  TaskModel _fromRow(Map<String, dynamic> row) {
    return TaskModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      title: row['title'] as String,
      description: row['description'] ?? '',
      priority: row['priority'] ?? 'Medium',
      dueDate: DateTime.parse(row['due_date'] as String),
      isCompleted: (row['status'] as String).toLowerCase() == 'completed',
      createdBy: row['created_by']?.toString() ?? '',
      assignedto: row["assigned_to"]?.toString() ?? "",
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : DateTime.now(),
      ownerId: '',
    );
  }
}
