import 'package:bizos/features/task/data/models/task_model.dart';

abstract class TaskRemoteDatasource {
  Future<List<TaskModel>> getTasks(
    String businessId,
    String userId,
    bool isOwner,
  );
  Future<List<TaskModel>> getAllTasks({
    required String userId,
    required bool isOwner,
  });
  Future<TaskModel> getTaskById(String id);
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<Map<String, String>> getUserNames(List<String> userIds);
  Future<Map<String, String>> getBusinessNames(List<String> businessIds);
}
