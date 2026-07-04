import 'package:bizos/features/task/data/datasource/task_remote_datasource.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDatasource taskRemoteDatasource;
  final DashboardRemoteDatasource dashboardRemoteDatasource;

  TaskRepositoryImpl({
    required this.taskRemoteDatasource,
    required this.dashboardRemoteDatasource,
  });

  @override
  Future<List<TaskModel>> getTasks(
    String businessId,
    String userId,
    bool isOwner,
  ) async {
    try {
      return await taskRemoteDatasource.getTasks(businessId, userId, isOwner);
    } catch (e) {
      print("Error loading tasks: $e");
      rethrow;
    }
  }

  @override
  Future<List<TaskModel>> getAllTasks({
    required String userId,
    required bool isOwner,
  }) async {
    try {
      return await taskRemoteDatasource.getAllTasks(userId: userId, isOwner: isOwner);
    } catch (e) {
      print("Error loading all tasks: $e");
      rethrow;
    }
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    try {
      return await taskRemoteDatasource.getTaskById(id);
    } catch (e) {
      print("Error loading task by id: $e");
      rethrow;
    }
  }

  @override
  Future<void> createTask(TaskModel task) async {
    try {
      await taskRemoteDatasource.createTask(task);
      // Automatically log activity
      await dashboardRemoteDatasource.logActivity(
        businessId: task.businessId,
        title: "Add Task",
        description: "Task '${task.title}' was added",
        amount: 0.0,
      );
    } catch (e) {
      print("Error creating task: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await taskRemoteDatasource.updateTask(task);
    } catch (e) {
      print("Error updating task: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      // Find task first to log its details
      final task = await taskRemoteDatasource.getTaskById(id);

      await taskRemoteDatasource.deleteTask(id);

      // Log activity
      await dashboardRemoteDatasource.logActivity(
        businessId: task.businessId,
        title: "Delete Task",
        description: "Task '${task.title}' was deleted",
        amount: 0.0,
      );
    } catch (e) {
      print("Error deleting task: $e");
      // Fallback: delete directly if finding fails
      try {
        await taskRemoteDatasource.deleteTask(id);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    try {
      return await taskRemoteDatasource.getUserNames(userIds);
    } catch (e) {
      print("Error fetching user names in repository: $e");
      return {};
    }
  }

  @override
  Future<Map<String, String>> getBusinessNames(List<String> businessIds) async {
    try {
      return await taskRemoteDatasource.getBusinessNames(businessIds);
    } catch (e) {
      print("Error fetching business names in repository: $e");
      return {};
    }
  }
}
